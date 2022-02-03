*** Settings ***
Documentation   NOTEBOOK_SIZE_VERIFICATION
...             Verify spawned server pod has the correct resource requests/limits
...
...             = Variables =
...             | Namespace                     | Required |        RHODS Namespace/Project for RHODS operator POD |
...             | Notebook size                 | Required |        List of container size present on JH page|
Library         SeleniumLibrary
Library         OperatingSystem
Library         Collections
Resource        ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown

*** Variables ***
${namespace}           rhods-notebooks
@{notebook_size}            Small   Medium

*** Test Cases ***
Verify Spwaned Notebook Size
    [Tags]  Sanity   ODS-1072
     Launch JupyterHub Spawner From Dashboard
     Spawan Notebook And Verify Size

*** Keywords ***
Dashboard Test Setup
    Set Library Search Order  SeleniumLibrary
    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load

Dashboard Test Teardown
    Close All Browsers

Spawan Notebook And Verify Size

    FOR    ${container_size}   IN   @{notebook_size}
           ${jh_container_size}      Get Container Size    ${container_size}
           Spawn Notebook With Arguments    size=${container_size}
           ${notebook_pod_name}         Get User Notebook Pod Name         ${TEST_USER.USERNAME}
           ${status}       Run   oc get pods -n ${namespace} ${notebook_pod_name} -o jsonpath='{.spec.containers[0].resources}'
           ${data}   Convert To Lower Case   ${status}
           ${dict_pod_data}     Evaluate    json.loads('''${data}''')    json
           Run Keyword And Continue On Failure   Run Keyword If   &{dict_pod_data} != &{jh_container_size}   Fail   Container size didn't match.
           ...  Pod container size '${dict_pod_data}' and JH conaintainer is '${jh_container_size}'
           Fix Spawner Status
    END


