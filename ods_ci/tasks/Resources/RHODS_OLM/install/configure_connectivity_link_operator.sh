#!/bin/bash

oc create namespace kuadrant-system --dry-run=client -o yaml | oc apply -f -

oc apply -f - <<EOF
apiVersion: kuadrant.io/v1beta1
kind: Kuadrant
metadata:
  name: kuadrant
  namespace: kuadrant-system
EOF

