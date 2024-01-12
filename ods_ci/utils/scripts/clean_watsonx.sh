#!/bin/bash
TEST_NS="${1-watsonx}"
INF_SERVICE="${2-example-caikit}"
oc delete InferenceService $INF_SERVICE  -n $TEST_NS
oc delete KnativeServing knative-serving -n knative-serving
oc delete Jaeger jaeger -n istio-system
oc delete Kiali kiali -n istio-system
oc delete ServiceMeshControlPlane minimal -n istio-system
oc delete ServiceMeshMemberRoll default -n istio-system


oc delete subscription jaeger-product -n openshift-operators
oc delete subscription kiali-ossm -n openshift-operators
oc delete subscription servicemeshoperator -n openshift-operators
oc delete subscription serverless-operator -n openshift-serverless

jaeger_csv_name=$(oc get csv -n openshift-operators -oname | grep jaeger)
oc delete $jaeger_csv_name -n openshift-operators

kiali_csv_name=$(oc get csv -n openshift-operators -oname | grep kiali)
oc delete $kiali_csv_name -n openshift-operators

sm_csv_name=$(oc get csv -n openshift-operators -oname | grep servicemeshoperator)
oc delete $sm_csv_name -n openshift-operators

sl_csv_name=$(oc get csv -n openshift-serverless -oname | grep serverless-operator)
oc delete $sl_csv_name -n openshift-serverless

oc delete OperatorGroup serverless-operators -n openshift-serverless

oc delete project istio-system
oc delete project knative-serving
oc delete project knative-eventing
oc delete project $TEST_NS
