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
    Add And Run JupyterLab Code Cell in Active Notebook  ${CODE}
    ${return_code}    ${timestamp}    Run And Return Rc And Output   oc get pod -n rhods-notebooks jupyter-nb-ldap-2dadmin2-0 --no-headers --output='custom-columns=TIMESTAMP:.metadata.creationTimestamp'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0
    Set Global Variable    ${timestamp}   #robocop: disable
    Close Browser

Upgrade RHODS
    [Documentation]    Appprove the install plan for the upgrade
    [Tags]  ODS-1766
    ...     Upgrade
    ${return_code}    ${output}    Run And Return Rc And Output   oc patch installplan $(oc get installplans -n redhat-ods-operator | grep -v NAME | awk '{print $1}') -n redhat-ods-operator --type='json' -p '[{"op": "replace", "path": "/spec/approved", "value": true}]'   #robocop:disable
    Should Be Equal As Integers    ${return_code}     0   msg=Error while upgradeing RHODS
    Sleep  10s      reason=wait for ten second until operator goes into init state
    ${return_code}    ${output}    Run And Return Rc And Output   oc get pod -n redhat-ods-operator -l name=rhods-operator --no-headers --output='custom-columns=STATUS:.status.phase'    #robocop:disable
    Should Contain    ${output}    Pending
    OpenShiftLibrary.Wait For Pods Status  namespace=redhat-ods-operator  timeout=300
    [Teardown]   End Web Test

TensorFlow Image Test
    [Documentation]   Run basic tensorflow notebook during upgrade
    [Tags]  Upgrade
    Launch Notebook    tensorflow   ${TEST_USER.USERNAME}     ${TEST_USER.PASSWORD}   ${TEST_USER.AUTH_TYPE}
    [Teardown]   End Web Test

PyTorch Image Workload Test
    [Documentation]   Run basic pytorch notebook during upgrade
    [Tags]  Upgrade
    Launch Notebook    pytorch    ${TEST_USER.USERNAME}     ${TEST_USER.PASSWORD}   ${TEST_USER.AUTH_TYPE}
    Run Repo And Clean  https://github.com/lugi0/notebook-benchmarks  notebook-benchmarks/pytorch/PyTorch-MNIST-Minimal.ipynb
    Capture Page Screenshot
    JupyterLab Code Cell Error Output Should Not Be Visible
    [Teardown]   End Web Test


*** Keywords ***
Dashboard Suite Setup
    [Documentation]  Basic suite setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Dashboard Test Teardown
    [Documentation]  Basic suite teardown
    Close All Browsers

Launch Notebook
    [Documentation]  Launch notebook for the suite
    [Arguments]   ${notbook_image}=s2i-minimal-notebook   ${username}=${TEST_USER2.USERNAME}   ${password}=${TEST_USER2.PASSWORD}   ${auth_type}=${TEST_USER2.AUTH_TYPE}  #robocop: disable
    Begin Web Test     username=${username}  password=${password}  auth_type=${auth_type}
    Login To RHODS Dashboard    ${username}  ${password}   ${auth_type}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${username}  ${password}   ${auth_type}
    ${authorization_required}     Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize Jupyterhub Service Account
    Fix Spawner Status
    Spawn Notebook With Arguments   image=${notbook_image}    username=${username}  password=${password}  auth_type=${auth_type}   #robocop: disable
