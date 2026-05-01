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

# On non-AWS platforms (GCP, OpenStack, etc.) the Gateway service only receives an
# internal IP.  Create an OpenShift Route so maas.<cluster-domain> is reachable
# externally through the cluster's default router.  The route is safe to apply on
# all platforms — on AWS it simply provides an additional ingress path.
SVC_NAME="maas-default-gateway-openshift-default"

echo "Waiting for service ${SVC_NAME} in ${INGRESS_NS}..."
if ! oc wait service/"${SVC_NAME}" -n "${INGRESS_NS}" \
  --for=jsonpath='{.spec.clusterIP}' --timeout=2m; then
  echo "ERROR: service ${SVC_NAME} not found in ${INGRESS_NS}; cannot create Route"
  exit 1
fi

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
  echo "ERROR: Failed to create maas-gateway-route in ${INGRESS_NS}"
  exit 1
fi

echo "MaaS Gateway configured successfully with domain: maas.${CLUSTER_DOMAIN}"
