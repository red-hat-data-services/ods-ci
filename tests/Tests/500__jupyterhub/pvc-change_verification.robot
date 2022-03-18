*** Settings ***
Documentation    PVC_CHANGE_VERIFICATION
...                 Verify  if we can modify default PVC size
...
...
...                 = Variables =
...                 | Namespace | Required |    Jupyterhub configuration namespace|
...                 | S_size    | Required |    Supported size |
...                 | Ns_size   | Required  |   Not Supported PVC size |
...                 | Size_code | Required |    Python code to check size in notebook |
#
Library         SeleniumLibrary
Library         JupyterLibrary
Resource         ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Suite Teardown  PVC Size Suite Teadrown
Test Setup      PVC Size Test Setup

*** Variables ***
${NAMESPACE}    redhat-ods-applications
${S_SIZE}       4
${SIZE_CODE}    import subprocess;
...    int(subprocess.check_output(['df','-h', '/opt/app-root/src']).split()[8].decode('utf-8')[:-1])
@{NS_SIZE}      0    -15    abc    6.2


*** Test Cases ***
Verify Supported Notebook PVC Size Using Backend
    [Documentation]   Verify if user can spawn notebook
    ...    for supported PVC size got changed
    [Tags]    Smoke
    ...       Sanity
    ...       ODS-1228    ODS-1221
    Change And Apply PVC size    ${S_SIZE}Gi
    Run Keyword And Warn On Failure   Verify Notebook Size     600s    ${S_SIZE}
    ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=rhods-notebooks
    Verify PVC Size     ${S_SIZE}       ${pvc_size}
    [Teardown]    PVC Size Test Teardown

Verify Unsupported Notebook PVC Size Using Backend
    [Documentation]   Verify if user should not able to
    ...    spawn notebook for supported PVC change
    [Tags]    Tier2
    ...       ODS-1229    ODS-1233
    Verify Multiple Unsupported Size    ${NS_SIZE}
    [Teardown]    PVC Size Test Teardown

Verify Supported Notebook PVC Size Using UI
   [Documentation]   Verify if dedicated admin user able to chnage PVC
    ...    and RHODS user is able to spawn notebook for supported PVC
    ...    change using UI
    [Tags]    Smoke
    ...       Sanity
    ...       ODS-1220    ODS-1222
    Add User To Dedicated Admin Group
    Launch RHODS Dashboard
    Set PVC Value In RHODS Dashboard    ${S_SIZE}
    Sleep    60
    Run Keyword And Warn On Failure   Verify Notebook Size     600s    ${S_SIZE}
    ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=rhods-notebooks
    Verify PVC Size     ${S_SIZE}       ${pvc_size}
    [Teardown]    PVC Size UI Test Teardown

*** Keywords ***
Launch RHODS Dashboard
    [Documentation]    Launch RHODS Dashboard
    Set Library Search Order  SeleniumLibrary
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load

Verify Multiple Unsupported Size
    [Documentation]   Verify Mulitple unsupported size
    [Arguments]      ${NS_SIZES}
    FOR    ${NS_SIZE}    IN    @{NS_SIZES}
       Change And Apply PVC size     ${NS_SIZE}Gi
       ${status}     Run Keyword And Return Status   Verify Notebook Size   60s   ${NS_SIZE}
       Run Keyword And Continue On Failure    Page Should Contain    Server request failed to start
       Run Keyword IF    '${status}'=='FAIL'   Log   Unable to Spawn Notebook
       ...   for unsupported values
    END

Change And Apply PVC size
    [Documentation]    Make PVC change to configmap
    ...    and rollout deployment config
    [Arguments]     ${size}
    Check If PVC Change Is Permanent    ${size}
    Roll Out Jupyter Deployment Config
    Launch RHODS Dashboard

PVC Size Suite Teadrown
    [Documentation]   PVC size suite teardown
    ${status}    ${pvc_name}    Run Keyword And Ignore Error
    ...     Get User Notebook PVC Name    ${TEST_USER.USERNAME}
    May Be Delete PVC     ${pvc_name}
    ${pod_name}    Get User Notebook Pod Name     ${TEST_USER.USERNAME}
    May Be Delete Notebook POD    rhods-notebooks    ${pod_name}
