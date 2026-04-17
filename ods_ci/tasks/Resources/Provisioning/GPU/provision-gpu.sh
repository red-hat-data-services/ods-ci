#!/bin/bash
set -e

# GPU Node Provisioning Script for Self-Managed Clusters
# 
# This script creates GPU nodes in self-managed OpenShift clusters by creating
# a new MachineSet with the specified configuration.
#
# Parameters:
#   $1 INSTANCE_TYPE  - Instance type or GPU flavor (default: g4dn.xlarge)
#   $2 PROVIDER       - Cloud provider (AWS/GCP/AZURE/IBM) (default: AWS)
#   $3 GPU_NODE_COUNT - Number of GPU nodes (default: 1)
#   $4 GPU_COUNT      - GPUs per node (for GCP nvidia-* only) (default: 1)
#
# Parameter Logic:
#   For GCP nvidia-* flavors: $3=GPU_NODE_COUNT, $4=GPU_COUNT
#   For all other cases: $3=GPU_NODE_COUNT, GPU_COUNT=1
#
# Examples:
#   ./provision-gpu.sh g4dn.xlarge AWS 2             # 2 g4dn.xlarge nodes on AWS
#   ./provision-gpu.sh n1-standard-4 GCP 3          # 3 n1-standard-4 nodes on GCP
#   ./provision-gpu.sh nvidia-tesla-v100 GCP 2 1    # 2 nodes with 1 V100 each on GCP
#   ./provision-gpu.sh nvidia-tesla-t4 GCP 3 2      # 3 nodes with 2 T4s each on GCP
#   ./provision-gpu.sh g2-standard-4 GCP 3          # 3 g2-standard-4 nodes on GCP

# Parse parameters with simplified logic
INSTANCE_TYPE=${1:-"g4dn.xlarge"}
PROVIDER=${2:-"AWS"}
GPU_NODE_COUNT=${3:-"1"}

# Special case for GCP with nvidia-* flavors: $4=GPU_COUNT (GPUs per node)
# For all other cases: GPU_COUNT=1
if [[ "$PROVIDER" == "GCP" && "$INSTANCE_TYPE" == *"nvidia-"* ]]; then
    GPU_COUNT=${4:-"1"}
else
    GPU_COUNT="1"
fi

# Display parameters for clarity
echo "=== GPU Node Provisioning Parameters ==="
echo "Instance Type/GPU Flavor: $INSTANCE_TYPE"
echo "Provider: $PROVIDER"
echo "GPU Node Count: $GPU_NODE_COUNT"
echo "GPU Count: $GPU_COUNT"

echo "========================================"

KUSTOMIZE_PATH="$PWD/tasks/Resources/Provisioning/Hive/GPU"
MACHINESET_PATH="$KUSTOMIZE_PATH/base/source-machineset.yaml"
PROVIDER_OVERLAY_DIR=$KUSTOMIZE_PATH/overlays/$PROVIDER
MACHINE_WAIT_TIMEOUT=10m

