#!/bin/bash
set -e

GPU_INSTALL_DIR="$(dirname "$0")"

function create_registry_network() {
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}}}}'
    oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
    echo "Internal registry network created."
}

function check_registry() {
    registry_pod=$(oc get pod -l docker-registry=default -n openshift-image-registry --no-headers -o custom-columns=":metadata.name")
    if [ -n "$registry_pod" ]; then
        echo "Internal registry pod ($registry_pod) is present."
        return 0 # Success
    else
        echo "Internal registry pod is not present."
        create_registry_network
        return 1 # Failure
    fi
}
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

has_csv_succeeded() {
  local ns=$1
  local subscription=$2
  local csv
  csv=$(oc get subscriptions.operators.coreos.com "${subscription}" -n "${ns}" -o=custom-columns=CURRENT_CSV:.status.currentCSV --no-headers=true)
  if [ x"$csv" != "x" ] && [ x"$csv" != x"<none>" ]
  then
    phase=$(oc get clusterserviceversions.operators.coreos.com -n "${ns}" "${csv}" -o=custom-columns=PHASE:.status.phase --no-headers=true)
    if [ x"$phase" = x"Succeeded" ]
    then
      return 0
    fi
  fi

  return 1
}

function create_devconfig() {
  oc create -f - <<EOF
kind: DeviceConfig
apiVersion: amd.io/v1alpha1
metadata:
  name: dc-internal-registry
  namespace: openshift-amd-gpu
EOF
}

function wait_until_pod_ready_status() {
  local timeout_seconds=1200
  local pod_label=$1
  local namespace=$2
  local timeout=240
  start_time=$(date +%s)
  while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
     pod_status="$(oc get pod -l app="$pod_label" -n "$namespace" --no-headers=true 2>/dev/null)"
     daemon_status="$(oc get daemonset -l app="$pod_label" -n "$namespace" --no-headers=true 2>/dev/null)"
     if [[ -n "$daemon_status" || -n "$pod_status" ]] ; then
        echo "Waiting until GPU Pods or Daemonset of '$pod_label' in namespace '$namespace' are in running state..."
        echo "Pods status: '$pod_status'"
        echo "Daemonset status: '$daemon_status'"
        oc wait --timeout="${timeout_seconds}s" --for=condition=ready pod -n "$namespace" -l app="$pod_label" || \
        oc rollout status --watch --timeout=3m daemonset -n "$namespace" -l app="$pod_label" || continue
        break
     fi
     echo "Waiting for Pods or Daemonset with label app='$pod_label' in namespace '$namespace' to be present..."
     sleep 5
  done
}

function machineconfig_updates {
  # There should be only "True" and there should be at least one
  [ True = "$(oc get machineconfigpool --no-headers=true  '-o=custom-columns=UPDATED:.status.conditions[?(@.type=="Updated")].status' | uniq)" ]
}

function monitor_logs() {
    local pod_name=$1
    local search_text=$2
    local ns=$3
    local c_name=$4
    echo "Monitoring logs for pod $pod_name..."

    # Use 'kubectl logs' command to fetch logs continuously

    oc logs "$pod_name" -c "$c_name" -n "$ns" | while read -r line; do
        if [[ $line == *"$search_text"* ]]; then
            echo "Found \"$search_text\" in pod logs: $line"
        fi
    done
}

check_registry
status=$?

# Blacklist the inbox drivers with a MachineConfig if the registry check was successful
if [ $status -eq 0 ]; then
    oc apply -f "$GPU_INSTALL_DIR/blacklist_driver.yaml"
else
    return 1
fi

sleep 120
wait_while 1800 ! machineconfig_updates

echo "Installing NFD operator"
oc apply -f "$GPU_INSTALL_DIR/../nfd_operator.yaml"
wait_while 360 ! has_csv_succeeded openshift-nfd nfd
oc apply -f "$GPU_INSTALL_DIR/../nfd_deploy.yaml"
echo "Installing KMM operator"
oc apply -f "$GPU_INSTALL_DIR/kmm_operator_install.yaml"
wait_while 360 ! has_csv_succeeded openshift-kmm kernel-module-management
echo "Installing AMD operator"
oc apply -f "$GPU_INSTALL_DIR/amd_gpu_install.yaml"
wait_while 360 ! has_csv_succeeded openshift-amd-gpu amd-gpu-operator
create_devconfig
name=$(oc get pod -n openshift-amd-gpu -l openshift.io/build.name -oname)
wait_while 1200 ! monitor_logs "$name" "Successfully pushed image-registry.openshift-image-registry.svc:5000/openshift-amd-gpu" openshift-amd-gpu docker-build
