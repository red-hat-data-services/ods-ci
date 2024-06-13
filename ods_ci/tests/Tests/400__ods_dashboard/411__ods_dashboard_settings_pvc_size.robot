*** Settings ***
Documentation       PVC_CHANGE_VERIFICATION
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
Resource        ../../Resources/RHOSi.resource
Resource        ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Resource        ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Suite Setup     RHOSi Setup
Suite Teardown  PVC Size Suite Teadrown
Test Setup      PVC Size Test Setup
Test Tags       Dashboard


*** Variables ***
${NAMESPACE}    ${APPLICATIONS_NAMESPACE}
${S_SIZE}       15
${SIZE_CODE}    import subprocess;
...    int(subprocess.check_output(['df','-h', '/opt/app-root/src']).split()[8].decode('utf-8')[:-1])
@{NS_SIZE}      0    6.5   -1


*** Test Cases ***
Verify User Can Spawn Notebook After Changing PVC Size Using Backend
    [Documentation]   Verify if user can spawn notebook
    ...    for supported PVC size got changed
    [Tags]    Tier2
    ...       ODS-1221
    ...       FlakyTest
    Change And Apply PVC size    ${S_SIZE}Gi
    Run Keyword And Warn On Failure   Verify Notebook Size     600s    ${S_SIZE}
    ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=${NOTEBOOKS_NAMESPACE}
    Verify PVC Size     ${S_SIZE}       ${pvc_size}
    [Teardown]    PVC Size Test Teardown

Verify User Cannot Set An Unsupported PVC Size Using Backend
    [Documentation]   Verify if user should not able to
    ...    spawn notebook for supported PVC change
    ...    ProductBug:RHODS-3258
    [Tags]    Tier2
    ...       ODS-1229
    ...       ProductBug
    Verify Multiple Unsupported Size    ${NS_SIZE}
    [Teardown]    PVC Size Test Teardown

Verify User Can Spawn Notebook After Changing PVC Size Using UI
    [Documentation]   Verify if dedicated admin user able to chnage PVC
    ...    and RHODS user is able to spawn notebook for supported PVC
    ...    and verify PVC size
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1220    ODS-1222
    Verify PVC change using UI     ${S_SIZE}
    ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=${NOTEBOOKS_NAMESPACE}
    Verify PVC Size     ${S_SIZE}       ${pvc_size}
    PVC Size Suite Teadrown
    [Teardown]    PVC Size UI Test Teardown     True

Verify User Cannot Set An Unsupported PVC Size Using The UI
        [Documentation]   Verify if dedicated admin user able to chnage PVC
    ...    and RHODS user is able to spawn notebook for unsupported PVC
    ...    and verify PVC size
    [Tags]    Tier2
    ...       ODS-1223
    FOR    ${size}    IN    @{NS_SIZE}
         Verify PVC change using UI   ${size}
         ${pvc_size}   Get Notebook PVC Size        username=${TEST_USER.USERNAME}   namespace=${NOTEBOOKS_NAMESPACE}
         ${status}    Run Keyword And Return Status    Verify PVC Size     ${size}       ${pvc_size}
         IF   '${status}' != 'True'
               Log     Actul size and assigned size is mismatch
         ELSE
               Log     User is able to spawn and set the Unsupported size
               Run Keyword And Continue On Failure    Fail
         END
         PVC Size Suite Teadrown
    END
    [Teardown]    PVC Size UI Test Teardown

*** Keywords ***
Launch RHODS Dashboard
    [Documentation]    Launch RHODS Dashboard
    Set Library Search Order  SeleniumLibrary
    Launch Dashboard   ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ...   ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}

Verify Multiple Unsupported Size
    [Documentation]   Verify Mulitple unsupported size
    [Arguments]      ${NS_SIZES}
    FOR    ${NS_SIZE}    IN    @{NS_SIZES}
       Change And Apply PVC size     ${NS_SIZE}Gi
       ${status}     Run Keyword And Return Status   Verify Notebook Size   60s   ${NS_SIZE}
       Run Keyword And Continue On Failure    Page Should Contain    Server request failed to start
       IF    '${status}'=='FAIL'   Log   Unable to Spawn Notebook
       ...   for unsupported values
    END

Change And Apply PVC size
    [Documentation]    Make PVC change to OdhDashboardConfig CR
    ...    and restart the Notebook controller POD
    [Arguments]     ${size}
    Check If PVC Change Is Permanent    ${size}
    Sleep    20
    Launch RHODS Dashboard

PVC Size Suite Teadrown
    [Documentation]   PVC size suite teardown
    ${pod_name}    Get User Notebook Pod Name     ${TEST_USER.USERNAME}
    May Be Delete Notebook POD    ${NOTEBOOKS_NAMESPACE}    ${pod_name}
    ${status}    ${pvc_name}    Run Keyword And Ignore Error
    ...     Get User Notebook PVC Name    ${TEST_USER.USERNAME}
    May Be Delete PVC     ${pvc_name}
    RHOSi Teardown

Verify PVC change using UI
   [Documentation]   Basic PVC change verification
    [Arguments]     ${S_SIZE}
    Add User To Dedicated Admin Group
    Launch RHODS Dashboard
    Set PVC Value In RHODS Dashboard    ${S_SIZE}
    Sleep    60
    Run Keyword And Warn On Failure   Verify Notebook Size     600s    ${S_SIZE}
