#!/bin/bash
# Make changes to gpu install file

GPU_INSTALL_DIR="$(dirname "$0")"

CHANNEL=$(oc get packagemanifest gpu-operator-certified -n openshift-marketplace -o jsonpath='{.status.defaultChannel}')

CSVNAME=$(oc get packagemanifests/gpu-operator-certified -n openshift-marketplace -ojson | jq -r '.status.channels[] | select(.name == "'$CHANNEL'") | .currentCSV')

sed -i -e "0,/v1.11/s//$CHANNEL/g" -e "s/gpu-operator-certified.v1.11.0/$CSVNAME/g"  ${GPU_INSTALL_DIR}/gpu_install.yaml

oc apply -f ${GPU_INSTALL_DIR}/gpu_install.yaml

function wait_until_gpu_pods_are_running() {

  local timeout_seconds=1200
  local sleep_time=90

  echo "Waiting until gpu pods are in running state..."

  SECONDS=0
  while [ "$SECONDS" -le "$timeout_seconds" ]; do
    pod_status=$(oc get pods -n "nvidia-gpu-operator" | grep gpu-operator | awk 'NR == 1 { print $3 }')
    if [ "$pod_status" == "Running" ]; then
      break
    else
      ((remaining_seconds = timeout_seconds - SECONDS))
      echo "GPU installation seems to be still running (timeout in $remaining_seconds seconds)..."
      sleep $sleep_time
    fi
  done

  if [ "$pod_status" == "Running" ]; then
    printf "GPU operator is up and running\n"
    return 0
  else
    printf "ERROR: Timeout reached while waiting for gpu operator to be in running state\n"
    return 1
  fi

}

wait_until_gpu_pods_are_running
oc apply -f ${GPU_INSTALL_DIR}/nfd_deploy.yaml
oc get csv -n nvidia-gpu-operator $CSVNAME -ojsonpath={.metadata.annotations.alm-examples} | jq .[0] > clusterpolicy.json
oc apply -f clusterpolicy.json


