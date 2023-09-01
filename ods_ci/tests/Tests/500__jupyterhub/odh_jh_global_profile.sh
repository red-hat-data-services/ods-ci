#!/bin/bash
# This script is helper script to modify the odh-jh-global-profiles
MY_VALUE=$1
if [[ "$MY_VALUE" == "modify" ]]
then
    oc patch -n ${APPLICATIONS_NAMESPACE} OdhDashboardConfigs odh-dashboard-config --type=merge -p '{"spec":{"notebookSizes":[{"name":"Small","resources":{"limits":{"cpu":"6","memory":"9Gi"},"requests":{"cpu":"2","memory":"6Gi"}}},{"name":"Medium","resources":{"limits":{"cpu":"6","memory":"24Gi"},"requests":{"cpu":"3","memory":"24Gi"}}},{"name":"Large","resources":{"limits":{"cpu":"14","memory":"56Gi"},"requests":{"cpu":"7","memory":"56Gi"}}},{"name":"X Large","resources":{"limits":{"cpu":"30","memory":"120Gi"},"requests":{"cpu":"15","memory":"120Gi"}}}]}}'

elif [[ "$MY_VALUE" == "default" ]]
then
     oc patch -n ${APPLICATIONS_NAMESPACE} OdhDashboardConfigs odh-dashboard-config --type=merge -p '{"spec":{"notebookSizes":[{"name":"Small","resources":{"limits":{"cpu":"2","memory":"8Gi"},"requests":{"cpu":"1","memory":"8Gi"}}},{"name":"Medium","resources":{"limits":{"cpu":"6","memory":"24Gi"},"requests":{"cpu":"3","memory":"24Gi"}}},{"name":"Large","resources":{"limits":{"cpu":"14","memory":"56Gi"},"requests":{"cpu":"7","memory":"56Gi"}}},{"name":"X Large","resources":{"limits":{"cpu":"30","memory":"120Gi"},"requests":{"cpu":"15","memory":"120Gi"}}}]}}'
else
   echo "Don't seems to provide the correct command line input, Supported input value are modify and default"
fi
