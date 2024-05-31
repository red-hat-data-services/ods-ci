*** Settings ***
Documentation       Test Suite for Upgrade testing,to be run during the upgrade
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Common.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource            ../../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Library             DebugLibrary
Library             JupyterLibrary


*** Variables ***
${CODE}         while True: import time ; time.sleep(10); print ("Hello")


*** Test Cases ***
Long Running Jupyter Notebook
    [Documentation]    Launch a long running notebook before the upgrade
    [Tags]  Upgrade
    Launch Notebook
    Add And Run JupyterLab Code Cell In Active Notebook  ${CODE}
    ${return_code}    ${timestamp}    Run And Return Rc And Output   oc get pod -n ${NOTEBOOKS_NAMESPACE} jupyter-nb-ldap-2dadmin2-0 --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0
    Set Global Variable    ${timestamp}   #robocop: disable
    Close Browser

Upgrade RHODS
    [Documentation]    Approve the install plan for the upgrade and make sure that upgrade has completed
    [Tags]  ODS-1766
    ...     Upgrade
    ${initial_version} =  Get RHODS Version
    ${initial_creation_date} =  Get Operator Pod Creation Date
    ${return_code}    ${output}    Run And Return Rc And Output   oc patch installplan $(oc get installplans -n ${OPERATOR_NAMESPACE} | grep -v NAME | awk '{print $1}') -n ${OPERATOR_NAMESPACE} --type='json' -p '[{"op": "replace", "path": "/spec/approved", "value": true}]'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0   msg=Error while upgrading RHODS
    Sleep  30s      reason=wait for thirty seconds until old CSV is removed and new one is ready
    RHODS Version Should Be Greater Than    ${initial_version}
    Operator Pod Creation Date Should Be Updated    ${initial_creation_date}
    OpenShiftLibrary.Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=300

TensorFlow Image Test
    [Documentation]   Run basic tensorflow notebook during upgrade
    [Tags]  Upgrade
    Launch Notebook    tensorflow   ${TEST_USER.USERNAME}     ${TEST_USER.PASSWORD}   ${TEST_USER.AUTH_TYPE}
    [Teardown]   Upgrade Test Teardown

PyTorch Image Workload Test
    [Documentation]   Run basic pytorch notebook during upgrade
    [Tags]  Upgrade
    Launch Notebook    pytorch    ${TEST_USER.USERNAME}     ${TEST_USER.PASSWORD}   ${TEST_USER.AUTH_TYPE}
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    [Teardown]   Upgrade Test Teardown


*** Keywords ***
Launch Notebook
    [Documentation]  Launch notebook for the suite
    [Arguments]   ${notbook_image}=minimal-notebook   ${username}=${TEST_USER2.USERNAME}   ${password}=${TEST_USER2.PASSWORD}   ${auth_type}=${TEST_USER2.AUTH_TYPE}  #robocop: disable
    Begin Web Test     username=${username}  password=${password}  auth_type=${auth_type}
    Login To RHODS Dashboard    ${username}  ${password}   ${auth_type}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${username}  ${password}   ${auth_type}
    ${authorization_required}     Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize Jupyterhub Service Account
    Fix Spawner Status
    Spawn Notebook With Arguments   image=${notbook_image}    username=${username}  password=${password}  auth_type=${auth_type}   #robocop: disable

Upgrade Test Teardown
    End Web Test
    Skip If RHODS Is Self-Managed
    ${expression} =    Set Variable    rhods_aggregate_availability&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
     Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression} =    Set Variable     rhods_aggregate_availability{name="rhods-dashboard"}&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
    Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}
    ${expression} =    Set Variable     rhods_aggregate_availability{name="notebook-spawner"}&step=1
    ${resp} =    Prometheus.Run Query    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}    ${expression}
    Log    rhods_aggregate_availability: ${resp.json()["data"]["result"][0]["value"][-1]}
    @{list_values} =    Create List    1
    Run Keyword And Warn On Failure    Should Contain    ${list_values}    ${resp.json()["data"]["result"][0]["value"][-1]}

RHODS Version Should Be Greater Than
    [Documentation]    Checks if the RHODS version is greater than the given initial version.
    ...                Fails if the version is not greater.
    [Arguments]  ${initial_version}
    ${ver} =  Get RHODS Version
    ${ver} =  Fetch From Left  ${ver}  -
    Should Be True    '${ver}' > '${initial_version}'    msg=RHODS version was not greater than initial version ${initial_version}

Get Operator Pod Creation Date
    [Documentation]    Retrieves the creation date of the RHODS operator pod.
    ...                Returns the creation date as a string.
    ...                Fails if the command to retrieve the creation date fails.
    ${return_code}    ${creation_date}    Run And Return Rc And Output    oc get pod -n ${OPERATOR_NAMESPACE} -l name=rhods-operator --no-headers -o jsonpath='{.items[0].metadata.creationTimestamp}'
    Should Be Equal As Integers    ${return_code}     0   msg=Error while getting creation date of the operator pod
    [Return]    ${creation_date}

Operator Pod Creation Date Should Be Updated
    [Documentation]    Checks if the operator pod creation date has been updated after the upgrade.
    ...                Fails if the updated creation date is not more recent than the initial creation date.
    [Arguments]  ${initial_creation_date}
    ${updated_creation_date} =  Get Operator Pod Creation Date
    Should Be True    '${updated_creation_date}' > '${initial_creation_date}'    msg=Operator pod creation date was not updated after upgrade
