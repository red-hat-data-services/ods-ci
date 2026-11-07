#!/bin/sh
# Redirecting stdout/stderr of must-gather to a file, as it fills up the
# process buffer and prevents the script from running further.
# Bound the gather with GNU timeout so a hung oc/gather cannot stall CI
# for hours (RHOAIENG-88048).
#clean up must-gather.local*
for dir in must-gather.local*; do
    if [ -d "$dir" ]; then
        echo "Removing existing directory: $dir"
        rm -rf "$dir"
    fi
done

cleanup_gather_namespaces() {
    oc get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null \
        | grep '^openshift-must-gather-' \
        | while IFS= read -r ns; do
            echo "Deleting leftover must-gather namespace: ${ns}"
            oc delete ns "${ns}" --wait=false --ignore-not-found=true || true
        done
}

if ! command -v timeout >/dev/null 2>&1; then
    echo "FAIL: GNU timeout is required to bound oc adm must-gather"
    exit 1
fi

IMAGE="${MUST_GATHER_IMAGE:-quay.io/rhoai/odh-must-gather-rhel9:rhoai-3.0}"
GATHER_TIMEOUT="${MUST_GATHER_TIMEOUT:-15m}"

echo "Starting oc adm must-gather (timeout ${GATHER_TIMEOUT}, image ${IMAGE}) at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"

timeout "${GATHER_TIMEOUT}" oc adm must-gather --image="${IMAGE}" --volume-percentage=90 -- \
    "export OPERATOR_NAMESPACE=${OPERATOR_NAMESPACE};export APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}; /usr/bin/gather" \
    > must-gather-results.txt 2>&1
rc=$?

echo "must-gather finished with rc=${rc} at $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if [ -f must-gather-results.txt ]; then
    echo "----- tail of must-gather-results.txt -----"
    tail -n 50 must-gather-results.txt
    echo "----- end tail -----"
fi

if [ "${rc}" -eq 124 ]; then
    echo "FAIL: oc adm must-gather timed out after ${GATHER_TIMEOUT}"
    cleanup_gather_namespaces
    exit 1
fi

if [ "${rc}" -eq 0 ]
then
    echo "SUCCESS: must-gather logs can be found in repo must-gather-local.*"
else
    echo "FAIL : Unable to get must-gather logs"
    cleanup_gather_namespaces
    exit 1
fi
