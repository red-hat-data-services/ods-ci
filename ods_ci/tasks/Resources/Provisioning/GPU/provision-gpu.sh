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
#   $3 GPU_COUNT      - GPUs per node (for GCP nvidia-* only) OR node count (default: 1)
#   $4 GPU_NODE_COUNT - Number of nodes (for GCP nvidia-* only) (default: 1)
#
# Parameter Logic:
#   For GCP nvidia-* flavors: $3=GPU_COUNT, $4=GPU_NODE_COUNT
#   For all other cases: GPU_COUNT=1, GPU_NODE_COUNT=$3
#
# Examples:
#   ./provision-gpu.sh g4dn.xlarge AWS 2             # 2 g4dn.xlarge nodes on AWS
#   ./provision-gpu.sh n1-standard-4 GCP 3          # 3 n1-standard-4 nodes on GCP
#   ./provision-gpu.sh nvidia-tesla-v100 GCP 1 2    # 2 nodes with 1 V100 each on GCP
#   ./provision-gpu.sh nvidia-tesla-t4 GCP 2 3      # 3 nodes with 2 T4s each on GCP
#   ./provision-gpu.sh g2-standard-4 GCP 3          # 3 g2-standard-4 nodes on GCP

# Parse parameters with simplified logic
INSTANCE_TYPE=${1:-"g4dn.xlarge"}
PROVIDER=${2:-"AWS"}

# Special case for GCP with nvidia-* flavors: $3=GPU_COUNT, $4=GPU_NODE_COUNT
# For all other cases: GPU_COUNT=1, GPU_NODE_COUNT=$3
if [[ "$PROVIDER" == "GCP" && "$INSTANCE_TYPE" == *"nvidia-"* ]]; then
    # GCP nvidia-* flavor: $3=GPU_COUNT, $4=GPU_NODE_COUNT
    GPU_COUNT=${3:-"1"}
    GPU_NODE_COUNT=${4:-"1"}
else
    # All other cases: GPU_COUNT=1, GPU_NODE_COUNT=$3
    GPU_COUNT="1"
    GPU_NODE_COUNT=${3:-"1"}
fi

# Display parameters for clarity
echo "=== GPU Node Provisioning Parameters ==="
echo "Instance Type/GPU Flavor: $INSTANCE_TYPE"
echo "Provider: $PROVIDER"
echo "GPU Node Count: $GPU_NODE_COUNT"

echo "========================================"

