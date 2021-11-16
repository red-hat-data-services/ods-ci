*** Settings ***
Resource  ./Page/LoginPage.robot
Resource  ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource  ./Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource  ./Page/ODH/Prometheus/Prometheus.resource
Library  OperatingSystem

*** Variables ***


*** Keywords ***
Stop RHODS Operator
  [Documentation]  Scales down to 0 the rhods-operator deployment
  ${output}=  Run   oc -n redhat-ods-operator scale deployment rhods-operator --replicas=0
  Log  ${output}
  Sleep  30  reason=Wait until rhods-operator is stopped


Start RHODS Operator
  [Documentation]  Scales up to 1 pod the rhods-operator deployment
  ${output}=  Run   oc -n redhat-ods-operator scale deployment rhods-operator --replicas=1
  Log  ${output}
  Sleep  120  reason=Wait until rhods-operator starts

