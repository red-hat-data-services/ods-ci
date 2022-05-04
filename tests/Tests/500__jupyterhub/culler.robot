*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Library          ../../../libs/Helpers.py
Library          OpenShiftLibrary
Suite Teardown   Teardown
Force Tags       JupyterHub


*** Variables ***
${DEFAULT_CULLER_TIMEOUT} =    31536000
${CUSTOM_CULLER_TIMEOUT} =     600


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]    Sanity    Tier1
    ...       ODS-1255
    Disable Notebook Culler
    ${current_timeout} =  Get And Verify Notebook Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}
    Close Browser

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]    Sanity    Tier1
    ...       ODS-1231
    Modify Notebook Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    ${current_timeout} =  Get And Verify Notebook Culler Timeout
    Should Not Be Equal  ${current_timeout}  ${DEFAULT_CULLER_TIMEOUT}
    Should Be Equal   ${current_timeout}  ${CUSTOM_CULLER_TIMEOUT}
    Close Browser

Verify Culler Kills Inactive Server
    [Documentation]    Verifies that the culler kills an inactive
    ...    server after timeout has passed.
    [Tags]    Sanity    Tier1
    ...       ODS-1254
    Spawn Minimal Image
    Clone Git Repository And Run    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Inactive.ipynb
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${CUSTOM_CULLER_TIMEOUT}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    ${culled} =  Set Variable  False
    ${drift} =  Set Variable  ${0}
    # Wait for maximum 10 minutes over timeout
    FOR  ${index}  IN RANGE  20
        ${culled} =  Run Keyword And Return Status  Run Keyword And Expect Error
        ...    Pods not found in search  OpenShiftLibrary.Search Pods
        ...    ${notebook_pod_name}  namespace=rhods-notebooks
        Exit For Loop If  ${culled}==True
        Sleep  30s
        ${drift} =  Evaluate  ${drift}+${30}
    END
    IF  ${drift}>${120}
        Fail    Drift was over 2 minutes, it was ${drift} seconds
    END

Verify Culler Does Not Kill Active Server
    [Documentation]    Verifies that the culler does not kill an active
    ...    server even after timeout has passed.
    [Tags]    Sanity    Tier1
    ...       ODS-1253
    Spawn Minimal Image
    Clone Git Repository And Open    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Active.ipynb
    Open With JupyterLab Menu    Run    Run All Cells
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+120}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks

Verify Do Not Stop Idle Notebooks
    [Documentation]    Disables the culler (default configuration) and verifies nb is not culled
    [Tags]    Sanity    Tier1
    ...       ODS-1230
    Disable Notebook Culler
    Close Browser
    Spawn Minimal Image
    Clone Git Repository And Run    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Inactive.ipynb
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+120}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks


*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Default

Get Notebook Culler Pod Name
    [Documentation]    Finds the current culler pod and returns the name
    ${culler_pod} =  OpenShiftLibrary.Oc Get  kind=Pod
    ...    label_selector=app=jupyterhub-idle-culler  namespace=redhat-ods-applications
    ${length} =  Get Length  ${culler_pod}
    # Only 1 culler pod, correct one
    IF  ${length}==1
        ${culler_pod_name} =  Set Variable  ${culler_pod[0]}[metadata][name]
    ELSE
        # There can be more than one during rollout
        Sleep  10s
        ${culler_pod_name} =  Get Notebook Culler Pod Name
    END
    Log  ${culler_pod}
    Log  ${culler_pod_name}
    [Return]  ${culler_pod_name}

Get And Verify Notebook Culler Timeout
    [Documentation]    Gets the current culler timeout from configmap and culler pod, compares the two
    ...    And returns the value
    ${current_timeout} =  Get Notebook Culler Timeout From Configmap
    Log  ${current_timeout}
    ${culler_env_timeout} =  Get Notebook Culler Timeout From Culler Pod
    Log  ${culler_env_timeout}
    Should Be Equal  ${current_timeout}  ${culler_env_timeout}
    [Return]  ${current_timeout}

Get Notebook Culler Timeout From Configmap
    [Documentation]    Gets the current culler timeout from configmap
    ${current_timeout} =  OpenShiftLibrary.Oc Get  kind=ConfigMap  name=jupyterhub-cfg
    ...    namespace=redhat-ods-applications  fields=['data.culler_timeout']
    ${current_timeout} =  Set Variable  ${current_timeout[0]['data.culler_timeout']}
    [Return]  ${current_timeout}

Get Notebook Culler Timeout From Culler Pod
    [Documentation]    Gets the current culler timeout from culler pod
    ${CULLER_POD} =  Get Notebook Culler Pod Name
    ${culler_env_timeout} =  Run  oc exec ${CULLER_POD} -c jupyterhub-idle-culler -n redhat-ods-applications -- printenv CULLER_TIMEOUT  # robocop: disable
    [Return]  ${culler_env_timeout}

Modify Notebook Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Cluster Settings
    Set Notebook Culler Timeout  ${new_timeout}
    Sleep  30s  msg=Give time for rollout

Open Dashboard Cluster Settings
    [Documentation]    Opens the RHODS dashboard and navigates to the Cluster settings page
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Sleep  5
    ${settings_hidden} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://section[@aria-labelledby="settings"][@hidden=""]
    IF  ${settings_hidden}==True
        Click Element  xpath://button[@id="settings"]
    END
    Click Element  xpath://a[.="Cluster settings"]

Set Notebook Culler Timeout
    [Documentation]    Modifies the notebook culler timeout using the dashboard UI setting it to ${new_timeout} seconds
    [Arguments]    ${new_timeout}
    ${hours}  ${minutes} =  Convert To Hours And Minutes  ${new_timeout}
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==True
        Click Element  xpath://input[@id="culler-timeout-limited"]
    END
    Input Text  //input[@id="hour-input"]  ${hours}
    Input Text  //input[@id="minute-input"]  ${minutes}
    Click Button  Save changes

Disable Notebook Culler
    [Documentation]    Disables the culler (i.e. sets the default timeout of 1 year)
    Open Dashboard Cluster Settings
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
        Click Button  Save changes
    END
    Sleep  30s  msg=Give time for rollout

Teardown
    [Documentation]    Teardown for the test
    Disable Notebook Culler
    Launch JupyterHub Spawner From Dashboard
    End Web Test
