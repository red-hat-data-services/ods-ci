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
    Disable Culler
    ${current_timeout} =  Get Culler Timeout
    Should Be Equal  ${DEFAULT_CULLER_TIMEOUT}  ${current_timeout}
    Close Browser

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]    Sanity    Tier1
    ...       ODS-1231
    Modify Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    ${current_timeout} =  Get Culler Timeout
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
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+120}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    Run Keyword And Expect Error  Pods not found in search  OpenShiftLibrary.Search Pods
    ...    ${notebook_pod_name}  namespace=rhods-notebooks

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
    Disable Culler
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

Get Culler Pod
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
        ${culler_pod_name} =  Get Culler Pod
    END
    Log  ${culler_pod}
    Log  ${culler_pod_name}
    [Return]  ${culler_pod_name}

Get Culler Timeout
    [Documentation]    Gets the current culler timeout
    ${current_timeout} =  OpenShiftLibrary.Oc Get  kind=ConfigMap  name=jupyterhub-cfg
    ...    namespace=redhat-ods-applications  fields=['data.culler_timeout']
    ${current_timeout} =  Set Variable  ${current_timeout[0]['data.culler_timeout']}
    Log  ${current_timeout}
    Log To Console  ${current_timeout}
    ${CULLER_POD} =  Get Culler Pod
    ${culler_env_timeout} =  Run  oc exec ${CULLER_POD} -c jupyterhub-idle-culler
    ...    -n redhat-ods-applications -- printenv CULLER_TIMEOUT
    Should Be Equal  ${current_timeout}  ${culler_env_timeout}
    [Return]  ${current_timeout}

Modify Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Cluster Settings
    Set Timeout To  ${new_timeout}
    # Enough time to start the rollout
    Sleep  60s

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

Set Timeout To
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

Disable Culler
    [Documentation]    Disables the culler (i.e. sets the default timeout of 1 year)
    Open Dashboard Cluster Settings
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
        Click Button  Save changes
    END

Teardown
    [Documentation]    Teardown for the test
    Disable Culler
    Launch JupyterHub Spawner From Dashboard
    End Web Test
