#!/bin/bash

while [ "$#" -gt 0 ]; do
    case $1 in
        --namespace)
            shift
            APPS_NS=$1
            shift
            ;;
        *)
            echo "Unknown command line switch: $1"
            exit 1
            ;;
    esac
done

APPS_NS="${APPS_NS:-redhat-ods-applications}"
POSTGRES_IMAGE="registry.redhat.io/rhel9/postgresql-15@sha256:90ec347a35ab8a5d530c8d09f5347b13cc71df04f3b994bfa8b1a409b1171d59"

# Derive MaaS infrastructure namespace (matches MaaS controller logic from PR #1051).
# When INFRA_NAMESPACE=AUTO (default since 3.5), the controller expects maas-db-config
# in a separate infra namespace. Postgres stays in APPS_NS; maas-db-config is copied
# to the infra namespace with a cross-namespace connection URL.
derive_infra_namespace() {
    case "$1" in
        redhat-ods-applications) echo "redhat-ai-gateway-infra" ;;
        opendatahub)             echo "odh-ai-gateway-infra" ;;
        *)                       echo "$1" ;;
    esac
}

detect_infra_namespace() {
    local apps_ns="$1"
    local infra_val
    infra_val=$(oc get deployment maas-controller -n "${apps_ns}" \
        -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="INFRA_NAMESPACE")].value}' \
        2>/dev/null)

    if [[ "${infra_val}" == "AUTO" ]]; then
        derive_infra_namespace "${apps_ns}"
    elif [[ -n "${infra_val}" ]]; then
        echo "${infra_val}"
    else
        echo "${apps_ns}"
    fi
}

INFRA_NS=$(detect_infra_namespace "${APPS_NS}")

# Ensure namespaces exist
oc create namespace "${APPS_NS}" --dry-run=client -o yaml | oc apply -f -
if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
    oc create namespace "${INFRA_NS}" --dry-run=client -o yaml | oc apply -f -
fi

# Skip if all resources already exist and deployment is ready
if oc get secret maas-db-config -n "${INFRA_NS}" &>/dev/null \
   && oc get secret postgres-creds -n "${APPS_NS}" &>/dev/null \
   && oc get service postgres -n "${APPS_NS}" &>/dev/null \
   && oc get deployment postgres -n "${APPS_NS}" &>/dev/null; then
    oc wait deployment/postgres -n "${APPS_NS}" --for=condition=Available --timeout=5m
    echo "MaaS PostgreSQL prerequisites already exist (postgres in ${APPS_NS}, maas-db-config in ${INFRA_NS}), skipping."
    exit 0
fi

# Reuse existing credentials if postgres-creds secret is present, otherwise generate new ones
if oc get secret postgres-creds -n "${APPS_NS}" &>/dev/null; then
    PG_USER="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)"
    PG_PASS="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
    PG_DB="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_DB}' | base64 -d)"
    if [[ -z "${PG_USER}" || -z "${PG_PASS}" || -z "${PG_DB}" ]]; then
        echo "postgres-creds in ${APPS_NS} is missing required keys/values" >&2
        exit 1
    fi
    echo "Reusing existing postgres-creds in ${APPS_NS}"
else
    PG_USER="maas-$(cat /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    PG_PASS="$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
    PG_DB="maas-$(cat /dev/urandom | tr -dc a-z0-9 | head -c 8)"
fi

# 1. postgres-creds secret
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: postgres-creds
  namespace: ${APPS_NS}
  labels:
    app: postgres
    purpose: poc
type: Opaque
stringData:
  POSTGRES_USER: "${PG_USER}"
  POSTGRES_PASSWORD: "${PG_PASS}"
  POSTGRES_DB: "${PG_DB}"
EOF

# 2. maas-db-config secret (DB_CONNECTION_URL key)
# Use cross-namespace DNS when postgres and maas-db-config are in different namespaces
if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
    PG_HOST="postgres.${APPS_NS}.svc"
else
    PG_HOST="postgres"
fi
DB_URL="postgresql://${PG_USER}:${PG_PASS}@${PG_HOST}:5432/${PG_DB}?sslmode=disable"
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: maas-db-config
  namespace: ${INFRA_NS}
  labels:
    app: maas-api
    purpose: poc
type: Opaque
stringData:
  DB_CONNECTION_URL: "${DB_URL}"
EOF

# 3. postgres Service
oc apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: ${APPS_NS}
  labels:
    app: postgres
    purpose: poc
spec:
  selector:
    app: postgres
  ports:
    - name: postgres
      port: 5432
      protocol: TCP
      targetPort: 5432
EOF

# 4. postgres Deployment
oc apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  namespace: ${APPS_NS}
  labels:
    app: postgres
    purpose: poc
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
        purpose: poc
    spec:
      containers:
        - name: postgres
          image: ${POSTGRES_IMAGE}
          env:
            - name: POSTGRESQL_USER
              valueFrom:
                secretKeyRef:
                  name: postgres-creds
                  key: POSTGRES_USER
            - name: POSTGRESQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-creds
                  key: POSTGRES_PASSWORD
            - name: POSTGRESQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: postgres-creds
                  key: POSTGRES_DB
          ports:
            - containerPort: 5432
          volumeMounts:
            - name: data
              mountPath: /var/lib/pgsql/data
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          readinessProbe:
            exec:
              command: ["/usr/libexec/check-container"]
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: data
          emptyDir: {}
EOF

# Wait for postgres to be ready
if ! oc wait deployment/postgres -n "${APPS_NS}" --for=condition=Available --timeout=5m; then
    echo "PostgreSQL deployment is not ready in ${APPS_NS}" >&2
    exit 1
fi

if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
    echo "MaaS PostgreSQL prerequisites provisioned (postgres in ${APPS_NS}, maas-db-config in ${INFRA_NS})"
else
    echo "MaaS PostgreSQL prerequisites provisioned in ${APPS_NS}"
fi
