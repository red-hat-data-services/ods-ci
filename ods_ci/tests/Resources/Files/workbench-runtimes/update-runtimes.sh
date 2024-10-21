#!/bin/bash
#######################################################################################
# Follow these steps to update the workbench runtimes in this folder                  #
#  - Open a browser and connect to RHOAI Dashboard                                    #
#  - Create a data science project my-project                                         #
#  - Start a Workbench using the Standard Data Science Image. Name should be wb-sds   #
#  - Open a terminal:                                                                 #
#    - oc login ...                                                                   #
#    - ./update-runtimes.sh my-project                                                #
#  - The workbench runtimes will be downloaded, overwritting existing ones            #
#######################################################################################

RUNTIME_IMAGES_PATH=/opt/app-root/share/jupyter/metadata/runtime-images/

if [ $# -ne 1 ]; then
    echo "Wrong number of parameters: missing project name" >&2
    script_name=$(basename "$0")
    echo "Usage: $script_name my-project" >&2
    exit 2
fi
export MY_PROJECT=${1}

if ! oc get project "$MY_PROJECT" > /dev/null 2>&1
then
    echo "Project $MY_PROJECT not found or not connected to cluster"
    exit 2
fi
oc project $MY_PROJECT

pod_name=$(oc get pods --selector notebook-name=wb-sds -n "$MY_PROJECT"  --no-headers=true | awk '{print $1}')

if [ -z "$pod_name" ]; then
  echo "Could not find a running pod with --selector notebook-name=wb-sds in namespace $MY_PROJECT"
  exit 2
fi

echo "Updating runtimes (getting info from pod $pod_name) ..."
oc rsync "$pod_name":$RUNTIME_IMAGES_PATH  .    -c wb-sds
