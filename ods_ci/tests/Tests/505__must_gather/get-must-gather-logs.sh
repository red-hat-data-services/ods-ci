#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.
oc adm must-gather --image=quay.io/modh/must-gather@sha256:4a8d9398fdbc073e32611364d715a7210ce695d8b6bbbe957e3f9de6e4374e45 &> must-gather-results.txt

if [ $? -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
fi
