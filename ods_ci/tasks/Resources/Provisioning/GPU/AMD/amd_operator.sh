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
    if [ "$phase" = "Succeeded" ]
    then
      return 0
    fi
  fi

  return 1
}

function create_devconfig() {
  dc_name="dc-internal-registry"
  dc=$(oc get DeviceConfig $dc_name -n openshift-amd-gpu -oname --ignore-not-found)
  if [[ -n $dc ]];
    then
      echo "AMD DeviceConfig $dc_name already exists". Skipping creation
    else
      echo "Creating AMD DeviceConfig..."
      oc create -f - <<EOF
kind: DeviceConfig
apiVersion: amd.io/v1alpha1
metadata:
  name: $dc_name
  namespace: openshift-amd-gpu
EOF
  fi
}


function wait_until_pod_is_created() {
  label=$1
  namespace=$2
  timeout=$3
  start_time=$(date +%s)
  while [ $(($(date +%s) - start_time)) -lt $timeout ]; do
    podName=$(oc get pods -n $2 -l $1 -oname)
    if [[ -n $podName ]];
      then {
        echo Pod $podName found!
        return 0
      } else {
        echo "waiting for pod with label $label"
        sleep 2
      }
    fi
  done
  echo "Timeout exceeded, pod with label $label not found"
  return 1
}

function machineconfig_updates {
  # There should be only "True" and there should be at least one
  [ True = "$(oc get machineconfigpool --no-headers=true  '-o=custom-columns=UPDATED:.status.conditions[?(@.type=="Updated")].status' | uniq)" ]
}

function monitor_logs() {
    local pod_name=$1
    local ns=$2
    local c_name=$3
    shift 3
    local search_text=$(printf "%q " "$@")
    echo "Monitoring logs for pod $pod_name..."
    # Use 'kubectl logs' command to fetch logs continuously
    oc logs "$pod_name" -c "$c_name" -n "$ns" | while read -r line; do
        if [[ $line == *"$search_text"* ]]; then
            echo "Found \"$search_text\" in pod logs: $line"
        fi
    done
}

function wait_until_driver_image_is_built() {
  startup_timeout=$1
  build_timeout=$2
  name=$(oc get pod -n openshift-amd-gpu -l openshift.io/build.name -oname)
  echo Builder pod name: $name
  oc wait --timeout="${startup_timeout}s" --for=condition=ready pod -n openshift-amd-gpu -l openshift.io/build.name
  echo "Wait for the image build to finish"
  oc wait --timeout="${build_timeout}s" --for=delete pod -n openshift-amd-gpu -l openshift.io/build.name
  echo "Checking the image stream got created"
  image=$(oc get is amd_gpu_kmm_modules -n openshift-amd-gpu -oname)
  if [[ $? -eq 0 ]];
    then
      echo ".Image Stream $image found!"
    else
      echo ".Image Stream amd_gpu_kmm_modules not found. Check the cluster"
      exit 1
  fi
}

function create_acceleratorprofile() {
  echo "Creating an Accelerator Profile for Dashboard"
  oc apply -f - <<EOF
  apiVersion: dashboard.opendatahub.io/v1
  kind: AcceleratorProfile
  metadata:
    name: ods-ci-amd-gpu
    namespace: redhat-ods-applications
  spec:
    displayName: AMD GPU
    enabled: true
    identifier: amd.com/gpu
    tolerations:
      - effect: NoSchedule
        key: amd.com/gpu
        operator: Exists
EOF
  if [ $? -eq 0 ]; then
    echo "Verifying that an AcceleratorProfiles resource was created in redhat-ods-applications"
    oc describe AcceleratorProfiles -n redhat-ods-applications
  fi 
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
image=$(oc get is amd_gpu_kmm_modules -n openshift-amd-gpu -oname --ignore-not-found)
if [[ -n $image ]];
  then
      echo ".Image Stream amd_gpu_kmm_modules alredy present! Skipping waiting for builder pod";
  else
      wait_until_pod_is_created  openshift.io/build.name openshift-amd-gpu 180
      wait_until_driver_image_is_built 60 1200
fi
echo "Configuration of AMD GPU node and Operators completed"
# the message appears in the logs, but the pod may get delete before our code next iteration checks the logs once again,
# hence it'd fails to reach the pod. It happened to me
# wait_while 1200 monitor_logs "$name" openshift-amd-gpu docker-build "Successfully pushed image-registry.openshift-image-registry.svc:5000/openshift-amd-gpu"
create_acceleratorprofile
