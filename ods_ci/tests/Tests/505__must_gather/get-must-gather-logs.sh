#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.
oc adm must-gather --image=quay.io/modh/must-gather@sha256:5dd8b6f7e72c7fb3a5b46a48304514e4975fd6ed171cc3b1386771151020110a &> must-gather-results.txt

if [ $? -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
fi
