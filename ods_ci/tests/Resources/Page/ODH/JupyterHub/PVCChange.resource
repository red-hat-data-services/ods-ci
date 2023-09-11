*** Settings ***
Documentation   Set of Keywords for PVC change support
Resource        ../ODHDashboard/ODHDashboardSettings.resource
Library         OpenShiftLibrary


*** Keywords ***
Check If PVC Change Is Permanent
    [Documentation]   Check if PVC changes are not reverted back
    [Arguments]    ${PVC_SIZE}
    ${size}    Get PVC Size    ${APPLICATIONS_NAMESPACE}
    Change PVC Size From ConfigMap     ${PVC_SIZE}
    Sleep    15s
    ${new_size}    Get PVC Size    ${APPLICATIONS_NAMESPACE}
    IF  ${new_size} == ${PVC_SIZE}[:-2]
        Should Not Be Equal As Strings    '${size}'    '${new_size}'
    ELSE
        Fail    Unable to change the default PVC size
    END

Verify Notebook Size
    [Arguments]    ${timeout}     ${size}
    [Documentation]   Launch Jupyter spawner and compare size
    Launch JupyterHub Spawner From Dashboard
    Run Keyword And Return Status    Click Element    //*[@id="pf-modal-part-1"]/div/button
    Spawn Notebook With Arguments    image=minimal-notebook    spawner_timeout=${timeout}
    Run Keyword And Warn On Failure    Run Cell And Check Output
    ...   ${SIZE_CODE}   ${size}
    Fix Spawner Status

Verify PVC Size
    [Documentation]   Compare PVC size
    [Arguments]    ${actual_size}     ${expected_size}
    Should Be Equal As Integers    ${actual_size}     ${expected_size}

PVC Size Test Teardown
    [Documentation]    PVC change teardown
    Close All Browsers
    Change PVC Size From ConfigMap     20Gi
    Run Keyword And Ignore Error     Delete Pods Using Label Selector    ${APPLICATIONS_NAMESPACE}    app=notebook-controller

May Be Delete PVC
    [Documentation]    Delete PVC from openshift
    [Arguments]    ${pvc_name}
    Run Keyword And Return Status    Oc Delete    kind=PersistentVolumeClaim
    ...   field_selector=metadata.name==${pvc_name}    namespace=${NOTEBOOKS_NAMESPACE}

Get Notebook PVC Size
    [Documentation]    Return Notebook PVC size
    [Arguments]  ${username}    ${namespace}
    ${pvc_name}   Get User Notebook PVC Name    ${username}
    ${data}    Oc Get  kind=PersistentVolumeClaim  namespace=${namespace}
    ...     field_selector=metadata.name==${pvc_name}
    ${size}    Set Variable    ${data[0]['status']['capacity']['storage']}
    ${int_size}   Convert To Integer    ${size}[:-2]
    RETURN   ${int_size}

May Be Delete Notebook POD
    [Documentation]   Delete Notebook Pod Name based on Name
    [Arguments]     ${namespace}    ${pod_name}
    Run Keyword And Return Status    Oc Delete    kind=Pod    namespace=${namespace}
    ...    field_selector=metadata.name==${pod_name}

Add User To Dedicated Admin Group
    [Arguments]  ${username}=${TEST_USER.USERNAME}  ${group_name}=dedicated-admins
    Run    oc adm groups add-users ${group_name} ${username}

PVC Size Test Setup
    [Documentation]    PVC change suite setup
    ${status}    ${pvc_name}    Run Keyword And Ignore Error
    ...     Get User Notebook PVC Name    ${TEST_USER.USERNAME}
    May Be Delete PVC     ${pvc_name}
    ${pod_name}    Get User Notebook Pod Name     ${TEST_USER.USERNAME}
    May Be Delete Notebook POD    ${NOTEBOOKS_NAMESPACE}    ${pod_name}

PVC Size UI Test Teardown
    [Documentation]    Teardown for UI test
    [Arguments]     ${default_verification}=False
    Go To    ${ODH_DASHBOARD_URL}
    Restore PVC Value To Default Size
    IF    ${default_verification} == True
          Run Keyword And Warn On Failure   Verify Notebook Size   600s    ${20}
          ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=${NOTEBOOKS_NAMESPACE}
          Run Keyword And Warn On Failure  Verify PVC Size     ${20}       ${pvc_size}
    END
    Close All Browsers
