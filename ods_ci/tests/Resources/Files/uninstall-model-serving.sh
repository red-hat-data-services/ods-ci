#! /bin/bash

INFERENCE_SERVICE_PROJECT=${2:-"mesh-test"}

oc delete servingruntime triton-2.x -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete pod minio -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete service minio -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete servingruntime mlserver-0.x -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete project "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
