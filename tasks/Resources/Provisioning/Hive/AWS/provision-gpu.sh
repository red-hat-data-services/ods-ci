#!/bash/bin
# Select the first machineset
SOURCE_MACHINESET=$(oc get machineset -n openshift-machine-api -o name | head -n1)

# Reformat with jq, for better diff result.
oc get -o json -n openshift-machine-api $SOURCE_MACHINESET  | jq -r > /tmp/source-machineset.json

OLD_MACHINESET_NAME=$(jq '.metadata.name' -r /tmp/source-machineset.json )
NEW_MACHINESET_NAME=${OLD_MACHINESET_NAME/worker/worker-gpu}

# Change instanceType and delete some stuff
jq -r '.spec.template.spec.providerSpec.value.instanceType = "g4dn.xlarge"
  | del(.metadata.selfLink)
  | del(.metadata.uid)
  | del(.metadata.creationTimestamp)
  | del(.metadata.resourceVersion)
  ' /tmp/source-machineset.json > /tmp/gpu-machineset.json

# Change machineset name
sed -i "s/$OLD_MACHINESET_NAME/$NEW_MACHINESET_NAME/g" /tmp/gpu-machineset.json

# Create new machineset
oc create -f /tmp/gpu-machineset.json -l gpu-machineset=true
rm /tmp/source-machineset.json
rm /tmp/gpu-machineset.json