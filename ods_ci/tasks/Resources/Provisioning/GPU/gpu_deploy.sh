#!/bin/bash
set -e

echo "Create and apply 'gpu_install.yaml' to install Nvidia GPU Operator"

GPU_INSTALL_DIR="$(dirname "$0")"

CHANNEL="$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')"

CSVNAME="$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -o json | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')"

sed -i -e "0,/v1.11/s//$CHANNEL/g" -e "s/gpu-operator-certified.v1.11.0/$CSVNAME/g"  "$GPU_INSTALL_DIR/gpu_install.yaml"

oc apply -f "$GPU_INSTALL_DIR/gpu_install.yaml"

echo "Wait for Nvidia GPU Operator Subscription, InstallPlan and Deployment to complete"

oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n nvidia-gpu-operator subs nfd

oc wait --timeout=3m --for jsonpath='{.status.state}'=AtLatestKnown -n nvidia-gpu-operator subs gpu-operator-certified

oc wait --timeout=3m --for condition=Installed -n nvidia-gpu-operator installplan --all

oc rollout status --watch --timeout=3m -n nvidia-gpu-operator deployment gpu-operator

oc rollout status --watch --timeout=3m -n nvidia-gpu-operator deployment nfd-controller-manager

function wait_until_pod_ready_status() {
  local timeout_seconds=1200
  local pod_label=$1
  local namespace=nvidia-gpu-operator

  echo "Waiting until GPU pods of '$pod_label' in namespace '$namespace' are in running state..."
  oc wait --timeout=${timeout_seconds}s --for=condition=ready pod -n $namespace -l app="$pod_label"
}

function rerun_accelerator_migration() {
  # As we are adding the GPUs after installing the RHODS operator, those GPUs are not discovered automatically.
  # In order to rerun the migration we need to
  # 1. Delete the migration configmap
  # 2. Rollout restart dashboard deployment, so the configmap is created again and the migration run again
  # Context: https://github.com/opendatahub-io/odh-dashboard/issues/1938

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
oc apply -f "$GPU_INSTALL_DIR/nfd_deploy.yaml"
oc get csv -n nvidia-gpu-operator "$CSVNAME" -o jsonpath='{.metadata.annotations.alm-examples}' | jq .[0] > clusterpolicy.json
oc apply -f clusterpolicy.json
wait_until_pod_ready_status "nvidia-device-plugin-daemonset"
wait_until_pod_ready_status "nvidia-container-toolkit-daemonset"
wait_until_pod_ready_status "nvidia-dcgm-exporter"
wait_until_pod_ready_status "gpu-feature-discovery"
wait_until_pod_ready_status "nvidia-operator-validator"
rerun_accelerator_migration


