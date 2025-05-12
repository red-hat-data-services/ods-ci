#!/bin/bash

RHOAI_VERSION="${1}"
RHOAI_SUB_NAME="${2}"

if [[ -z "${RHOAI_SUB_NAME}" ]]; then
  echo "No RHOAI_SUB_NAME was specified. Getting subscription name"
  RHOAI_SUB=$(oc get sub --all-namespaces -ojson | jq '.items[] | select(.spec.name=="rhods-operator") | .metadata.name + ","+ .metadata.namespace' | tr -d '"')
  IFS=',' read -ra RHOAI_SUB_DETAILS <<< "$RHOAI_SUB"
  echo "${RHOAI_SUB}"
  echo "${RHOAI_SUB_DETAILS[@]}"
fi

if [[ -z "${RHOAI_VERSION}" ]]; then
  echo "No RHOAI_VERSION was specified. Getting currentCSV"
  RHOAI_VERSION=$(oc get sub -ojson ${RHOAI_SUB_DETAILS[0]} -n ${RHOAI_SUB_DETAILS[1]} | jq '.status.currentCSV' | tr -d '"')
fi

if [[ "${RHOAI_VERSION}" != "rhods-operator."* ]]; then
  RHOAI_VERSION="rhods-operator.${RHOAI_VERSION}"
fi

echo "Set startingCSV to '${RHOAI_VERSION}'"
oc patch subscription -n ${RHOAI_SUB_DETAILS[1]} ${RHOAI_SUB_DETAILS[0]} \
   --type='merge' -p "{\"spec\":{\"startingCSV\":\"${RHOAI_VERSION}\"}}"