#!/bin/bash
set -euo pipefail

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
POSTGRES_IMAGE="registry.redhat.io/rhel9/postgresql-15:latest"

# Ensure namespace exists
oc create namespace "${APPS_NS}" --dry-run=client -o yaml | oc apply -f -

# Skip if all resources already exist and deployment is ready
if oc get secret maas-db-config -n "${APPS_NS}" &>/dev/null \
   && oc get secret postgres-creds -n "${APPS_NS}" &>/dev/null \
   && oc get service postgres -n "${APPS_NS}" &>/dev/null \
   && oc get deployment postgres -n "${APPS_NS}" &>/dev/null; then
    oc wait deployment/postgres -n "${APPS_NS}" --for=condition=Available --timeout=5m
    echo "MaaS PostgreSQL prerequisites already exist in ${APPS_NS}, skipping."
    exit 0
fi

# Reuse existing credentials if postgres-creds secret is present, otherwise generate new ones
if oc get secret postgres-creds -n "${APPS_NS}" &>/dev/null; then
    PG_USER="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_USER}' | base64 -d)"
    PG_PASS="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d)"
    PG_DB="$(oc get secret postgres-creds -n "${APPS_NS}" -o jsonpath='{.data.POSTGRES_DB}' | base64 -d)"
    echo "Reusing existing postgres-creds in ${APPS_NS}"
else
    PG_USER="maas-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    PG_PASS="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
    PG_DB="maas-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
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
DB_URL="postgresql://${PG_USER}:${PG_PASS}@postgres:5432/${PG_DB}?sslmode=disable"
oc apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: maas-db-config
  namespace: ${APPS_NS}
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

echo "MaaS PostgreSQL prerequisites provisioned in ${APPS_NS}"
