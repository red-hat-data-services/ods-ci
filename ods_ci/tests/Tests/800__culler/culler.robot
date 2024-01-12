*** Settings ***
Documentation    Tests for the NB culler
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Library          ../../../libs/Helpers.py
Library          OpenShiftLibrary
Suite Setup      Set Library Search Order    SeleniumLibrary
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
    ...    OpenShiftLibrary.Oc Get  kind=ConfigMap  name=notebook-controller-culler-config    namespace=${APPLICATIONS_NAMESPACE}
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
    Spawn Server And Run Notebook Which Will Not Keep Server Active
    Wait Until Culler Timeout
    Verify That Inactive Server Has Been Culled Within A Specific Window Of Time

Verify Culler Does Not Kill Active Server
    [Documentation]    Verifies that the culler does not kill an active
    ...    server even after timeout has passed.
    [Tags]    Tier2
    ...       ODS-1253
    ...       Execution-Time-Over-15m
    Spawn Server And Run Notebook To Keep Server Active For More Than 10 Minutes
    Wait Until Culler Timeout Plus A Drift Window Which By Default Equals 12 Minutes
    Check If Server Pod Still Exists

Verify Do Not Stop Idle Notebooks
    [Documentation]    Disables the culler (default configuration) and verifies nb is not culled
    [Tags]    Tier2
    ...       ODS-1230
    ...       Execution-Time-Over-15m
    Disable Notebook Culler
    Close Browser
    Spawn Server And Run Notebook Which Will Not Keep Server Active
    Wait Until Culler Timeout Plus A Drift Window Which By Default Equals 12 Minutes
    Check If Server Pod Still Exists

Verify That "Stop Idle Notebook" Setting Is Not Overwritten After Restart Of Operator Pod
    [Documentation]    Restart the operator pod and verify if "Stop Idle Notebook" setting
    ...   is overwritten or not.
    ...   ProductBug:RHODS-4336
    [Tags]    Tier2
    ...       ODS-1607
    Modify Notebook Culler Timeout    ${CUSTOM_CULLER_TIMEOUT}
    Oc Delete    kind=Pod     namespace=${OPERATOR_NAMESPACE}    label_selector=name=rhods-operator
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
    Spawn Notebook With Arguments  image=minimal-notebook  size=Small

Get Notebook Culler Pod Name
    [Documentation]    Finds the current culler pod and returns the name
    ${culler_pod} =  OpenShiftLibrary.Oc Get  kind=Pod
    ...    label_selector=component.opendatahub.io/name=kf-notebook-controller  namespace=${APPLICATIONS_NAMESPACE}
    ${culler_pod_name} =  Set Variable  ${culler_pod[0]}[metadata][name]
    Log  ${culler_pod}
    Log  ${culler_pod_name}
    RETURN  ${culler_pod_name}

Get And Verify Notebook Culler Timeout
    [Documentation]    Gets the current culler timeout from configmap and culler pod, compares the two
    ...    And returns the value
    ${current_timeout} =  Get Notebook Culler Timeout From Configmap
    Log  ${current_timeout}
    ${culler_env_timeout} =  Get Notebook Culler Timeout From Culler Pod
    Log  ${culler_env_timeout}
    Should Be Equal  ${current_timeout}  ${culler_env_timeout}
    RETURN  ${current_timeout}

Get Notebook Culler Timeout From Configmap
    [Documentation]    Gets the current culler timeout from configmap
    ${current_timeout} =  OpenShiftLibrary.Oc Get  kind=ConfigMap  name=notebook-controller-culler-config
    ...    namespace=${APPLICATIONS_NAMESPACE}  fields=['data.CULL_IDLE_TIME']
    ${current_timeout} =  Set Variable  ${current_timeout[0]['data.CULL_IDLE_TIME']}
    RETURN  ${current_timeout}

Get Notebook Culler Timeout From Culler Pod
    [Documentation]    Gets the current culler timeout from culler pod
    ${CULLER_POD} =  Get Notebook Culler Pod Name
    ${culler_env_timeout} =  Run  oc exec ${CULLER_POD} -n ${APPLICATIONS_NAMESPACE} -- printenv CULL_IDLE_TIME  # robocop: disable
    RETURN  ${culler_env_timeout}

Teardown
    [Documentation]    Teardown for the test
    Disable Notebook Culler
    Launch JupyterHub Spawner From Dashboard
    End Web Test

Spawn Server And Run Notebook To Keep Server Active For More Than 10 Minutes
    [Documentation]    This keyword spawns a server, then clones a Git Repo and runs a notebook
    ...    which will keep the server's kernel active for ~15 minutes (enough time to be seen as active)
    ...    after the culler timeout, which is by default set at 10 minutes. It then closes the browser
    ...    to validate that kernel activity is seen also while no user is actively on the server page.
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

Wait Until Culler Timeout Plus A Drift Window Which By Default Equals 12 Minutes
    [Documentation]    This keyword will sleep for 12 minutes by default.
    ...    It is used to wait for the culler timeout (10 minutes by default)
    ...    plus a configurable drift window (120 seconds or 2 minutes by default).
    [Arguments]    ${drift}=120
    Sleep    ${${CUSTOM_CULLER_TIMEOUT}+${drift}}

Check If Server Pod Still Exists
    [Documentation]    This keyword simply looks for the server pod
    ...    in order to confirm that it still exists and wasn't deleted
    ...    by the notebook culler.
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    OpenShiftLibrary.Search Pods  ${notebook_pod_name}  namespace=${NOTEBOOKS_NAMESPACE}

Spawn Server And Run Notebook Which Will Not Keep Server Active
    [Documentation]    This keyword spawns a server, then clones a Git Repo and runs a notebook
    ...    which won't keep the server's kernel active. It then closes the browser.
    Spawn Minimal Image
    Clone Git Repository And Run    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/notebook-culler/Inactive.ipynb
    Open With JupyterLab Menu    File    Save Notebook
    Close Browser

Verify That Inactive Server Has Been Culled Within A Specific Window Of Time
    [Documentation]    This keyword checks that an inactive server gets culled
    ...    within an acceptable window of time. There are two arguments that can be set:
    ...    acceptable_drift: control the threshold after which the test fails, in seconds
    ...    loop_control: controls for how long the test should keep checking for the presence
    ...        inactive server. Integer that gets multiplied by 30s.
    [Arguments]    ${acceptable_drift}=120    ${loop_control}=20
    ${notebook_pod_name} =  Get User Notebook Pod Name  ${TEST_USER.USERNAME}
    ${culled} =  Set Variable  False
    ${drift} =  Set Variable  ${0}
    # Wait for maximum 10 minutes over timeout
    FOR  ${index}  IN RANGE  ${loop_control}
        ${culled} =  Run Keyword And Return Status  Run Keyword And Expect Error
        ...    Pods not found in search  OpenShiftLibrary.Search Pods
        ...    ${notebook_pod_name}  namespace=${NOTEBOOKS_NAMESPACE}
        Exit For Loop If  ${culled}==True
        Sleep  30s
        ${drift} =  Evaluate  ${drift}+${30}
    END
    IF  ${drift}>${acceptable_drift}
        Fail    Drift was over ${acceptable_drift} seconds, it was ${drift} seconds
    END

Wait Until Culler Timeout
    [Documentation]    Sleeps for the length of the culler's timeout
    Sleep    ${CUSTOM_CULLER_TIMEOUT}
