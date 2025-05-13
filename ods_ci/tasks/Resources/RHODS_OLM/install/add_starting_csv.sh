#!/bin/bash

echo ">> Retrieving RHOAI subscription details"
RHOAI_SUB=$(oc get sub --all-namespaces -ojson | jq '.items[] | select(.spec.name=="rhods-operator") | .metadata.name + ","+ .metadata.namespace' | tr -d '"')
IFS=',' read -ra RHOAI_SUB_DETAILS <<< "$RHOAI_SUB"
echo "${RHOAI_SUB_DETAILS[@]}"
RHOAI_VERSION=$(oc get sub -ojson ${RHOAI_SUB_DETAILS[0]} -n ${RHOAI_SUB_DETAILS[1]} | jq '.status.currentCSV' | tr -d '"')

echo ">> Setting startingCSV to '${RHOAI_VERSION}'"
oc patch subscription -n ${RHOAI_SUB_DETAILS[1]} ${RHOAI_SUB_DETAILS[0]} \
   --type='merge' -p "{\"spec\":{\"startingCSV\":\"${RHOAI_VERSION}\"}}"
