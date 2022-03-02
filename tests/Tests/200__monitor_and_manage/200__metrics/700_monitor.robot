*** Settings ***
Resource    ../../../Resources/ODS.robot
Resource    ../../../Resources/Common.robot
Resource    ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource    ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Library        JupyterLibrary
Library        SeleniumLibrary
Library        OpenShiftCLI
Library        OperatingSystem


*** Test Cases ***
Verify that Prometheus image is a CPaaS built image with oc
  [Tags]  ODS-734
  ${pod} =  Run  oc get pods -n redhat-ods-monitoring -o json | jq '.items[] | select(.kind == "Pod") | select(.metadata.name | startswith("prometheus-")) | .metadata.name'
  Container Image Should Be  redhat-ods-monitoring  ${pod}  prometheus  "registry.redhat.io/openshift4/ose-prometheus"
  Container Image Should Be  redhat-ods-monitoring  ${pod}  oauth-proxy  "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"
