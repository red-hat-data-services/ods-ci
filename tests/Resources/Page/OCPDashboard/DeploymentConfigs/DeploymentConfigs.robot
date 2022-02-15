*** Keywords ***
Restart Rollout
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout restart dc/${dc_name} -n ${namespace}

Start Rollout
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout latest dc/${dc_name} -n ${namespace}