# On GCP, if the first zone has no GPU capacity, try other zones in the same region (from
# worker MachineSets, or common zone suffixes). Copies matching worker networkInterfaces.
retry_gpu_machineset_other_gcp_zones() {
  local ms=$1
  local replicas=$2
  local wait_timeout=$3
  local current_zone
  current_zone=$(oc get machinesets.machine.openshift.io -n openshift-machine-api "$ms" -o jsonpath='{.spec.template.spec.providerSpec.value.zone}')
  local region="${current_zone%-*}"

  ZONE_CANDIDATES=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && ZONE_CANDIDATES+=("$line")
  done < <(oc get machinesets.machine.openshift.io -n openshift-machine-api -o json | jq -r --arg ms "$ms" --arg cz "$current_zone" '
    [.items[] | select(.metadata.name != $ms)
     | .spec.template.spec.providerSpec.value.zone // empty | select(. != "")]
    | unique | .[] | select(. != $cz)')

  if [[ ${#ZONE_CANDIDATES[@]} -eq 0 ]]; then
    local suf z
    for suf in b c f d a; do
      z="${region}-${suf}"
      [[ "$z" == "$current_zone" ]] && continue
      ZONE_CANDIDATES+=("$z")
    done
  fi

  local z worker_ms patchfile
  for z in "${ZONE_CANDIDATES[@]}"; do
    echo "GPU wait failed in $current_zone; retrying zone $z"
    oc scale machinesets.machine.openshift.io "$ms" -n openshift-machine-api --replicas=0
    oc wait --timeout=10m --for=jsonpath='{.status.replicas}'=0 machinesets.machine.openshift.io "$ms" -n openshift-machine-api || true

    worker_ms=$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o json | jq -r --arg z "$z" --arg gpu "$ms" '
      [.items[] | select(.metadata.name != $gpu)
       | select((.spec.template.spec.providerSpec.value.zone // "") == $z)
       | select((.spec.template.metadata.labels["machine.openshift.io/cluster-api-machine-type"] // "") == "worker")]
      | if length > 0 then .[0].metadata.name else empty end')

    if [[ -n "$worker_ms" ]]; then
      patchfile=$(mktemp)
      oc get machinesets.machine.openshift.io -n openshift-machine-api "$worker_ms" -o json | jq --arg z "$z" '
        [
          {"op": "replace", "path": "/spec/template/spec/providerSpec/value/zone", "value": $z},
          {"op": "replace", "path": "/spec/template/spec/providerSpec/value/networkInterfaces",
           "value": .spec.template.spec.providerSpec.value.networkInterfaces}
        ]' > "$patchfile"
      oc patch machinesets.machine.openshift.io "$ms" -n openshift-machine-api --type=json -p "$(cat "$patchfile")"
      rm -f "$patchfile"
    else
      oc patch machinesets.machine.openshift.io "$ms" -n openshift-machine-api --type=merge -p "{\"spec\":{\"template\":{\"spec\":{\"providerSpec\":{\"value\":{\"zone\":\"$z\"}}}}}}"
    fi

    oc scale machinesets.machine.openshift.io "$ms" -n openshift-machine-api --replicas="$replicas"
    if oc wait --timeout="$wait_timeout" --for jsonpath='{.status.readyReplicas}'="$replicas" machinesets.machine.openshift.io "$ms" -n openshift-machine-api; then
      echo "GPU nodes became ready in zone $z"
      return 0
    fi
    current_zone="$z"
  done
  return 1
}

# Check if existing machineset GPU already exists
EXISTING_GPU_MACHINESET="$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[?(@.metadata.annotations['machine\.openshift\.io/GPU']>'0')].metadata.name}")"
if [[ -n "$EXISTING_GPU_MACHINESET" ]] ; then
  echo "Machine-set for GPU already exists: $EXISTING_GPU_MACHINESET"
  exit 0
fi

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o name | head -n1)
oc get -o yaml -n openshift-machine-api $SOURCE_MACHINESET  > $MACHINESET_PATH

# rename machine set in the template file
OLD_MACHINESET_NAME=$(yq '.metadata.name' $MACHINESET_PATH )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/gpu}
sed -i'' -e "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" $MACHINESET_PATH

if [[ "$PROVIDER" == "GCP" && "$INSTANCE_TYPE" == *"nvidia-"* ]] ; then
  # nvidia-* GPU attachment to n1 instance
  GPU_TYPE=$INSTANCE_TYPE
  INSTANCE_TYPE="n1-standard-4"
  PROVIDER_OVERLAY_DIR="$PROVIDER_OVERLAY_DIR/attach-gpu-to-n1"
  sed -i'' -e "s/GPU_TYPE/$GPU_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
  sed -i'' -e "s/GPU_COUNT/$GPU_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
fi
# set the desired node flavor and replica count in the kustomize overlay
sed -i'' -e "s/INSTANCE_TYPE/$INSTANCE_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
sed -i'' -e "s/GPU_NODE_COUNT/$GPU_NODE_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml

# create the new MachineSet using kustomize
oc apply --kustomize $PROVIDER_OVERLAY_DIR
# Add GPU label to the new machine-set
oc patch machinesets.machine.openshift.io -n openshift-machine-api "$NEW_MACHINESET_NAME" -p '{"metadata":{"labels":{"gpu-machineset":"true"}}}' --type=merge
# wait for the machine to be Ready
echo "Waiting for GPU Node to be Ready"
if ! oc wait --timeout=$MACHINE_WAIT_TIMEOUT --for jsonpath='{.status.readyReplicas}'=$GPU_NODE_COUNT machinesets.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api; then
  if [[ "$PROVIDER" == "GCP" ]] && retry_gpu_machineset_other_gcp_zones "$NEW_MACHINESET_NAME" "$GPU_NODE_COUNT" "$MACHINE_WAIT_TIMEOUT"; then
    exit 0
  fi
  echo "Machine Set $NEW_MACHINESET_NAME does not have its Machines in Running status after $MACHINE_WAIT_TIMEOUT timeout"
  echo "Please check the cluster"
  exit 1
fi
