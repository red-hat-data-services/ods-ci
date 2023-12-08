#!/bin/bash
set -e

# Select the first machineset as a template for the GPU machineset
SOURCE_MACHINESET=$(oc get machineset -n openshift-machine-api -o name | head -n1)

# Reformat with jq, for better diff result.
oc get -o json -n openshift-machine-api $SOURCE_MACHINESET  | jq -r > /tmp/source-machineset.json

OLD_MACHINESET_NAME=$(jq '.metadata.name' -r /tmp/source-machineset.json )
NEW_MACHINESET_NAME=test-instascale
NUMBER_OF_REPLICAS=0

# Change number of replicas and delete some stuff
jq -r ".spec.replicas = "$NUMBER_OF_REPLICAS"
  | del(.metadata.annotations)
  | del(.metadata.resourceVersion)
  | del(.metadata.uid)
  | del(.metadata.creationTimestamp)
  | del(.metadata.generation)
  | del(.metadata.managedFields) 
  | del(.status)
  " /tmp/source-machineset.json > /tmp/instascale-machineset.json

# Change machineset name
sed -i "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" /tmp/instascale-machineset.json

# Create new machineset
oc apply -f /tmp/instascale-machineset.json
rm /tmp/source-machineset.json
rm /tmp/instascale-machineset.json
