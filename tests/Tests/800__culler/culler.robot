*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
#Resource         ../400__ods_dashboard/410__ods_dashboard_settings.robot
Library          ../../../libs/Helpers.py
Library          OpenShiftLibrary
Suite Teardown   Teardown
Force Tags       JupyterHub


*** Variables ***
${CUSTOM_CULLER_TIMEOUT} =     600
${CUSTOM_CULLER_TIMEOUT_MINUTES} =     ${{${CUSTOM_CULLER_TIMEOUT}//60}}


*** Test Cases ***
Verify Default Culler Timeout
    [Documentation]    Checks default culler timeout
    [Tags]    Tier2
    ...       ODS-1255
    Disable Notebook Culler
    # When disabled the cm doesn't exist, expect error
    ${configmap} =  Run Keyword And Expect Error  STARTS: ResourceOperationFailed: Get failed
    ...    OpenShiftLibrary.Oc Get  kind=ConfigMap  name=notebook-controller-culler-config    namespace=redhat-ods-applications
    Close Browser

Verify Culler Timeout Can Be Updated
    [Documentation]    Verifies culler timeout can be updated
    [Tags]    Tier2
    ...       ODS-1231
    Modify Notebook Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    ${current_timeout} =  Get And Verify Notebook Culler Timeout
    Should Be Equal As Integers   ${current_timeout}  ${CUSTOM_CULLER_TIMEOUT_MINUTES}
    Close Browser

Verify Culler Kills Inactive Server
    [Documentation]    Verifies that the culler kills an inactive
    ...    server after timeout has passed.
    [Tags]    Tier2
    ...       ODS-1254
    ...       Execution-Time-Over-15m
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
    [Tags]    Tier2
    ...       ODS-1253
    ...       Execution-Time-Over-15m
    ...       AutomationBug
    ${NOTEBOOK_TO_RUN} =  Set Variable  ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Active.ipynb
    Spawn Minimal Image
    Clone Git Repository And Open    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ${NOTEBOOK_TO_RUN}
    Wait Until ${{"${NOTEBOOK_TO_RUN}".split("/")[-1] if "${NOTEBOOK_TO_RUN}"[-1]!="/" else "${NOTEBOOK_TO_RUN}".split("/")[-2]}} JupyterLab Tab Is Selected
    Close Other JupyterLab Tabs
    Sleep  0.5s
    Open With JupyterLab Menu  Run  Run All Cells
    Sleep  0.5s
    Open With JupyterLab Menu    File    Save Notebook
    Sleep  0.5s
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+120}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks

Verify Do Not Stop Idle Notebooks
    [Documentation]    Disables the culler (default configuration) and verifies nb is not culled
    [Tags]    Tier2
    ...       ODS-1230
    ...       Execution-Time-Over-15m
    Disable Notebook Culler
    Close Browser
    Spawn Minimal Image
    Clone Git Repository And Run    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Inactive.ipynb
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+120}
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=rhods-notebooks

Verify That "Stop Idle Notebook" Setting Is Not Overwritten After Restart Of Operator Pod
    [Documentation]    Restart the operator pod and verify if "Stop Idle Notebook" setting
    ...   is overwritten or not.
    ...   ProductBug:RHODS-4336
    [Tags]    Tier2
    ...       ProductBug
    ...       ODS-1607
    Modify Notebook Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    Oc Delete    kind=Pod     namespace=redhat-ods-operator    label_selector=name=rhods-operator
    sleep   5    msg=waiting time for the operator pod to be replaced with new one
    Reload Page
    Wait Until Page Contains Element    xpath://input[@id="culler-timeout-unlimited"]
    ${status} =    Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF    ${status}==True
        Fail    Restart of operator pod causing 'Stop Idle Notebook' setting to change in RHODS dashboard
    END


*** Keywords ***
Spawn Minimal Image
    [Documentation]    Spawn a minimal image
    Begin Web Test
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook With Arguments  image=s2i-minimal-notebook  size=Small

Get Notebook Culler Pod Name
    [Documentation]    Finds the current culler pod and returns the name
    ${culler_pod} =  OpenShiftLibrary.Oc Get  kind=Pod
    ...    label_selector=component.opendatahub.io/name=kf-notebook-controller  namespace=redhat-ods-applications
    ${culler_pod_name} =  Set Variable  ${culler_pod[0]}[metadata][name]
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
    ${current_timeout} =  OpenShiftLibrary.Oc Get  kind=ConfigMap  name=notebook-controller-culler-config
    ...    namespace=redhat-ods-applications  fields=['data.CULL_IDLE_TIME']
    ${current_timeout} =  Set Variable  ${current_timeout[0]['data.CULL_IDLE_TIME']}
    [Return]  ${current_timeout}

Get Notebook Culler Timeout From Culler Pod
    [Documentation]    Gets the current culler timeout from culler pod
    ${CULLER_POD} =  Get Notebook Culler Pod Name
    ${culler_env_timeout} =  Run  oc exec ${CULLER_POD} -n redhat-ods-applications -- printenv CULL_IDLE_TIME  # robocop: disable
    [Return]  ${culler_env_timeout}

Modify Notebook Culler Timeout
    [Documentation]    Modifies the culler timeout via UI
    [Arguments]    ${new_timeout}
    Open Dashboard Cluster Settings
    Set Notebook Culler Timeout  ${new_timeout}
    Sleep  10s  msg=Give time for rollout

Open Dashboard Cluster Settings
    [Documentation]    Opens the RHODS dashboard and navigates to the Cluster settings page
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Sleep  1s
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
    ${disabled_field} =  Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==True
        Click Element  xpath://input[@id="culler-timeout-limited"]
    END
    Input Text  //input[@id="hour-input"]  ${hours}
    Input Text  //input[@id="minute-input"]  ${minutes}
    Sleep  0.5s
    ${changed_setting} =  Run Keyword And Return Status    Page Should Contain Element
    ...    xpath://button[.="Save changes"][@aria-disabled="false"]
    IF  ${changed_setting}==True
        Save Changes In Cluster Settings
    END

Disable Notebook Culler
    [Documentation]    Disables the culler (i.e. sets the default timeout of 1 year)
    Open Dashboard Cluster Settings
    Sleep  5
    ${disabled_field} =  Run Keyword And Return Status  Page Should Contain Element
    ...    xpath://input[@id="hour-input"][@disabled=""]
    IF  ${disabled_field}==False
        Click Element  xpath://input[@id="culler-timeout-unlimited"]
        Save Changes In Cluster Settings
    END
    Sleep  30s  msg=Give time for rollout

Teardown
    [Documentation]    Teardown for the test
    Disable Notebook Culler
    Launch JupyterHub Spawner From Dashboard
    End Web Test
