*** Settings ***
Resource  ./Page/LoginPage.robot
Resource  ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource  ./Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource  ./Page/ODH/Prometheus/Prometheus.resource
Library  OperatingSystem

*** Variables ***


*** Keywords ***
Scale Down rhods-operator Deployment
  [Documentation]  Scales down rhods-operator deployment to 0 pods
  ${output}=  Run   oc -n redhat-ods-operator scale deployment rhods-operator --replicas=0
  Log  ${output}
  Sleep  30  reason=Wait until rhods-operator deployment is scaled down


Scale Up rhods-operator Deployment
  [Documentation]  Scales up rhods-operator deployment to 1 pods
  ${output}=  Run   oc -n redhat-ods-operator scale deployment rhods-operator --replicas=1
  Log  ${output}
  Sleep  120  reason=Wait until rhods-operator deployment is scaled up


Scale Down rhods-dashboard Deployment
  [Documentation]  Scales down rhods-dashboard deployment to 0 pods
  ${output}=  Run   oc scale deployment rhods-dashboard -n redhat-ods-applications --replicas=0
  Log  ${output}
  Sleep  10  reason=Wait until rhods-dashboard deployment is scaled down

Scale Up rhods-dashboard Deployment
  [Documentation]  Scales up rhods-dashboard deployment to 2 pods
  ${output}=  Run   oc scale deployment rhods-dashboard -n redhat-ods-applications --replicas=0
  Log  ${output}
  Sleep  10  reason=Wait until rhods-dashboard deployment is scaled up

Scale Down traefik-proxy Deployment
  [Documentation]  Scales down traefik-proxy deployment to 0 pods
  ${output}=  Run   oc scale deployment traefik-proxy -n redhat-ods-applications --replicas=0
  Log  ${output}
  Sleep  10  reason=Wait until traefik-proxy deployment is scaled down

Scale Up traefik-proxy Deployment
  [Documentation]  Scales up traefik-proxy deployment to 3 pods
  ${output}=  Run   oc scale deployment traefik-proxy -n redhat-ods-applications --replicas=3
  Log  ${output}
  Sleep  10  reason=Wait until traefik-proxy deployment is scaled up
