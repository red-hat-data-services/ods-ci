#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.
oc adm must-gather --image=quay.io/modh/must-gather@sha256:f49988620efc6227f931c964e45e935838406340a096db84f5736c05066f1cc6 &> must-gather-results.txt

if [ $? -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
fi
