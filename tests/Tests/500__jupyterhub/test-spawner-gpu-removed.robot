*** Settings ***
Documentation     Test that the JupyterHub Spawner UI will set gpu=0 when no gpus are in the cluster AND
...               the user previously spawned a notebook that had gpus

Resource          ../../Resources/ODS.robot
Resource          ../../Resources/Common.robot
Resource          ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource          ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource          ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library           DebugLibrary
Library           JupyterLibrary
Library           OpenShiftCLI

Suite Setup       Begin Web Test
Suite Teardown    End Web Test

Force Tags        JupyterHub


*** Variables ***
${NOTEBOOK_IMAGE} =    s2i-generic-data-science-notebook
${GPU_EXISTS}     =    ${False}


*** Test Cases ***
Set Notebook GPU Resource To Non-zero Value
    [Documentation]    Navigate to the JupyterHub spawnerUI and set the gpu count to an invalid value
    [Tags]  ODS-1353

    # The JSP user configMap names use hex encoding for special characters
    ${test_user_jsp_configmap_name} =    Clean Kubernetes Object Name    ${TEST_USER.USERNAME}
    ${test_user_jsp_configmap_name} =    Set Variable  jupyterhub-singleuser-profile-${test_user_jsp_configmap_name}
    ${test_user_jsp_gpu_property} =      Set Variable  gpu: 99
    ${namespace} =                  Set Variable  redhat-ods-applications

    Launch JupyterHub Spawner From Dashboard
    ${GPU_EXISTS} =    Run Keyword And Return Status    Wait Until GPU Dropdown Exists
    Set Suite Variable    \${GPU_EXISTS}    ${GPU_EXISTS}
    Skip If    ${GPU_EXISTS}    SKIPPING due to available GPUs in the cluster


    Debug
    # This will completely overwrite the JSP profile for the user since the data.profile is a string value.
    OpenShiftCLI.Patch    kind=ConfigMap   namespace=${namespace}
    ...                   name=${test_user_jsp_configmap_name}  type=merge
    ...                   src={"data":{"profile":"${test_user_jsp_gpu_property}\nlast_selected_size: Default"}}

    # Sleep then reload page so that we can be sure that the configMap is updated before the SpawnerUI
    # re-reads the new gpu value
    Sleep  5
    ${test_user_jsp_configmap} =    OpenShiftCLI.Get  kind=ConfigMap  namespace=${namespace}
    ...    field_selector=metadata.name==${test_user_jsp_configmap_name}

    Should Contain  ${test_user_jsp_configmap[0]['data']['profile']}  ${test_user_jsp_gpu_property}
    SeleniumLibrary.Reload Page

Can Spawn Notebook
    [Documentation]    Verify that the notebook can spawn successfully with the currect gpu value
    [Tags]  ODS-1353

    Skip If    ${GPU_EXISTS}    SKIPPING due to available GPUs in the cluster
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    Run Keyword If    ${authorization_required}    Authorize jupyterhub service account
    Wait Until Page Contains Element    xpath://span[@id='jupyterhub-logo']

    Spawn Notebook With Arguments  image=${NOTEBOOK_IMAGE}  size=Default

Can Launch Python3 Smoke Test Notebook
    [Documentation]    Verify that the notebook pod launched successfully
    [Tags]  ODS-1353

    Skip If    ${GPU_EXISTS}    SKIPPING due to available GPUs in the cluster
    # Sometimes the kernel is not ready if we run the cell too fast
    Add And Run JupyterLab Code Cell In Active Notebook    import os
    Add And Run JupyterLab Code Cell In Active Notebook    print("Hello World!")

    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible


*** Keywords ***
Clean Kubernetes Object Name
    [Documentation]    Accepts any string with special characters and returns a string with the special
    [Tags]  ODS-1353
    ...    characters hex encoded
    ...    Replaces:
    ...    - ==> -2d
    ...    @ ==> -40
    ...    . ==> -2e
    [Arguments]    ${raw_string}

    # The JSP user configMap names use hex encoding for special characters
    ${new_string} =    Replace String  ${raw_string}  -  -2d
    ${new_string} =    Replace String  ${new_string}  @  -40
    ${new_string} =    Replace String  ${new_string}  .  -2e

    [Return]    ${new_string}
