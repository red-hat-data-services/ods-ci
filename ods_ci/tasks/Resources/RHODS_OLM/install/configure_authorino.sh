#!/bin/bash

echo ">> Waiting for Authorino service to be created by Kuadrant operator"

# Wait for the Authorino service to exist (max 5 minutes)
if oc wait --for=create svc/authorino-authorino-authorization -n kuadrant-system --timeout=300s 2>/dev/null; then
    echo ">> Authorino service found"
else
    echo ">> ERROR: Authorino service not found after 300 seconds" >&2
    exit 1
fi

# Annotate the service for SSL certificate
echo ">> Annotating Authorino service for SSL certificate"
oc annotate svc/authorino-authorino-authorization service.beta.openshift.io/serving-cert-secret-name=authorino-server-cert -n kuadrant-system --overwrite

if [[ $? -eq 0 ]]; then
    echo ">> Authorino service annotated successfully"
else
    echo ">> Failed to annotate Authorino service" >&2
    exit 1
fi

# Wait for the TLS secret to be created by OpenShift's serving cert controller or cert-manager
echo ">> Waiting for TLS secret to be created..."
if oc wait --for=create secret/authorino-server-cert -n kuadrant-system --timeout=120s 2>/dev/null; then
    echo ">> TLS secret created successfully"
else
    echo ">> ERROR: TLS secret not found after 120 seconds" >&2
    exit 1
fi
