*** Settings ***
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Suite Setup      Begin Web Test
Suite Teardown   Teardown


*** Test Cases ***
Test Setting Pod Toleration Via UI
    [Documentation]    Sets a Pod toleration via the admin UI
    [Tags]  Sanity    Tier1
    ...     ODS-1684
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Notebook pod tolerations
    Set Pod Toleration Via UI    TestToleration
    Save Changes In Cluster Settings

Verify Toleration Is Applied To Pod
    [Documentation]    Verifies Pod spawns with toleration
    [Tags]  Sanity    Tier1
    ...     ODS-1685
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook
    Verify Pod Toleration    TestToleration


*** Keywords ***
Set Pod Toleration Via UI
    [Documentation]    Sets toleration using admin UI
    [Arguments]    ${toleration}
    Wait Until Page Contains Element    xpath://input[@id="tolerations-enabled-checkbox"]
    Sleep  2s
    Click Element    xpath://input[@id="tolerations-enabled-checkbox"]
    Wait Until Element Is Enabled    xpath://input[@id="toleration-key-input"]
    Input Text    xpath://input[@id="toleration-key-input"]    ${toleration}

Verify Pod Toleration
    [Documentation]    Verifies Pod contains toleration
    [Arguments]    ${toleration}
    ${expected} =    Set Variable    Tolerations    ${toleration}:NoSchedule op=Exists
    ${current_user} =    Get Current User In JupyterLab
    ${notebook_pod_name} =   Get User Notebook Pod Name  ${current_user}
    ${received} =  Get Pod Tolerations    ${notebook_pod_name}
    Lists Should Be Equal    ${received}    ${expected}
    ...    msg=Unexpected Pod Toleration
    Log    ${received}
    Log    ${expected}

Get Pod Tolerations
    [Documentation]    Returns the list of pod tolerations
    [Arguments]    ${notebook_pod_name}
    OpenShiftLibrary.Search Pods    ${notebook_pod_name}  namespace=rhods-notebooks
    # TODO: This only returns the first toleration. Write keyword to parse whole pod spec and
    # return list of all tolerations
    ${output} =    Run   oc describe pod ${notebook_pod_name} -n rhods-notebooks | grep -i tolerations:
    @{received} =    Split String    ${output}    separator=:${SPACE}
    FOR    ${idx}    IN RANGE    2
        ${el} =  Remove From List  ${received}  0
        ${el} =  Strip String  ${el}
        Append To List  ${received}  ${el}
    END
    [Return]  ${received}

Teardown
    [Documentation]    Removes tolerations and cleans up
    Clean Up Server
    Stop JupyterLab Notebook Server
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains Element    xpath://input[@id="tolerations-enabled-checkbox"]
    Click Element    xpath://input[@id="tolerations-enabled-checkbox"]
    Save Changes In Cluster Settings
    Close Browser
