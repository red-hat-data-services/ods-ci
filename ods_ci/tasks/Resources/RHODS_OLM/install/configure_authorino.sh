#!/bin/bash

echo ">> Waiting for Authorino service to be created by Kuadrant operator"

# Wait for the Authorino service to exist (max 5 minutes)
timeout=300
elapsed=0
while [ $elapsed -lt $timeout ]; do
    if oc get svc/authorino-authorino-authorization -n kuadrant-system &>/dev/null; then
        echo ">> Authorino service found"
        break
    fi
    echo ">> Waiting for Authorino service... ($elapsed seconds elapsed)"
    sleep 10
    elapsed=$((elapsed + 10))
done

# Check if service exists
if ! oc get svc/authorino-authorino-authorization -n kuadrant-system &>/dev/null; then
    echo ">> ERROR: Authorino service not found after $timeout seconds"
    exit 1
fi

# Annotate the service for SSL certificate
echo ">> Annotating Authorino service for SSL certificate"
oc annotate svc/authorino-authorino-authorization service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert -n kuadrant-system --overwrite

if [ $? -eq 0 ]; then
    echo ">> Authorino service annotated successfully"
else
    echo ">> Failed to annotate Authorino service"
    exit 1
fi
