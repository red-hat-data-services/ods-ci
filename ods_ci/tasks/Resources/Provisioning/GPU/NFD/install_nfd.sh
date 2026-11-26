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

ocpVersion=$(oc version --output json | jq '.openshiftVersion' | tr -d '"')
IFS='.' read -ra ocpVersionSplit <<< "$ocpVersion"
xyVersion="${ocpVersionSplit[0]}.${ocpVersionSplit[1]}"
declare -A images=(
    ["4.14"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery@sha256:2977e67a413882efbfb90b52facf65d38a5cb2cd7a232ca3a69476e5dec33319"
    ["4.15"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:661b6697dee34626a3a98b50cdba787402ab214d2807b8460df92e3c79cdfcc5"
    ["4.16"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:bb95bc317ab78e8af4ef34dd66f9f62c2f8c261dfb5eab40918142812802f8b7"
    ["4.17"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:154cf3f1ddaf895d7ecd04947bd455a930132f72acc6e8bde8c26bc123184ace"
    # 4.18 is a pre-release image. We need to update it later
    ["4.18"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:510cb4351253492455664b6c323f54dc2f6f2f8791c5e92ba6b7e60b8adb357c"
    ["4.19"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:d23fe6bcb36bdbe0e61a30f8ab7cb90e6dea25a399d87c3ba3d94415a61735b8"
    ["4.20"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:fbd8db340dd4e4cda793b1f0453d42988bb8102d1061388827777bb848b067f2"
    ["4.21"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:76a161a255a255eafcef4dc036adb8c0c8aadab2f0c57c3d3e19d5eea0ac5961"
    ["4.22"]="registry.redhat.io\/openshift4\/ose-node-feature-discovery-rhel9@sha256:c16c62f136039eaf535ef4e3f6e3a5cc278fa49538e82f8a37bff89f641c2596"

)
majorVersion="${ocpVersionSplit[0]}"

# Render into a temporary copy so the checked-out template is never mutated.
# This ensures repeated runs and version changes always start from the
# original template, and 5+ correctly omits the image even if a prior
# 4.x run (or committed manifest) already baked in a digest.
NFD_RENDERED=$(mktemp "${NFD_INSTANCE%.yaml}.XXXXXX")
trap 'rm -f "$NFD_RENDERED"' EXIT
cp "$NFD_INSTANCE" "$NFD_RENDERED"

if [[ "$majorVersion" == "4" ]]; then
    if [ "${images[$xyVersion]}" ]; then
        imageUrl="${images[$xyVersion]}"
        echo "Using image SHA for $xyVersion: $imageUrl"
    else
        imageUrl="${images["4.17"]}"
        echo "WARNING: I don't know the sha for $xyVersion. Re-using default 4.17 $imageUrl. It might not work!"
    fi
    # Replace the entire image: line (handles both <imageUrl> placeholder
    # and pre-rendered digests from legacy manifests)
    sed -i'' -e "s/^\([[:space:]]*\)image:.*/\1image: $imageUrl/" "$NFD_RENDERED"
elif [[ "$majorVersion" -ge 5 ]] 2>/dev/null; then
    echo "OCP $xyVersion detected (major version >= 5)."
    echo "Omitting spec.operand.image to let the NFD operator use its managed default."
    # Remove image line entirely (handles both <imageUrl> placeholder and
    # pre-rendered digests). The NFD operator selects its own operand image
    # via the NODE_FEATURE_DISCOVERY_IMAGE env var when spec.operand.image
    # is empty.
    # See: openshift/cluster-nfd-operator getOperandImage() in
    # internal/controllers/nodefeaturediscovery_reconciler.go
    sed -i'' -e '/^[[:space:]]*image:/d' "$NFD_RENDERED"
else
    echo "ERROR: Unsupported OCP major version '$majorVersion' (detected: $ocpVersion)."
    echo "Only OCP 4.x (with pinned image digests) and OCP 5+ (operator-managed image) are supported."
    exit 1
fi

# temporary sleep until latest oc binary is available and --for=create is supported
sleep 10s
oc apply -f "$NFD_RENDERED"

echo "Configuring SR-IOV Operator"
oc apply -f "$NFD_INSTALL_DIR/sriov_network_node_policy.yaml"
