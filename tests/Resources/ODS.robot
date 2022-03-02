*** Settings ***
Resource  ./Page/LoginPage.robot
Resource  ./Page/ODH/ODHDashboard/ODHDashboard.resource
Resource  ./Page/ODH/JupyterHub/ODHJupyterhub.resource 
Resource  ./Page/ODH/Prometheus/Prometheus.resource


*** Keywords ***
Container Image Should Be
  [Documentation]  Checks if the container image matches  $expected-image-url 
  [Arguments]   ${namespace}  ${pod}  ${container}  ${expected-image-url}
  ${image} =  Run  oc get pod ${pod} -n ${namespace} -o json | jq '.spec.containers[] | select(.name == "${container}") | .image'
  Should Be Equal  ${image}  ${expected-image-url}