# Save original values for validation
ORIGINAL_INSTANCE_TYPE=$INSTANCE_TYPE
KUSTOMIZE_PATH="$PWD/tasks/Resources/Provisioning/Hive/GPU"
MACHINESET_PATH="$KUSTOMIZE_PATH/base/source-machineset.yaml"
PROVIDER_OVERLAY_DIR=$KUSTOMIZE_PATH/overlays/$PROVIDER
MACHINE_WAIT_TIMEOUT=10m
# Check if existing machineset GPU already exists
EXISTING_GPU_MACHINESET="$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o jsonpath="{.items[?(@.metadata.annotations['machine\.openshift\.io/GPU']>'0')].metadata.name}")"
if [[ -n "$EXISTING_GPU_MACHINESET" ]] ; then
  echo "Machine-set for GPU already exists: $EXISTING_GPU_MACHINESET"
  
  # Get current replica count with proper error handling
  CURRENT_REPLICAS=$(oc get machineset.machine.openshift.io $EXISTING_GPU_MACHINESET -n openshift-machine-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
  
  # Check if we could get the replica count
  if [[ -z "$CURRENT_REPLICAS" ]]; then
    echo "Error: Could not get replica count for MachineSet $EXISTING_GPU_MACHINESET"
    echo "MachineSet might not exist or use different API version. Listing all GPU MachineSets:"
    oc get machinesets -n openshift-machine-api | grep -i gpu || echo "No GPU MachineSets found"
    echo "Proceeding to create new MachineSet..."
  else
    echo "Current replicas: $CURRENT_REPLICAS, Desired replicas: $GPU_NODE_COUNT"
  fi
  
  # Validate existing MachineSet configuration matches requirements
  NEEDS_SCALING=false
  NEEDS_RECREATION=false
  
  if [[ -n "$CURRENT_REPLICAS" && "$CURRENT_REPLICAS" != "$GPU_NODE_COUNT" ]]; then
    echo "Replica count differs: Current=$CURRENT_REPLICAS, Requested=$GPU_NODE_COUNT"
    NEEDS_SCALING=true
  fi
  
  # Check if existing MachineSet matches the requested configuration
  if [[ -n "$CURRENT_REPLICAS" ]]; then
    echo "Validating existing MachineSet configuration..."
    
    # Get current instance type
    CURRENT_INSTANCE_TYPE=$(oc get machineset.machine.openshift.io $EXISTING_GPU_MACHINESET -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.machineType}' 2>/dev/null)
    
    # For GCP, check GPU configuration
    if [[ "$PROVIDER" == "GCP" ]]; then
      CURRENT_GPU_COUNT=$(oc get machineset.machine.openshift.io $EXISTING_GPU_MACHINESET -n openshift-machine-api -o json 2>/dev/null | jq -r '.spec.template.spec.providerSpec.value.gpus[0].count // "0"')
      CURRENT_GPU_TYPE=$(oc get machineset.machine.openshift.io $EXISTING_GPU_MACHINESET -n openshift-machine-api -o json 2>/dev/null | jq -r '.spec.template.spec.providerSpec.value.gpus[0].type // "none"')
      
      # Determine expected GPU type based on original input
      if [[ "$ORIGINAL_INSTANCE_TYPE" == *"nvidia-"* ]]; then
        EXPECTED_GPU_TYPE=$ORIGINAL_INSTANCE_TYPE
        EXPECTED_INSTANCE_TYPE="n1-standard-4"
      else
        EXPECTED_GPU_TYPE="nvidia-tesla-t4"
        EXPECTED_INSTANCE_TYPE=$ORIGINAL_INSTANCE_TYPE
      fi
      
      echo "Current config: Instance=$CURRENT_INSTANCE_TYPE, GPU=$CURRENT_GPU_TYPE, GPU_Count=$CURRENT_GPU_COUNT"
      echo "Expected config: Instance=$EXPECTED_INSTANCE_TYPE, GPU=$EXPECTED_GPU_TYPE, GPU_Count=$GPU_COUNT"
      
      # Check if configuration matches (excluding replica count)
      if [[ "$CURRENT_INSTANCE_TYPE" != "$EXPECTED_INSTANCE_TYPE" ]] || \
         [[ "$CURRENT_GPU_TYPE" != "$EXPECTED_GPU_TYPE" ]] || \
         [[ "$CURRENT_GPU_COUNT" != "$GPU_COUNT" ]]; then
        echo "ERROR: Existing MachineSet configuration does not match requested configuration!"
        echo "This would result in different GPU flavor/count than requested."
        echo "Configuration mismatch requires recreation, not just scaling."
        NEEDS_RECREATION=true
        NEEDS_SCALING=false  # Override scaling since we need recreation
      fi
    else
      # For non-GCP providers, check instance type
      if [[ "$CURRENT_INSTANCE_TYPE" != "$ORIGINAL_INSTANCE_TYPE" ]]; then
        echo "ERROR: Existing MachineSet has different instance type ($CURRENT_INSTANCE_TYPE vs $ORIGINAL_INSTANCE_TYPE)"
        echo "Instance type mismatch requires recreation, not just scaling."
        NEEDS_RECREATION=true
        NEEDS_SCALING=false  # Override scaling since we need recreation
      fi
    fi
  fi
  
  # Debug: Show decision logic
  echo "Decision: NEEDS_SCALING=$NEEDS_SCALING, NEEDS_RECREATION=$NEEDS_RECREATION"
  
  # Handle recreation if needed
  if [[ "$NEEDS_RECREATION" == "true" ]]; then
    echo "Deleting existing MachineSet due to configuration mismatch..."
    oc delete machineset.machine.openshift.io $EXISTING_GPU_MACHINESET -n openshift-machine-api
    sleep 10
    echo "Proceeding to create new MachineSet with correct configuration..."
    # Continue to MachineSet creation section
  elif [[ "$NEEDS_SCALING" == "true" ]]; then
    echo "Scaling MachineSet from $CURRENT_REPLICAS to $GPU_NODE_COUNT replicas"
    oc scale machineset.machine.openshift.io $EXISTING_GPU_MACHINESET --replicas=$GPU_NODE_COUNT -n openshift-machine-api
    
    # Set NEW_MACHINESET_NAME for the wait logic
    NEW_MACHINESET_NAME=$EXISTING_GPU_MACHINESET
    
    # Skip to the waiting section
    echo "Waiting for $GPU_NODE_COUNT GPU Node(s) to be Ready"
    oc wait --timeout=$MACHINE_WAIT_TIMEOUT --for jsonpath='{.status.readyReplicas}'=$GPU_NODE_COUNT machinesets.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api
    if [ $? -ne 0 ]; then
      echo "Machine Set $NEW_MACHINESET_NAME does not have its Machines in Running status after $MACHINE_WAIT_TIMEOUT timeout"
      echo "Please check the cluster"
      exit 1
    fi
    echo "GPU MachineSet scaled successfully to $GPU_NODE_COUNT replicas"
    exit 0
  elif [[ -n "$CURRENT_REPLICAS" && "$NEEDS_RECREATION" != "true" ]]; then
    echo "MachineSet already has the desired configuration and $GPU_NODE_COUNT replicas"
    exit 0
  fi
  # If CURRENT_REPLICAS is empty or NEEDS_RECREATION is true, continue to create new MachineSet
fi

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machinesets.machine.openshift.io -n openshift-machine-api -o name | head -n1)
oc get -o yaml -n openshift-machine-api $SOURCE_MACHINESET  > $MACHINESET_PATH

