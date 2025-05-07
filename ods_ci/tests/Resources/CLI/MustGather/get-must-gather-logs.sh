#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.

oc adm must-gather --image=quay.io/modh/must-gather:rhoai-2.19 -- "export OPERATOR_NAMESPACE=${OPERATOR_NAMESPACE};export APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}; /usr/bin/gather" &> must-gather-results.txt

#clean up must-gather.local* 
for dir in must-gather.local*; do
    if [ -d "$dir" ]; then
        echo "Removing existing directory: $dir"
        rm -rf "$dir"
    fi
done


if [ $? -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
fi
