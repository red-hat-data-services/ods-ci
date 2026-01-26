#!/bin/bash

oc create namespace kuadrant-system --dry-run=client -o yaml | oc apply -f -

oc apply -f - <<EOF
apiVersion: kuadrant.io/v1beta1
kind: Kuadrant
metadata:
  name: kuadrant
  namespace: kuadrant-system
EOF

echo ">> Waiting for Kuadrant resource to be ready"

# Wait for the Kuadrant resource to be ready, if it is not ready, restart Kuadrant operator and try again
if oc wait --for=condition=ready kuadrant kuadrant  -n kuadrant-system --timeout=60s 2>/dev/null; then
    echo ">> Kuadrant resource ready"
else
    echo ">> Kuadrant resource NOT ready, most likely due to race condition when Authorino Operator is not available, restarting Kuadrant Operator" >&2
    oc delete pod -l app=kuadrant -n kuadrant-system
    echo ">> Waiting once more for Kuadrant resource to become ready after Kuadrant operator restart"
    if oc wait --for=condition=ready kuadrant kuadrant  -n kuadrant-system --timeout=60s 2>/dev/null; then
        echo ">> Kuadrant resource ready"
    else
        echo ">> ERROR: Kuadrant resource still NOT ready, even after Kuadrant operator restart" >&2
        exit 1
    fi
fi
