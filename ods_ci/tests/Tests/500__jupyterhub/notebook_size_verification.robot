*** Settings ***
Documentation       NOTEBOOK_SIZE_VERIFICATION
...                 Verify spawned notebook server and it's respective pod
...                 has the correct resource CPU and memory requests/limits
...
...                 = Variables =
...                 | Namespace       | Required |    RHODS Namespace/Project for notebook POD |
...                 | Notebook size   | Required |    List of container size present on JH page|
...                 | Default size    | Required |    Default container size for Default notebook size|
...                 | Custome size    | Required |    Custome conatiner size for Default notebook size|

Library             OperatingSystem
Library             Collections
Library             Process
Library             SeleniumLibrary
Resource            ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../Resources/RHOSi.resource

Test Setup          Dashboard Test Setup
Test Teardown       Dashboard Test Teardown
Force Tags          JupyterHub


*** Variables ***
${NAMESPACE}        ${NOTEBOOKS_NAMESPACE}
@{NOTEBOOK_SIZE}    Small    Medium
${DEFAULT_SIZE}     {"limits":{"cpu":"2","memory":"8gi"},"requests":{"cpu":"1","memory":"8gi"}}
${CUSTOME_SIZE}     {"limits":{"cpu":"6","memory":"9gi"},"requests":{"cpu":"2","memory":"6gi"}}


*** Test Cases ***
Verify Spawned Notebook Size
    [Documentation]    Check the available container size spec
    ...    with actual assign to spawned notebook pod
    [Tags]    Tier2
    ...       Execution-Time-Over-15m
    ...       FlakyTest
    ...       ODS-1072
    Launch JupyterHub Spawner From Dashboard
    Spawn Notebook And Verify Size

# I think this TC is not valid anymore
# Verify Custom Spwaned Notebook Size
#     [Documentation]    Modify and verify the default notebook conatiner size spec
#     ...    with spwaned notebook pod and set back to default size
#     [Tags]    Sanity    ODS-318
#     ...       ODS-1071
#     Launch JupyterHub Spawner From Dashboard
#     Modify Default Container Size
#     Sleep    60s    msg=Wait for the size to get reflect
#     ${d_container_size}    Create List    Small
#     Spawn Notebook And Verify Size    size=${CUSTOME_SIZE}    NOTEBOOK_SIZE=${d_container_size}
#     Restore Default Container Size


*** Keywords ***
Dashboard Test Setup
    [Documentation]    Open browser and load RHODS dashboard
    Set Library Search Order    SeleniumLibrary
    #RHOSi Setup
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load

Dashboard Test Teardown
    [Documentation]    Close all the open browser
    Run Keyword And Ignore Error    Click Button    Close
    Close All Browsers

Spawn Notebook And Verify Size
    [Documentation]    Capture and compare CPU/memory resource
    ...    between JH and notebook pod
    [Arguments]    ${size}=${DEFAULT_SIZE}    ${NOTEBOOK_SIZE}=${NOTEBOOK_SIZE}
    FOR    ${container_size}    IN    @{NOTEBOOK_SIZE}
        Reload Page
        ${jh_container_size}    Get Container Size    ${container_size}
        Spawn Notebook With Arguments    image=minimal-gpu    size=${container_size}
        ${notebook_pod_name}    Get User Notebook Pod Name    ${TEST_USER.USERNAME}
        ${status}    Run
        ...    oc get pods -n ${NAMESPACE} ${notebook_pod_name} -o jsonpath='{.spec.containers[0].resources}'
        ${data}    Convert To Lower Case    ${status}
        ${dict_pod_data}    Evaluate    json.loads('''${data}''')    json
        IF    &{dict_pod_data} != &{jh_container_size}    Run Keyword And Continue On Failure
        ...    Fail    Container size didn't match.
        ...    Pod container size '${dict_pod_data}' and JH conaintainer is '${jh_container_size}'
        Fix Spawner Status
    END

Modify Default Container Size
    [Documentation]    Modify the default container size using oc command
    ${output}    Run Process    sh ${CURDIR}/odh_jh_global_profile.sh modify    shell=yes
    Should Not Contain    ${output.stdout}    FAIL

Restore Default Container Size
    [Documentation]    Restore default container size using oc command
    ${output}    Run Process    sh ${CURDIR}/odh_jh_global_profile.sh default    shell=yes
    Should Not Contain    ${output.stdout}    FAIL
