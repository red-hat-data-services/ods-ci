*** Settings ***
Resource    ../../Resources/ODS.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LaunchJupyterHub.robot
Resource    ../../Resources/Page/ODH/JupyterHub/LoginJupyterHub.robot
Resource    ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot
Resource    ../../Resources/Page/OCPDashboard/OCPMenu.robot
Library     SeleniumLibrary
Test Setup    Test Suite For Web

*** Test Cases ***
Verify Telemetry Data Is Accessible
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-347
    Usage Data Collection Should Be Enabled
    Load JupyterHub API Page
    JupyterHub API Should Exposes SegmentKey
    Switch To RHODS Dashboard
    Navigate To Cluster Settings Page
    Disable "Usage Data Collection"
    Switch To JupyterHub API Tab
    Reload Page
    JupyterHub API Should Not Exposes SegmentKey
    [Teardown]    Teardown For Checks SegmentKey Is Exposes In Jupyterhub API TestCase

*** Keywords ***
Test Suite For Web
    Set Library Search Order  SeleniumLibrary

Navigate To Cluster Settings Page
    [Documentation]     Navigate to Cluste Settings page
    Menu.Navigate To Page    Settings    Cluster settings
    Wait Until Page Contains    Usage Data Collection

Teardown For Checks SegmentKey Is Exposes In Jupyterhub API TestCase
    [Documentation]     Enables ussage data collection and close the browser
    Switch To RHODS Dashboard
    Wait Until Page Contains    Usage Data Collection
    Enable "Usage Data Collection"
    Usage Data Collection Should Be Enabled
    Close Browser

Load JupyterHub API Page
    [Documentation]     Loads Jupyterhub and navigate to API url
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait for RHODS Dashboard to Load
    Launch JupyterHub Spawner From Dashboard
    ${url} =    Get Location
    Log    ${url}
    ${url} =    Replace String    ${url}    /hub/spawn    /services/jsp-api/api/instance
    Go To    ${url}
    sleep  0.5s

Is SegmentKey Exposed In JupyterHub API
    [Documentation]     checks segmentkey is present in json, if present return true otherwise false
    @{data} =    Get WebElements    //pre
    &{data} =    Evaluate    dict(${data[0].text})
    @{keys} =    Get Dictionary Keys    ${data["segment_key"]}
    ${return_value} =    Evaluate    'segmentKey' in ${keys}
    [Return]    ${return_value}

JupyterHub API Should Not Exposes SegmentKey
    [Documentation]     Checks API is not exposing segmentkey
    ${boolean} =    Is SegmentKey Exposed In JupyterHub API
    Should Not Be True    ${boolean}

JupyterHub API Should Exposes SegmentKey
    [Documentation]     Check API is exposing segmentkey
    ${boolean} =    Is SegmentKey Exposed In JupyterHub API
    Should Be True    ${boolean}

Switch To RHODS Dashboard
    [Documentation]     Switch tab to RHODS dashboard
    Switch Window    title=Red Hat OpenShift Data Science
    Sleep    1s    msg=Wait for to change tab

Switch To JupyterHub API Tab
    [Documentation]     Switch tab to jupyterhub API Tab
    ${handle} =    Get Window Handles
    Switch Window    ${handle}[1]
