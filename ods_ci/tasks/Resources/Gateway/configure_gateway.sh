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

# Apply the Gateway resource - FIXES APPLIED HERE
oc apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: openshift-ai-inference
  namespace: ${INGRESS_NS}
  labels:
    serving.kserve.io/gateway: kserve-ingress-gateway
spec:
  gatewayClassName: ${GW_CLASS_NAME}
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: All
EOF
# Wait for the Gateway to be accepted
oc wait gateway -n "${INGRESS_NS}" openshift-ai-inference \
--for=condition=Accepted --timeout=5m || \
echo "Gateway may not expose 'Accepted' condition; check with: oc get gateway -n ${INGRESS_NS} openshift-ai-inference"