#!/bin/bash
set -e

NFD_INSTALL_DIR="$(dirname "$0")"
NFD_INSTANCE=$NFD_INSTALL_DIR/nfd_deploy.yaml
echo "Installing NFD operator"
oc apply -f "$NFD_INSTALL_DIR/nfd_operator.yaml"
oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n openshift-nfd sub nfd

# Wait for the NFD operator CSV to be ready before creating the CR
oc wait --timeout=3m --for condition=Installed -n openshift-nfd installplan --all

sleep 10s
oc apply -f "$NFD_INSTANCE"