# rename machine set in the template file
OLD_MACHINESET_NAME=$(yq '.metadata.name' $MACHINESET_PATH )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/gpu}
sed -i'' -e "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" $MACHINESET_PATH

if [[ "$PROVIDER" == "GCP" ]] ; then
  if [[ "$INSTANCE_TYPE" == *"nvidia-"* ]] ; then
    # nvidia-* GPU attachment to standard instance
    GPU_TYPE=$INSTANCE_TYPE
    INSTANCE_TYPE="n1-standard-4"
    PROVIDER_OVERLAY_DIR="$PROVIDER_OVERLAY_DIR/attach-gpu-to-n1"
    sed -i'' -e "s/GPU_TYPE/$GPU_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
    sed -i'' -e "s/GPU_COUNT/$GPU_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
  elif [[ "$INSTANCE_TYPE" == *"g2-"* || "$INSTANCE_TYPE" == *"a2-"* || "$INSTANCE_TYPE" == *"g4-"* ]] ; then
    # GPU instance types (g2-standard-4, a2-highgpu-*, etc.) - use standard overlay
    # These instances have built-in GPUs, no need for attach-gpu overlay
    echo "Using GCP GPU instance type: $INSTANCE_TYPE with $GPU_COUNT GPU(s) per node"
  fi
fi
# set the desired node flavor and replica count in the kustomize overlay
sed -i'' -e "s/INSTANCE_TYPE/$INSTANCE_TYPE/g" $PROVIDER_OVERLAY_DIR/gpu.yaml
sed -i'' -e "s/GPU_NODE_COUNT/$GPU_NODE_COUNT/g" $PROVIDER_OVERLAY_DIR/gpu.yaml

