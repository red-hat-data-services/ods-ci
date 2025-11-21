#!/bin/bash
set -e

echo "Configuring Gateway API for KServe Ingress"

INGRESS_NS=${INGRESS_NS:-openshift-ingress}
GW_CLASS_NAME=${GW_CLASS_NAME:-openshift-default}

# Check if Gateway API is available
echo "Checking Gateway API availability..."
if ! oc get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
    echo "Gateway API CRDs not found. Gateway API may not be enabled on this cluster."
    echo "Please enable Gateway API feature gate or install Gateway API manually."
    exit 1
fi

# Check existing GatewayClasses
echo "Checking existing GatewayClasses..."
EXISTING_GW_CLASS=$(oc get gatewayclass -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$EXISTING_GW_CLASS" ]; then
    echo "Found existing GatewayClass: $EXISTING_GW_CLASS"
    GW_CLASS_NAME=$EXISTING_GW_CLASS
else
    echo "No existing GatewayClass found, creating: ${GW_CLASS_NAME}"
    # Create GatewayClass
    cat <<EOF | oc apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ${GW_CLASS_NAME}
spec:
  controllerName: "openshift.io/gateway-controller/v1"
EOF
fi

# Create namespace if it doesn't exist
echo "Ensuring namespace ${INGRESS_NS} exists"
oc create namespace ${INGRESS_NS} --dry-run=client -o yaml | oc apply -f -

# Check if Gateway already exists
if oc get gateway -n ${INGRESS_NS} openshift-ai-inference >/dev/null 2>&1; then
    echo "Gateway openshift-ai-inference already exists, updating..."
    oc delete gateway -n ${INGRESS_NS} openshift-ai-inference --ignore-not-found=true
fi

# Create Gateway
echo "Creating Gateway: openshift-ai-inference in namespace ${INGRESS_NS}"
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

# Wait for Gateway to be Accepted with better error handling
echo "Waiting for Gateway to be accepted..."
if oc wait gateway -n ${INGRESS_NS} openshift-ai-inference \
  --for=condition=Accepted --timeout=5m 2>/dev/null; then
    echo "Gateway accepted successfully"
else
    echo "Gateway acceptance timeout. Checking Gateway status..."
    oc get gateway -n ${INGRESS_NS} openshift-ai-inference -o yaml
    
    # Check if Gateway controller is running
    echo "Checking Gateway controller status..."
    if oc get pods -n openshift-ingress-operator -l name=gateway-controller 2>/dev/null | grep -q Running; then
        echo "Gateway controller is running"
    else
        echo "Gateway controller may not be running. Check with:"
        echo "oc get pods -n openshift-ingress-operator -l name=gateway-controller"
    fi
    
    # Check GatewayClass status
    echo "Checking GatewayClass status..."
    oc get gatewayclass ${GW_CLASS_NAME} -o yaml | grep -A 5 -B 5 "status:" || echo "No status found"
    
    echo "Gateway may not expose 'Accepted' condition; check with: oc get gateway -n ${INGRESS_NS} openshift-ai-inference -o yaml"
fi

echo "Gateway configuration completed"

