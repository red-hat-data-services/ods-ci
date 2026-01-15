#!/bin/bash
set -e

echo "Create and apply 'gpu_install.yaml' to install Nvidia GPU Operator"

GPU_INSTALL_DIR="$(dirname "$0")"

CHANNEL="$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')"

CSVNAME="$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -o json | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')"

sed -i'' -e "0,/v1.11/s//$CHANNEL/g" "$GPU_INSTALL_DIR/gpu_install.yaml"

oc apply -f "$GPU_INSTALL_DIR/gpu_install.yaml"
/bin/bash tasks/Resources/Provisioning/GPU/NFD/install_nfd.sh

echo "Wait for Nvidia GPU Operator Subscription, InstallPlan and Deployment to complete"

oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n nvidia-gpu-operator sub gpu-operator-certified

oc wait --timeout=3m --for condition=Installed -n nvidia-gpu-operator installplan --all

sleep 5

oc rollout status --watch --timeout=3m -n nvidia-gpu-operator deploy gpu-operator

oc wait --timeout=3m --for jsonpath='{.status.components.labelSelector.matchExpressions[].operator}'=Exists operator gpu-operator-certified.nvidia-gpu-operator

function wait_until_pod_ready_status() {
  local pod_label=$1
  local namespace=nvidia-gpu-operator
  local timeout=${2:-360}
  start_time=$(date +%s)
  while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
     pod_status="$(oc get pod -l app="$pod_label" -n "$namespace" --no-headers=true 2>/dev/null)"
     daemon_status="$(oc get daemonset -l app="$pod_label" -n "$namespace" --no-headers=true 2>/dev/null)"
     if [[ -n "$daemon_status" || -n "$pod_status" ]] ; then
        echo "Waiting until GPU Pods or Daemonset of '$pod_label' in namespace '$namespace' are in running state..."
        echo "Pods status: '$pod_status'"
        echo "Daemonset status: '$daemon_status'"
        oc wait --timeout=10s --for=condition=ready pod -n "$namespace" -l app="$pod_label" || \
        if [ $? -ne 0 ]; then
          continue
        fi
        oc rollout status --watch --timeout=3m daemonset -n "$namespace" -l app="$pod_label" || continue
        break
     fi
     echo "Waiting for Pods or Daemonset with label app='$pod_label' in namespace '$namespace' to be present..."
     sleep 5
  done
}

function create_gpu_profile() {
  echo "Creating NVIDIA GPU Profile for OpenDataHub/RHOAI"

  # Check if RHOAI namespace exists
  if ! oc get namespace redhat-ods-applications &>/dev/null; then
    echo "redhat-ods-applications namespace not found. Is RHOAI installed? Profile creation SKIPPED."
    return 0
  fi

  # Check for RHOAI 3.0 (HardwareProfile CRD exists)
  if oc get crd hardwareprofiles.infrastructure.opendatahub.io &>/dev/null; then
    echo "RHOAI 3.0 detected - Creating NVIDIA HardwareProfile"

    # Create HardwareProfile
    oc apply -f - <<EOF
apiVersion: infrastructure.opendatahub.io/v1
kind: HardwareProfile
metadata:
  name: nvidia-gpu-profile
  namespace: redhat-ods-applications
spec:
  displayName: NVIDIA GPU
  description: NVIDIA GPU hardware profile for AI/ML workloads
  enabled: true
  identifiers:
    - identifier: "cpu"
      displayName: "CPU"
      defaultCount: 2
      minCount: 1
      maxCount: 4
      resourceType: "CPU"
    - identifier: "memory"
      displayName: "Memory"
      defaultCount: "4Gi"
      minCount: "2Gi"
      maxCount: "8Gi"
      resourceType: "Memory"
    - identifier: nvidia.com/gpu
      displayName: NVIDIA GPU
      resourceType: Accelerator
      defaultCount: 1
      minCount: 1
      maxCount: 8
  tolerations:
    - effect: NoSchedule
      key: nvidia.com/gpu
      operator: Exists
EOF

    if [[ $? -eq 0 ]]; then
      echo "✅ Successfully created NVIDIA HardwareProfile"
      oc get hardwareprofile nvidia-gpu-profile -n redhat-ods-applications
    else
      echo "❌ Failed to create NVIDIA HardwareProfile"
    fi

  # RHOAI 2.x - Use migration approach
  elif oc get crd acceleratorprofiles.dashboard.opendatahub.io &>/dev/null; then
    echo "RHOAI 2.x detected - Running accelerator migration process"
    create_gpu_profile

  else
    echo "❌ Neither HardwareProfile nor AcceleratorProfile CRD found"
    echo "This could indicate:"
    echo "  - RHOAI/OpenDataHub 1.x (no profile support)"
    echo "  - Incomplete installation"
    echo "  - Custom deployment"
    echo "Profile creation SKIPPED - NVIDIA GPU functionality is not affected"
  fi
}