# create the new MachineSet using kustomize
echo "Applying kustomization from: $PROVIDER_OVERLAY_DIR"
echo "Current working directory: $PWD"
oc apply --kustomize $PROVIDER_OVERLAY_DIR
# Add GPU label to the new machine-set
oc patch machinesets.machine.openshift.io -n openshift-machine-api "$NEW_MACHINESET_NAME" -p '{"metadata":{"labels":{"gpu-machineset":"true"}}}' --type=merge
# Validate the created MachineSet has correct configuration
echo "Validating created MachineSet configuration..."
if [[ "$PROVIDER" == "GCP" ]]; then
  CREATED_INSTANCE_TYPE=$(oc get machineset.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api -o jsonpath='{.spec.template.spec.providerSpec.value.machineType}')
  
  # Only validate GPU configuration for GPU flavors (nvidia-* or g2-*/a2-*/g4-*)
  if [[ "$ORIGINAL_INSTANCE_TYPE" == *"nvidia-"* || "$ORIGINAL_INSTANCE_TYPE" == *"g2-"* || "$ORIGINAL_INSTANCE_TYPE" == *"a2-"* || "$ORIGINAL_INSTANCE_TYPE" == *"g4-"* ]]; then
    CREATED_GPU_COUNT=$(oc get machineset.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api -o json | jq -r '.spec.template.spec.providerSpec.value.gpus[0].count // "0"')
    CREATED_GPU_TYPE=$(oc get machineset.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api -o json | jq -r '.spec.template.spec.providerSpec.value.gpus[0].type // "none"')
    
    echo "Created MachineSet config: Instance=$CREATED_INSTANCE_TYPE, GPU=$CREATED_GPU_TYPE, GPU_Count=$CREATED_GPU_COUNT, Replicas=$GPU_NODE_COUNT"
    
    # Determine expected values based on GPU flavor type
    if [[ "$ORIGINAL_INSTANCE_TYPE" == *"nvidia-"* ]]; then
      # nvidia-* GPU attachment to standard instance
      EXPECTED_GPU_TYPE=$ORIGINAL_INSTANCE_TYPE
      EXPECTED_INSTANCE_TYPE="n1-standard-4"
    else
      # g2-*/a2-*/g4-* GPU instance types - no GPU attachment, instance has built-in GPUs
      EXPECTED_GPU_TYPE="none"  # No separate GPU attachment for built-in GPU instances
      EXPECTED_INSTANCE_TYPE=$ORIGINAL_INSTANCE_TYPE
    fi
    
    # Validate configuration
    if [[ "$ORIGINAL_INSTANCE_TYPE" == *"nvidia-"* ]]; then
      # For nvidia-* attachments, validate GPU type, count, and instance type
      if [[ "$CREATED_GPU_TYPE" != "$EXPECTED_GPU_TYPE" ]] || [[ "$CREATED_GPU_COUNT" != "$GPU_COUNT" ]] || [[ "$CREATED_INSTANCE_TYPE" != "$EXPECTED_INSTANCE_TYPE" ]]; then
        echo "ERROR: Created MachineSet configuration does not match requested!"
        echo "Expected: Instance=$EXPECTED_INSTANCE_TYPE, GPU=$EXPECTED_GPU_TYPE, GPU_Count=$GPU_COUNT"
        echo "Actual: Instance=$CREATED_INSTANCE_TYPE, GPU=$CREATED_GPU_TYPE, GPU_Count=$CREATED_GPU_COUNT"
        exit 1
      fi
    else
      # For g2-*/a2-*/g4-* instances, only validate instance type (GPUs are built-in)
      if [[ "$CREATED_INSTANCE_TYPE" != "$EXPECTED_INSTANCE_TYPE" ]]; then
        echo "ERROR: Created MachineSet instance type does not match requested!"
        echo "Expected: Instance=$EXPECTED_INSTANCE_TYPE"
        echo "Actual: Instance=$CREATED_INSTANCE_TYPE"
        exit 1
      fi
      echo "GPU configuration: Built-in GPUs for $CREATED_INSTANCE_TYPE (GPU_COUNT parameter: $GPU_COUNT)"
    fi
  else
    # For standard GCP instances, only validate instance type (no GPU validation)
    echo "Created MachineSet config: Instance=$CREATED_INSTANCE_TYPE, Replicas=$GPU_NODE_COUNT (standard instance, no GPU validation)"
    
    if [[ "$CREATED_INSTANCE_TYPE" != "$ORIGINAL_INSTANCE_TYPE" ]]; then
      echo "ERROR: Created MachineSet instance type does not match requested!"
      echo "Expected: Instance=$ORIGINAL_INSTANCE_TYPE"
      echo "Actual: Instance=$CREATED_INSTANCE_TYPE"
      exit 1
    fi
  fi
fi

# wait for the machine to be Ready
echo "Waiting for $GPU_NODE_COUNT GPU Node(s) to be Ready"
oc wait --timeout=$MACHINE_WAIT_TIMEOUT --for jsonpath='{.status.readyReplicas}'=$GPU_NODE_COUNT machinesets.machine.openshift.io $NEW_MACHINESET_NAME -n openshift-machine-api
 if [ $? -ne 0 ]; then
   echo "Machine Set $NEW_MACHINESET_NAME does not have its Machines in Running status after $MACHINE_WAIT_TIMEOUT timeout"
   echo "Please check the cluster"
   exit 1
fi

# Success message with configuration summary
echo "========================================="
echo "✅ GPU Node Provisioning Completed Successfully!"
echo "MachineSet: $NEW_MACHINESET_NAME"
echo "Instance Type: $INSTANCE_TYPE"
echo "Provider: $PROVIDER"
if [[ "$PROVIDER" == "GCP" && "$INSTANCE_TYPE" == *"nvidia-"* ]]; then
  echo "Configuration: $GPU_NODE_COUNT nodes × $GPU_COUNT GPUs each = $((GPU_COUNT * GPU_NODE_COUNT)) total GPUs"
else
  echo "Configuration: $GPU_NODE_COUNT nodes with instance-determined GPU count"
fi
echo "========================================="