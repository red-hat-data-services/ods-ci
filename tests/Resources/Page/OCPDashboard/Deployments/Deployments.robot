*** Keywords ***
Restart Rollout
    [Arguments]  ${deployment_name}  ${namespace}
    Run Process    oc rollout restart deployment/${deployment_name} -n ${namespace}