#!/bin/bash
set -e

function wait_while {
  local seconds timeout interval
  interval=2
  seconds=0
  timeout=$1
  shift
  while eval "$*"; do
    seconds=$(( seconds + interval ))
    sleep $interval
    echo -n '.'
    [[ $seconds -gt $timeout ]] && echo "Time out of ${timeout} exceeded" && return 1
  done
  if [[ "$seconds" != '0' ]]; then
    echo ''
  fi
  return 0
}

NFD_INSTALL_DIR="$(dirname "$0")"
NFD_INSTANCE=$NFD_INSTALL_DIR/nfd_deploy.yaml
echo "Installing NFD operator"
oc apply -f "$NFD_INSTALL_DIR/nfd_operator.yaml"
oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n openshift-nfd sub nfd

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
)
if [ "${images[$xyVersion]}" ]; then
    imageUrl="${images[$xyVersion]}"
    echo "Using image SHA for $xyVersion: $imageUrl"
else
    imageUrl="${images["4.17"]}"
    echo "WARNING: I don't know the sha for $xyVersion. Re-using default 4.17 $imageUrl. It might not work!"
fi
sed -i'' -e "s/<imageUrl>/$imageUrl/g" $NFD_INSTANCE
oc apply -f "$NFD_INSTANCE"
