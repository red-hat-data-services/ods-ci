*** Settings ***
Library   SeleniumLibrary
Library   JupyterLibrary
Library   OperatingSystem
Library   RequestsLibrary
Library   ../../libs/Helpers.py
Resource  Page/ODH/JupyterHub/JupyterLabLauncher.robot
Resource  Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource  RHOSi.resource


*** Keywords ***
Begin Web Test
    [Documentation]  This keyword should be used as a Suite Setup; it will log in to the
    ...              ODH dashboard, checking that the spawner is in a ready state before
    ...              handing control over to the test suites.

    Set Library Search Order  SeleniumLibrary
    RHOSi Setup


    Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    ${version-check}=  Is RHODS Version Greater Or Equal Than  1.4.0
    IF  ${version-check}==True
      Launch JupyterHub From RHODS Dashboard Link
    ELSE
      Launch JupyterHub From RHODS Dashboard Dropdown
    END
    Login To Jupyterhub  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Fix Spawner Status
    Go To  ${ODH_DASHBOARD_URL}

End Web Test
    ${server}=  Run Keyword and Return Status  Page Should Contain Element  //div[@id='jp-top-panel']//div[contains(@class, 'p-MenuBar-itemLabel')][text() = 'File']
    IF  ${server}==True
        Clean Up Server
        Stop JupyterLab Notebook Server
        Capture Page Screenshot
    END
    Close Browser

Load Json File
    [Arguments]   ${file_path}
    ${j_file}=    Get File    ${file_path}
    ${obj}=    Evaluate    json.loads('''${j_file}''')    json
    [Return]    ${obj}

Get CSS Property Value
    [Documentation]    Get the CSS property value of a given element
    [Arguments]    ${locator}    ${property_name}
    ${element}=       Get WebElement    ${locator}
    ${css_prop}=    Call Method       ${element}    value_of_css_property    ${property_name}
    [Return]     ${css_prop}

CSS Property Value Should Be
    [Documentation]     Compare the actual CSS property value with the expected one
    [Arguments]   ${locator}    ${property}    ${exp_value}   ${operation}=equal
    ${el_text}=   Get Text   xpath:${locator}
    Log    Text of the target element: ${el_text}
    ${actual_value}=    Get CSS Property Value   xpath:${locator}    ${property}
    IF    $operation == "contains"
        Run Keyword And Continue On Failure   Should Contain    ${actual_value}    ${exp_value}
    ELSE
        Run Keyword And Continue On Failure   Should Be Equal    ${actual_value}    ${exp_value}
    END

Get Cluster ID
    [Documentation]     Retrieves the ID of the currently connected cluster
    ${cluster_id}=   Run    oc get clusterversion -o json | jq .items[].spec.clusterID
    IF    not $cluster_id
        Fail    Unable to retrieve cluster ID. Are you logged using `oc login` command?
    END
    [Return]    ${cluster_id}

Get Cluster Name By Cluster ID
    [Documentation]     Retrieves the name of the currently connected cluster given its ID
    [Arguments]     ${cluster_id}
    ${cluster_name}=    Get Cluster Name     cluster_identifier=${cluster_id}
    IF    not $cluster_name
        Fail    Unable to retrieve cluster name for cluster ID ${cluster_id}
    END
    [Return]    ${cluster_name}

Wait Until HTTP Status Code Is
    [Documentation]     Waits Until Status Code Of URl Matches expected Status Code
    [Arguments]  ${url}   ${expected_status_code}=200  ${retry}=1m   ${retry_interval}=15s
    Wait Until Keyword Succeeds    ${retry}   ${retry_interval}
    ...    Check HTTP Status Code    ${url}    ${expected_status_code}

Check HTTP Status Code
    [Documentation]     Verifies Status Code of URL Matches Expected Status Code
    [Arguments]  ${link_to_check}  ${expected}=200
    ${response}=    RequestsLibrary.GET  ${link_to_check}   expected_status=any
    Run Keyword And Continue On Failure  Status Should Be  ${expected}
    [Return]  ${response.status_code}

Verify NPM Version
    [Documentation]  Verifies the installed version of an NPM library
    ...    against an expected version in a given pod/container
    [Arguments]  ${library}  ${expected_version}  ${pod}  ${namespace}  ${container}=""
    ${installed_version} =  Run  oc exec -n ${namespace} ${pod} -c ${container} -- npm list --depth=0 | awk -F@ '/${library}/ { print $2}'
    Should Be Equal  ${installed_version}  ${expected_version}