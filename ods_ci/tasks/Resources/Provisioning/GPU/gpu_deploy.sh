#!/bin/bash
# Make changes to gpu install file

GPU_INSTALL_DIR="$(dirname "$0")"

CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')

CSVNAME=$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')

sed -i -e "0,/v1.11/s//$CHANNEL/g" -e "s/gpu-operator-certified.v1.11.0/$CSVNAME/g"  ${GPU_INSTALL_DIR}/gpu_install.yaml

oc apply -f ${GPU_INSTALL_DIR}/gpu_install.yaml

function wait_until_pod_ready_status() {

  local timeout_seconds=1200
  local sleep_time=90
  local pod_label=$1
  local namespace=nvidia-gpu-operator

  echo "Waiting until gpu pods are in running state..."

  SECONDS=0
  while [ "$SECONDS" -le "$timeout_seconds" ]; do
    pod_status=$(oc get pods -lapp=$pod_label -n $namespace -ojsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' 2>/dev/null || echo "terminated")
    if [ "$pod_status" == "True" ]; then
			pod_terminating_status=$(oc get pods -lapp=$pod_label -n $namespace -o jsonpath='{.items[0].metadata.deletionGracePeriodSeconds}' 2>/dev/null || echo "terminated")
			if [ "${pod_terminating_status}" != "" ]; then
				echo "pod $pod_label is in terminating state..."
			else
				echo "Pod $pod_label is ready"
				break;
			fi
    else
      ((remaining_seconds = timeout_seconds - SECONDS))
      echo "GPU installation seems to be still running (timeout in $remaining_seconds seconds)..."
      oc get pods -n $namespace
      sleep $sleep_time
    fi
  done

  if [ "$pod_status" == "True" ] ; then
    printf "GPU operator is up and running\n"
    return 0
  else
    printf "ERROR: Timeout reached while waiting for gpu operator to be in running state\n"
    return 1
  fi

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
      printf "ERROR: When trying to delete the migration-gpu-status configmap\n"
      return 1
  fi

  echo "Rollout restart rhods-dashboard deployment"
  if ! oc rollout restart deployment.apps/rhods-dashboard -n redhat-ods-applications;
    then
      printf "ERROR: When trying to rollout restart rhods-dashboard deployment\n"
      return 1
  fi

  echo "Waiting for up to 3 minutes until rhods-dashboard deployment is rolled out"
  oc rollout status deployment.apps/rhods-dashboard -n redhat-ods-applications --watch --timeout 3m

  echo "Verifying that an AcceleratorProfiles resource was created in redhat-ods-applications"
  oc describe AcceleratorProfiles -n redhat-ods-applications

}

wait_until_pod_ready_status  "gpu-operator"
oc apply -f ${GPU_INSTALL_DIR}/nfd_deploy.yaml
oc get csv -n nvidia-gpu-operator $CSVNAME -ojsonpath={.metadata.annotations.alm-examples} | jq .[0] > clusterpolicy.json
oc apply -f clusterpolicy.json
wait_until_pod_ready_status "nvidia-device-plugin-daemonset"
wait_until_pod_ready_status "nvidia-container-toolkit-daemonset"
wait_until_pod_ready_status "nvidia-dcgm-exporter"
wait_until_pod_ready_status "gpu-feature-discovery"
wait_until_pod_ready_status "nvidia-operator-validator"
rerun_accelerator_migration


