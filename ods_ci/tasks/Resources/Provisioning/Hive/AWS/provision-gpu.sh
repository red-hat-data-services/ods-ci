#!/bin/bash
set -e

# Optional params
INSTANCE_TYPE=${1:-"g4dn.xlarge"}

# Check if existing machineset GPU already exists
EXISTING_GPU_MACHINESET="$(oc get machineset -n openshift-machine-api -o jsonpath="{.items[?(@.metadata.annotations['machine\.openshift\.io/GPU']>'0')].metadata.name}")"
if [[ -n "$EXISTING_GPU_MACHINESET" ]] ; then
  echo "Machine-set for GPU already exists"
  oc get machinesets -A --show-labels
  exit 0
fi

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machineset -n openshift-machine-api -o name | head -n1)

# Reformat with jq, for better diff result.
oc get -o json -n openshift-machine-api $SOURCE_MACHINESET  | jq -r > /tmp/source-machineset.json

OLD_MACHINESET_NAME=$(jq '.metadata.name' -r /tmp/source-machineset.json )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/gpu}


# Change instanceType and delete some stuff
jq -r --arg INSTANCE_TYPE "$INSTANCE_TYPE" '.spec.template.spec.providerSpec.value.instanceType=$INSTANCE_TYPE
  | del(.metadata.selfLink)
  | del(.metadata.uid)
  | del(.metadata.creationTimestamp)
  | del(.metadata.resourceVersion)
' /tmp/source-machineset.json > /tmp/gpu-machineset.json

# Change machineset name
sed -i'' -e "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" /tmp/gpu-machineset.json
# Create new machineset
oc apply -f /tmp/gpu-machineset.json
rm /tmp/source-machineset.json
rm /tmp/gpu-machineset.json

# Add GPU label to the new machine-set
oc patch machinesets -n openshift-machine-api "$NEW_MACHINESET_NAME" -p '{"metadata":{"labels":{"gpu-machineset":"true"}}}' --type=merge
