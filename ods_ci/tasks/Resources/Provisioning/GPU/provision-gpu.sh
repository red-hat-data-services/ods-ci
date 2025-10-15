#!/bin/bash
set -e

# GPU Node Provisioning Script for Self-Managed Clusters
# 
# This script creates GPU nodes in self-managed OpenShift clusters by creating
# a new MachineSet with the specified configuration.
#
# Parameters:
#   $1 INSTANCE_TYPE   - Instance type for the GPU nodes (default: g4dn.xlarge)
#   $2 PROVIDER        - Cloud provider (AWS/GCP/AZURE/IBM) (default: AWS)
#   $3 GPU_COUNT       - Number of GPUs per node (for GCP only) (default: 1)
#   $4 GPU_NODE_COUNT  - Number of GPU nodes to create (default: 1)
#
# Examples:
#   ./provision-gpu.sh                           # Create 1 g4dn.xlarge node on AWS
#   ./provision-gpu.sh g4dn.2xlarge AWS 1 3     # Create 3 g4dn.2xlarge nodes on AWS
#   ./provision-gpu.sh n1-standard-4 GCP 2 2    # Create 2 nodes with 2 GPUs each on GCP

# Optional params
INSTANCE_TYPE=${1:-"g4dn.xlarge"}
PROVIDER=${2:-"AWS"}
GPU_COUNT=${3:-"1"}
GPU_NODE_COUNT=${4:-"1"}
KUSTOMIZE_PATH="$PWD/tasks/Resources/Provisioning/Hive/GPU"
MACHINESET_PATH="$KUSTOMIZE_PATH/base/source-machineset.yaml"
PROVIDER_OVERLAY_DIR=$KUSTOMIZE_PATH/overlays/$PROVIDER
MACHINE_WAIT_TIMEOUT=10m
# Check if existing machineset GPU already exists
EXISTING_GPU_MACHINESET="$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[?(@.metadata.annotations['machine\.openshift\.io/GPU']>'0')].metadata.name}")"
if [[ -n "$EXISTING_GPU_MACHINESET" ]] ; then
  echo "Machine-set for GPU already exists"
  oc get machinesets -A --show-labels
  exit 0
fi

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o name | head -n1)
oc get -o yaml -n openshift-machine-api $SOURCE_MACHINESET  > $MACHINESET_PATH

# rename machine set in the template file
OLD_MACHINESET_NAME=$(yq '.metadata.name' $MACHINESET_PATH )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/gpu}
sed -i'' -e "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" $MACHINESET_PATH

if [[ "$PROVIDER" == "GCP" && "$INSTANCE_TYPE" == *"nvidia-"*  ]] ; then
  GPU_TYPE=$INSTANCE_TYPE
  INSTANCE_TYPE="n1-standard-4"
  PROVIDER_OVERLAY_DIR="$PROVIDER_OVERLAY_DIR/attach-gpu-to-n1"
  sed -i'' -e "s/GPU_TYPE/$GPU_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
  sed -i'' -e "s/GPU_COUNT/$GPU_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
fi
# set the desired node flavor and node count in the kustomize overlay
sed -i'' -e "s/INSTANCE_TYPE/$INSTANCE_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
sed -i'' -e "s/GPU_NODE_COUNT/$GPU_NODE_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml

# create the new MachineSet using kustomize
oc apply --kustomize $PROVIDER_OVERLAY_DIR
# Add GPU label to the new machine-set
oc patch machinesets.machine.openshift.io -n openshift-machine-api "$NEW_MACHINESET_NAME" -p '{"metadata":{"labels":{"gpu-machineset":"true"}}}' --type=merge
# wait for the machine to be Ready
echo "Waiting for $GPU_NODE_COUNT GPU Node(s) to be Ready"
oc wait --timeout=$MACHINE_WAIT_TIMEOUT --for jsonpath='{.status.readyReplicas}'=$GPU_NODE_COUNT machinesets.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api
 if [ $? -ne 0 ]; then
  echo "Machine Set $NEW_MACHINESET_NAME does not have its Machines in Running status after $MACHINE_WAIT_TIMEOUT timeout"
  echo "Please check the cluster"
  exit 1
fi