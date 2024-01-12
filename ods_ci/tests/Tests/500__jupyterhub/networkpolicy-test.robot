*** Settings ***
Documentation    Test for the new Notebook network policies
Resource         ../../Resources/ODS.robot
Resource         ../../Resources/Common.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource         ../../Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource         ../../Resources/Page/ODH/JupyterHub/GPU.resource
Library          JupyterLibrary
Suite Setup      RHOSi Setup
Suite Teardown   Network Policy Suite Teardown
Force Tags       JupyterHub


*** Test Cases ***
Test Network Policy Effect
    [Documentation]    Spawns two Notebooks with two different users and verifies
    ...    That the new network policies prevent user2 from accessing user1's workspace
    [Tags]  Sanity    Tier1
    ...     ODS-2046
    Open Browser And Start Notebook As First User
    Open Browser And Start Notebook As Second User With Env Vars
    Clone Git Repository And Run    https://github.com/redhat-rhods-qe/ods-ci-notebooks-main    ods-ci-notebooks-main/notebooks/500__jupyterhub/api/notebook_access.ipynb
    Sleep  1
    JupyterLab Code Cell Error Output Should Not Be Visible
    Run Keyword And Continue On Failure    Run Additional Notebook Cells
    End Web Test    username=${TEST_USER_2.USERNAME}
    Switch Browser    ${first_browser_id}
    End Web Test    username=${TEST_USER.USERNAME}


*** Keywords ***
Open Browser And Start Notebook As First User
    [Documentation]    Opens a Notebook, forcing the creation of the NetworkPolicies
    ...                and leaves it running
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize Jupyterhub Service Account
    Wait Until Page Contains    Start a notebook server
    Fix Spawner Status
    Spawn Notebook With Arguments    image=minimal-notebook
    @{old_browser} =    Get Browser Ids
    ${first_browser_id} =    Set Variable    ${old_browser}[0]
    Set Suite Variable    ${first_browser_id}
    ${pod_name} =    Get User Notebook Pod Name    ${TEST_USER.USERNAME}
    ${pod_ip} =    Run    oc get pod ${pod_name} -o jsonpath='{.status.podIP}' -n ${NOTEBOOKS_NAMESPACE}
    Set Suite Variable    ${pod_ip}
    ${pod_login_name} =    Get User CR Notebook Name    ${TEST_USER.USERNAME}
    Set Suite Variable    ${pod_login_name}

Open Browser And Start Notebook As Second User With Env Vars
    [Documentation]    Opens a second Notebook, with pod details of the first notebook
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER_2.USERNAME}    ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER_2.USERNAME}    ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize Jupyterhub Service Account
    Wait Until Page Contains    Start a notebook server
    Fix Spawner Status
    &{first_pod_details} =  Create Dictionary  pod_ip=${pod_ip}  pod_login=${pod_login_name}
    Spawn Notebook With Arguments    image=minimal-notebook    username=${TEST_USER_2.USERNAME}
    ...    password=${TEST_USER_2.PASSWORD}    auth_type=${TEST_USER_2.AUTH_TYPE}    envs=&{first_pod_details}

Run Additional Notebook Cells
    [Documentation]    Finalize attack notebook cells
    ${pod_name_user2} =    Get User Notebook Pod Name    ${TEST_USER_2.USERNAME}
    ${pod_ip_user2} =    Run    oc get pod ${pod_name_user2} -o jsonpath='{.status.podIP}' -n ${NOTEBOOKS_NAMESPACE}
    ${tmp} =    Run Cell And Get Output    my_pod_ip='${pod_ip_user2}'
    ${tmp2} =    Run Cell And Get Output    server_ips = scan_pods()
    ${out1} =    Run Cell And Get Output    check_jupyter_logins(server_ips)
    Should Be Equal    ${out1}    No Jupyter pods found
    ${out2} =    Run Cell And Get Output    print_tree_view('/')
    Should Be Equal    ${out2}    Server did not respond after 10 seconds, assuming connection is blocked

Network Policy Suite Teardown
    [Documentation]    Suite teardown to close remaining notebook servers and running
    ...                RHOSi teardown
    End Web Test
    RHOSi Teardown
