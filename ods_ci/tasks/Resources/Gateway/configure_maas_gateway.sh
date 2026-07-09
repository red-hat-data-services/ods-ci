#!/bin/bash

# Apply the GatewayClass resource
cat <<EOF | oc apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: openshift-default
spec:
  controllerName: "openshift.io/gateway-controller/v1"
EOF

INGRESS_NS=openshift-ingress
GW_CLASS_NAME=openshift-default

# Create the namespace if it doesn't exist using a safe method
oc create namespace "${INGRESS_NS}" --dry-run=client -o yaml | oc apply -f -

# Get the cluster domain
CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')

# Get the default wildcard certificate from OpenShift's ingress controller
# This certificate covers *.apps.<cluster-domain>
CERT_NAME=$(oc get ingresscontroller default -n openshift-ingress-operator -o jsonpath='{.spec.defaultCertificate.name}' 2>/dev/null)

# If no custom certificate is configured, use the router's default certificate
if [ -z "${CERT_NAME}" ]; then
    echo "No custom certificate found, using OpenShift default router certificate"
    CERT_NAME="router-certs-default"
fi

echo "Using certificate: ${CERT_NAME}"

# Apply the MaaS Gateway resource
oc apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: maas-default-gateway
  namespace: ${INGRESS_NS}
  annotations:
    opendatahub.io/managed: "false"
    security.opendatahub.io/authorino-tls-bootstrap: "true"
  labels:
    app.kubernetes.io/name: maas
    app.kubernetes.io/instance: maas-default-gateway
    app.kubernetes.io/component: gateway
    opendatahub.io/managed: "false"
spec:
  gatewayClassName: ${GW_CLASS_NAME}
  listeners:
    - name: http
      hostname: "maas.${CLUSTER_DOMAIN}"
      port: 80
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      hostname: "maas.${CLUSTER_DOMAIN}"
      port: 443
      protocol: HTTPS
      allowedRoutes:
        namespaces:
          from: All
      tls:
        certificateRefs:
          - group: ''
            kind: Secret
            name: ${CERT_NAME}
        mode: Terminate
EOF

# Wait for the Gateway to be accepted
oc wait gateway -n "${INGRESS_NS}" maas-default-gateway \
--for=condition=Accepted --timeout=5m || \
echo "Gateway may not expose 'Accepted' condition; check with: oc get gateway -n ${INGRESS_NS} maas-default-gateway"

# Configure Authorino TLS for maas-api communication
AUTHORINO_NS="${AUTHORINO_NAMESPACE:-kuadrant-system}"
echo "Configuring Authorino TLS in namespace: ${AUTHORINO_NS}..."

if ! oc get svc authorino-authorino-authorization -n "${AUTHORINO_NS}" &>/dev/null; then
  echo "ERROR: Authorino service not found in ${AUTHORINO_NS}. Is Authorino installed?" >&2
  exit 1
fi

echo "Annotating Authorino service for TLS certificate..."
if ! oc annotate service authorino-authorino-authorization \
  -n "${AUTHORINO_NS}" \
  service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert \
  --overwrite; then
  echo "ERROR: Failed to annotate Authorino service" >&2
  exit 1
fi

echo "Patching Authorino CR for TLS listener..."
if ! oc patch authorino authorino -n "${AUTHORINO_NS}" --type=merge --patch '{
  "spec": {
    "listener": {
      "tls": {
        "enabled": true,
        "certSecretRef": {
          "name": "authorino-server-cert"
        }
      }
    }
  }
}'; then
  echo "ERROR: Failed to patch Authorino CR for TLS" >&2
  exit 1
fi

echo "Adding CA bundle environment variables to Authorino deployment..."
if ! oc -n "${AUTHORINO_NS}" set env deployment/authorino \
  SSL_CERT_FILE=/etc/ssl/certs/openshift-service-ca/service-ca-bundle.crt \
  REQUESTS_CA_BUNDLE=/etc/ssl/certs/openshift-service-ca/service-ca-bundle.crt; then
  echo "ERROR: Failed to set environment variables on Authorino deployment" >&2
  exit 1
fi

echo "Authorino TLS configuration complete"

# On non-AWS platforms (GCP, OpenStack, etc.) the Gateway service only receives an
# internal IP.  Create an OpenShift Route so maas.<cluster-domain> is reachable
# externally through the cluster's default router.  The route is safe to apply on
# all platforms — on AWS it simply provides an additional ingress path.
echo "Waiting for service to appear for gateway maas-default-gateway in ${INGRESS_NS}..."
SVC_NAME=""
for i in $(seq 1 24); do
  SVC_NAME=$(oc get svc -n "${INGRESS_NS}" \
    -l gateway.networking.k8s.io/gateway-name=maas-default-gateway \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -n "${SVC_NAME}" ]; then
    break
  fi
  sleep 5
done

if [ -z "${SVC_NAME}" ]; then
  echo "ERROR: No service found for gateway maas-default-gateway in ${INGRESS_NS} after 2 minutes" >&2
  exit 1
fi
echo "Found service: ${SVC_NAME}"

if ! oc apply -f - <<EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: maas-gateway-route
  namespace: ${INGRESS_NS}
spec:
  host: maas.${CLUSTER_DOMAIN}
  port:
    targetPort: https
  to:
    kind: Service
    name: ${SVC_NAME}
    weight: 100
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
EOF
then
  echo "ERROR: Failed to create maas-gateway-route in ${INGRESS_NS}" >&2
  exit 1
fi

echo "MaaS Gateway configured successfully with domain: maas.${CLUSTER_DOMAIN}"