function create_gpu_profile() {
  # As we are adding the GPUs after installing the RHODS operator, those GPUs are not discovered automatically.
  # In order to rerun the migration we need to
  # 1. Delete the migration configmap
  # 2. Rollout restart dashboard deployment, so the configmap is created again and the migration run again
  # Context: https://github.com/opendatahub-io/odh-dashboard/issues/1938
  echo "Creating NVIDIA Accelerator Profile via RHOAI Dashboard deployment rollout"
  configmap=$(oc get configmap migration-gpu-status --ignore-not-found -n redhat-ods-applications -oname)
  if [ -z $configmap ];
    then
      echo "migration-gpu-status not found. Is RHOAI 2.x Installed? NVIDIA Accelerator Profile creation SKIPPED."
      return 0
  fi
  echo "Deleting configmap migration-gpu-status"
  if ! oc delete configmap migration-gpu-status -n redhat-ods-applications;
    then
      echo "ERROR: When trying to delete the migration-gpu-status configmap"
      return 1
  fi

  echo "Rollout restart rhods-dashboard deployment"
  if ! oc rollout restart deployment.apps/rhods-dashboard -n redhat-ods-applications;
    then
      echo "ERROR: When trying to rollout restart rhods-dashboard deployment"
      return 1
  fi

  echo "Waiting for up to 3 minutes until rhods-dashboard deployment is rolled out"
  oc rollout status deployment.apps/rhods-dashboard -n redhat-ods-applications --watch --timeout 3m

  echo "Verifying that an AcceleratorProfiles resource was created in redhat-ods-applications"
  oc describe AcceleratorProfiles -n redhat-ods-applications
}

wait_until_pod_ready_status  "gpu-operator"

echo "Applying NVIDIA vendor label NodeFeatureRule for GPU detection"
oc apply -f "${GPU_INSTALL_DIR}/nvidia-vendor-label-rule.yaml"

echo "Waiting for NFD to add NVIDIA vendor labels to GPU nodes..."
timeout=300
elapsed=0
gpu_nodes_found=false
while [ $elapsed -lt $timeout ]; do
  gpu_node_count=$(oc get nodes -l feature.node.kubernetes.io/pci-10de.present=true --no-headers 2>/dev/null | wc -l)
  if [ "$gpu_node_count" -gt 0 ]; then
    echo "Found $gpu_node_count GPU node(s) with NVIDIA vendor label"
    gpu_nodes_found=true
    break
  fi
  echo "Waiting for NVIDIA vendor labels on GPU nodes... ($elapsed/$timeout)"
  sleep 5
  elapsed=$((elapsed + 5))
done

if [ "$gpu_nodes_found" = false ]; then
  echo "WARNING: No GPU nodes found with NVIDIA vendor label after ${timeout}s"
  echo "GPU operator may not be able to deploy to nodes"
fi

echo "Applying NVIDIA GPU ClusterPolicy"
oc apply -f "${GPU_INSTALL_DIR}/cluster-policy.yaml"
wait_until_pod_ready_status "nvidia-device-plugin-daemonset" 600
wait_until_pod_ready_status "nvidia-container-toolkit-daemonset"
wait_until_pod_ready_status "nvidia-dcgm-exporter"
wait_until_pod_ready_status "gpu-feature-discovery"
wait_until_pod_ready_status "nvidia-operator-validator"
create_gpu_profile
