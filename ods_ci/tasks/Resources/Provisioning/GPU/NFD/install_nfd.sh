#!/bin/bash
set -e

NFD_INSTALL_DIR="$(dirname "$0")"
NFD_INSTANCE=$NFD_INSTALL_DIR/nfd_deploy.yaml

echo "Installing NFD operator"
oc apply -f "$NFD_INSTALL_DIR/nfd_operator.yaml"
oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n openshift-nfd sub nfd

echo "Installing SR-IOV Network Operator"
oc apply -f "$NFD_INSTALL_DIR/sriov_operator.yaml"
oc wait --timeout=8m --for jsonpath='{.status.state}'=AtLatestKnown -n openshift-sriov-network-operator sub sriov-network-operator-subscription

# temporary sleep until latest oc binary is available and --for=create is supported
sleep 10s
oc apply -f "$NFD_INSTANCE"

echo "Configuring SR-IOV Operator"
oc apply -f "$NFD_INSTALL_DIR/sriov_network_node_policy.yaml"
