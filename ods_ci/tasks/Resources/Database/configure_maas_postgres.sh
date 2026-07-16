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
# in a separate infra namespace. Postgres stays in APPS_NS; maas-db-config is always
# refreshed from postgres-creds and applied to INFRA_NS (and APPS_NS when they differ).
derive_infra_namespace() {
    case "$1" in
        redhat-ods-applications) echo "redhat-ai-gateway-infra" ;;
        opendatahub)             echo "odh-ai-gateway-infra" ;;
        *)                       echo "$1" ;;
    esac
}

detect_infra_namespace() {
    local apps_ns="$1"

    # MaaS provisioning may run before the RHOAI operator has fully deployed
    # the maas-controller (CRD registration, reconciliation, and pod scheduling
    # can take 10+ minutes after the CSV is ready). Without waiting, detect
    # would see no controller and fall back to the apps namespace — then when
    # the operator deploys a controller with INFRA_NAMESPACE=AUTO it looks in
    # the infra namespace where the secret doesn't exist, and maas-api never
    # starts. Wait up to 15 minutes to cover slow clusters.
    echo "Waiting for maas-controller deployment in ${apps_ns}..." >&2
    for i in $(seq 1 90); do
        oc get deployment maas-controller -n "${apps_ns}" &>/dev/null && break
        sleep 10
    done

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

# Always (re)apply maas-db-config from current credentials so namespaces cannot drift.
apply_maas_db_config() {
    local target_ns="$1"
    local pg_host="$2"
    local db_url="postgresql://${PG_USER}:${PG_PASS}@${pg_host}:5432/${PG_DB}?sslmode=disable"

    oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: maas-db-config
  namespace: ${target_ns}
  labels:
    app: maas-api
    purpose: poc
type: Opaque
stringData:
  DB_CONNECTION_URL: "${db_url}"
EOF
}

refresh_maas_db_config_secrets() {
    # FQDN works from both namespaces; prefer it whenever infra is separate.
    local pg_host
    if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
        pg_host="postgres.${APPS_NS}.svc"
    else
        pg_host="postgres"
    fi

    apply_maas_db_config "${INFRA_NS}" "${pg_host}"
    if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
        # Keep apps namespace in sync for consumers/tools that still look there.
        apply_maas_db_config "${APPS_NS}" "${pg_host}"
    fi
}

load_or_generate_postgres_creds() {
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
}

INFRA_NS=$(detect_infra_namespace "${APPS_NS}")

# Ensure namespaces exist
oc create namespace "${APPS_NS}" --dry-run=client -o yaml | oc apply -f -
if [[ "${INFRA_NS}" != "${APPS_NS}" ]]; then
    oc create namespace "${INFRA_NS}" --dry-run=client -o yaml | oc apply -f -
fi

# If postgres is already provisioned, still refresh maas-db-config every run so
# INFRA_NS (and APPS_NS when separate) cannot keep a stale connection URL.
if oc get secret postgres-creds -n "${APPS_NS}" &>/dev/null \
   && oc get service postgres -n "${APPS_NS}" &>/dev/null \
   && oc get deployment postgres -n "${APPS_NS}" &>/dev/null; then
    oc wait deployment/postgres -n "${APPS_NS}" --for=condition=Available --timeout=5m
    load_or_generate_postgres_creds
    refresh_maas_db_config_secrets
    echo "MaaS PostgreSQL already provisioned in ${APPS_NS}; refreshed maas-db-config in ${INFRA_NS}$([[ "${INFRA_NS}" != "${APPS_NS}" ]] && echo " and ${APPS_NS}")."
    exit 0
fi

# Reuse existing credentials if postgres-creds secret is present, otherwise generate new ones
load_or_generate_postgres_creds

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

# 2. maas-db-config secret (always applied; both namespaces when infra is separate)
refresh_maas_db_config_secrets

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
    echo "MaaS PostgreSQL prerequisites provisioned (postgres in ${APPS_NS}, maas-db-config in ${INFRA_NS} and ${APPS_NS})"
else
    echo "MaaS PostgreSQL prerequisites provisioned in ${APPS_NS}"
fi
