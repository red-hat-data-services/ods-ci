#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.
oc adm must-gather --image=quay.io/modh/must-gather@sha256:9d5988f45c3b00ec7fbbe7a8a86cc149a2768c9c47e207694fdb6e87ef44adf3 -- "export OPERATOR_NAMESPACE=${OPERATOR_NAMESPACE};export APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}; /usr/bin/gather" &> must-gather-results.txt

if [ $? -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
fi
