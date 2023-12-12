#!/bin/sh
oc get secret -n istio-system knative-serving-cert -o json | jq '.data."tls.crt"' | sed 's/"//g' | base64 -d > openshift_ca_istio_knative.crt
