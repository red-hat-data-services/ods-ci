#!/bin/bash
TEST_NS="${1-watsonx}"
INF_SERVICE="${2-example-caikit}"
oc delete InferenceService $INF_SERVICE  -n $TEST_NS
oc delete KnativeServing knative-serving -n knative-serving
oc delete Jaeger jaeger -n istio-system
oc delete Kiali kiali -n istio-system

oc delete subscription jaeger-product -n openshift-operators
oc delete subscription kiali-ossm -n openshift-operators

jaeger_csv_name=$(oc get csv -n openshift-operators -oname | grep jaeger)
oc delete $jaeger_csv_name -n openshift-operators

kiali_csv_name=$(oc get csv -n openshift-operators -oname | grep kiali)
oc delete $kiali_csv_name -n openshift-operators

oc delete project $TEST_NS
