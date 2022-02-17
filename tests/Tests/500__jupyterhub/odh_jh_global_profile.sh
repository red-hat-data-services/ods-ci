#!/bin/bash
# This script is helper script to modify the odh-jh-global-profiles
MY_VALUE=$1
if [[ "$MY_VALUE" == "modify" ]]
then
    oc patch -n redhat-ods-applications configmaps odh-jupyterhub-global-profile --type=merge -p '{"data":{"jupyterhub-singleuser-profiles.yaml":"profiles:\n  - name: globals\n    resources:\n      requests:\n        memory: 6Gi\n        cpu: 2\n      limits:\n        memory: 9Gi\n        cpu: 6\n"}}'

elif [[ "$MY_VALUE" == "default" ]]
then
    oc patch -n redhat-ods-applications configmaps odh-jupyterhub-global-profile --type=merge -p '{"data":{"jupyterhub-singleuser-profiles.yaml":"profiles:\n  - name: globals\n    resources:\n      requests:\n        memory: 4Gi\n        cpu: 1\n      limits:\n        memory: 8Gi\n        cpu: 2\n"}}'
else
   echo "Don't seems to provide the correct command line input, Supported input value are modify and default"
fi
