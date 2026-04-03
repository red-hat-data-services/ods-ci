#!/bin/bash

APPS_NS="${APPLICATIONS_NAMESPACE:-redhat-ods-applications}"
POSTGRES_IMAGE="registry.redhat.io/rhel9/postgresql-15:latest"

# Generate random credentials
PG_USER="maas-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
PG_PASS="$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32)"
PG_DB="maas-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"

# Skip if already provisioned
if oc get secret maas-db-config -n "${APPS_NS}" &>/dev/null; then
    echo "maas-db-config already exists in ${APPS_NS}, skipping."
    exit 0
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
oc wait deployment/postgres -n "${APPS_NS}" \
  --for=condition=Available --timeout=5m || \
echo "PostgreSQL deployment may not be ready; check with: oc get deployment postgres -n ${APPS_NS}"

echo "MaaS PostgreSQL prerequisites provisioned in ${APPS_NS}"
