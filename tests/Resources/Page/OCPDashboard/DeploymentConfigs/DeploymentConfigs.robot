*** Keywords ***
Restart Rollout
    [Documentation]     Rollout a deployment in Openshift using restart mode
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout restart dc/${dc_name} -n ${namespace}

Start Rollout
    [Documentation]     Rollout a deployment in Openshift fetching the latest version
    [Arguments]  ${dc_name}  ${namespace}
    Run    oc rollout latest dc/${dc_name} -n ${namespace}
