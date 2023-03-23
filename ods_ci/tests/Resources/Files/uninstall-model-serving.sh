#! /bin/bash

MODELMESH_PROJECT=${1:-"redhat-ods-applications"}
INFERENCE_SERVICE_PROJECT=${2:-"mesh-test"}

oc delete kfdef odh-modelmesh -n "$MODELMESH_PROJECT" --ignore-not-found=true &
oc patch kfdef odh-modelmesh --type=merge -p '{"metadata": {"finalizers":null}}' -n "$MODELMESH_PROJECT"
oc delete deployment odh-model-controller -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete deployment modelmesh-controller -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete deployment etcd -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete service etcd -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete service odh-model-controller-metrics-service -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete service modelmesh-serving -n "$MODELMESH_PROJECT" --ignore-not-found=true
oc delete servingruntime triton-2.x -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete service modelmesh-serving -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete pod minio -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete service minio -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete servingruntime mlserver-0.x -n "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
oc delete project "$INFERENCE_SERVICE_PROJECT" --ignore-not-found=true
