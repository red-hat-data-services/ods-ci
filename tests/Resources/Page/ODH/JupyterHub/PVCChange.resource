*** Settings ***
Documentation   Set of Keywords for PVC change support


*** Keywords ***
Check If PVC Change Is Permanent
    [Documentation]    Check IF PVC chnages are not reverted back
    [Arguments]    ${NUMBERS}
    May Be Delete PVC
    ${size}    Get PVC Size    redhat-ods-applications
    Change PVC Size From ConfigMap     ${NUMBERS}
    Sleep    15s
    ${new_size}    Get PVC Size    redhat-ods-applications
    IF  ${new_size} == ${NUMBERS}[:-2]
        Should Not Be Equal As Integers    ${size}    ${new_size}
    ELSE
        Fail    Unable to change the default PVC size
    END

Verify Notebook Size
   [Arguments]    ${timeout}     ${size}
   [Documentation]   Laucnh JH spawner and compare size
   Set Library Search Order  SeleniumLibrary
   Begin Web Test
   Launch JupyterHub Spawner From Dashboard
   Spawn Notebook With Arguments    image=s2i-minimal-notebook    spawner_timeout=${timeout}
   Run Cell And Check Output    ${SIZE_CODE}   ${size}
   Fix Spawner Status

Verify PVC Size
    [Documentation]   Compare PVC size
    [Arguments]    ${actual_size}     ${expected_size}
    Should Be Equal As Integers    ${actual_size}     ${expected_size}

PVC Size Test Teardown
    [Documentation]    PVC change teardown
    SeleniumLibrary.Close All Browsers
    Change PVC Size From ConfigMap     20Gi
    Roll Out Jupyter Deployement Config
    May Be Delete PVC

Roll Out Jupyter Deployement Config
    [Documentation]    Rollout deployementconfig for JH
    ${rollout_result}    Run Keyword And Return Status
    ...    Run    oc rollout latest dc/jupyterhub -n ${NAMESPACE}
    Should Be Equal    "${rollout_result}"    "True"
    Sleep    20s

May Be Delete PVC
    [Documentation]    Delete PVC from openshift
    ${status}    ${pvc_name}    Run Keyword And Ignore Error
    ...     Get User Notebook PVC Name    ${TEST_USER.USERNAME}
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
