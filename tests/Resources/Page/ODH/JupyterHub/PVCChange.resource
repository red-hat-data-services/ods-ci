*** Settings ***
Documentation   Set of Keywords for PVC change support


*** Keywords ***
Check If PVC Change Is Permanent
    [Documentation]   Check if PVC changes are not reverted back
    [Arguments]    ${PVC_SIZE}
    ${size}    Get PVC Size    redhat-ods-applications
    Change PVC Size From ConfigMap     ${PVC_SIZE}
    Sleep    15s
    ${new_size}    Get PVC Size    redhat-ods-applications
    IF  ${new_size} == ${PVC_SIZE}[:-2]
        Should Not Be Equal As Strings    '${size}'    '${new_size}'
    ELSE
        Fail    Unable to change the default PVC size
    END

Verify Notebook Size
    [Arguments]    ${timeout}     ${size}
    [Documentation]   Launch JH spawner and compare size
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments    image=s2i-minimal-notebook    spawner_timeout=${timeout}
    Run Keyword And Warn On Failure    Run Cell And Check Output
    ...   ${SIZE_CODE}   ${size}
    Fix Spawner Status

Verify PVC Size
    [Documentation]   Compare PVC size
    [Arguments]    ${actual_size}     ${expected_size}
    Should Be Equal As Integers    ${actual_size}     ${expected_size}

PVC Size Test Teardown
    [Documentation]    PVC change teardown
    SeleniumLibrary.Close All Browsers
    ${status}    ${pvc_name}    Run Keyword And Ignore Error
    ...     Get User Notebook PVC Name    ${TEST_USER.USERNAME}
    May Be Delete PVC     ${pvc_name}
    ${pod_name}    Get User Notebook Pod Name     ${TEST_USER.USERNAME}
    May Be Delete Notebook POD    rhods-notebooks    ${pod_name}
    Change PVC Size From ConfigMap     20Gi
    Roll Out Jupyter Deployment Config

Roll Out Jupyter Deployment Config
    [Documentation]    Rollout deployment config for JH
    ${rollout_result}    Run Keyword And Return Status
    ...    Run    oc rollout latest dc/jupyterhub -n ${NAMESPACE}
    Should Be Equal    "${rollout_result}"    "True"
    Sleep    120s

May Be Delete PVC
    [Documentation]    Delete PVC from openshift
    [Arguments]    ${pvc_name}
    Run Keyword And Return Status    OpenShiftCLI.Delete    kind=PersistentVolumeClaim
    ...   field_selector=metadata.name==${pvc_name}    namespace=rhods-notebooks

Get Notebook PVC Size
    [Documentation]    Return Notebook PVC size
    [Arguments]  ${username}    ${namespace}
    ${pvc_name}   Get User Notebook PVC Name    ${username}
    ${data}    OpenShiftCLI.Get  kind=PersistentVolumeClaim  namespace=${namespace}
    ...     field_selector=metadata.name==${pvc_name}
    ${size}    Set Variable    ${data[0]['status']['capacity']['storage']}
    ${int_size}   Convert To Integer    ${size}[:-2]
    [Return]   ${int_size}

May Be Delete Notebook POD
    [Documentation]   Delete Notebook Pod Name based on Name
    [Arguments]     ${namespace}    ${pod_name}
    Run Keyword And Return Status    OpenShiftCLI.Delete    kind=Pod    namespace=${namespace}
    ...    field_selector=metadata.name==${pod_name}

Add User To Dedicated Admin Group
    [Arguments]  ${username}=${TEST_USER.USERNAME}  ${group_name}=dedicated-admins
    Run    oc adm groups add-users ${group_name} ${username}
