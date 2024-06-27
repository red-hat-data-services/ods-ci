#!/bin/bash
set -e

# Optional params
INSTANCE_TYPE=${1:-"g4dn.xlarge"}
PROVIDER=${2:-"AWS"}
KUSTOMIZE_PATH="$PWD/ods_ci/tasks/Resources/Provisioning/Hive/GPU"
MACHINESET_PATH="$KUSTOMIZE_PATH/base/source-machineset.yaml"

# Check if existing machineset GPU already exists
EXISTING_GPU_MACHINESET="$(oc get machineset -n openshift-machine-api -o jsonpath="{.items[?(@.metadata.annotations['machine\.openshift\.io/GPU']>'0')].metadata.name}")"
if [[ -n "$EXISTING_GPU_MACHINESET" ]] ; then
  echo "Machine-set for GPU already exists"
  oc get machinesets -A --show-labels
  exit 0
fi

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machineset -n openshift-machine-api -o name | head -n1)
oc get -o yaml -n openshift-machine-api $SOURCE_MACHINESET  > $MACHINESET_PATH

# rename machine set in the template file
OLD_MACHINESET_NAME=$(yq '.metadata.name' $MACHINESET_PATH )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/gpu}
sed -i'' -e "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" $MACHINESET_PATH

# set the desired node flavor in the kustomize overlay
sed -i'' -e "s/INSTANCE_TYPE/$INSTANCE_TYPE/g" $KUSTOMIZE_PATH/overlays/$PROVIDER/gpu.yaml

# create the new MachineSet using kustomize
oc apply --kustomize $KUSTOMIZE_PATH/overlays/$PROVIDER

# Add GPU label to the new machine-set
oc patch machinesets -n openshift-machine-api "$NEW_MACHINESET_NAME" -p '{"metadata":{"labels":{"gpu-machineset":"true"}}}' --type=merge
