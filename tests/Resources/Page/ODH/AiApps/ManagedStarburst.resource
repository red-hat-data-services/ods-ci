*** Settings ***
Documentation    Collections of keywords to interact with Managed Starburst
Library    OperatingSystem
Library    OpenShiftLibrary
Library    SeleniumLibrary


*** Variables ***
${STARBURST_CR_DEFAULT_NAMESPACE}=    redhat-starburst-operator
${USERNAME_XP}=    xpath=//input[@id="username"]
${STARBURST_ROUTE}=    web-ui


*** Keywords ***
Create Starburst Route
    [Documentation]    Exposes starburst service for external connections
    [Arguments]    ${name}
    ${rc}=    Run And Return Rc    oc expose svc starburst --name ${name} -n ${STARBURST_CR_DEFAULT_NAMESPACE}
    # ${rc}=    Run And Return Rc    oc create route edge ${name} --service=starburst --insecure-policy="Redirect" -n ${STARBURST_CR_DEFAULT_NAMESPACE}    # robocop: disable
    ${route}=    Get Starburst Route
    [Return]    ${rc}    ${route}

Get Starburst Route
    [Documentation]    Gets the starburst route
    [Arguments]    ${name}=${STARBURST_ROUTE}
    ${route}=    Oc Get    kind=Route  name=${name}  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  fields=['spec.host']
    [Return]    ${route[0]['spec.host']}

Create Starburst Route If Not Exists
    [Documentation]    Exposes starburst service for external connections
    ...                if not done
    [Arguments]    ${name}
    ${found}=    Run Keyword And Return Status    Get Starburst Route
    IF    ${found} == ${FALSE}
        ${rc}  ${host}=    Create Starburst Route    name=${name}
    ELSE
        Log    message=Route ${name} already present under ${STARBURST_CR_DEFAULT_NAMESPACE} namespace
        ${host}=    Get Starburst Route
    END
    [Return]    ${host}

Perform Log In
    [Documentation]    Performs Log In of Trino/Starburst Dashboard
    [Arguments]    ${username}
    ${is_login_required}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element   xpath=//form[@id="login"]
    IF    ${is_login_required} == ${TRUE}
        # Wait Until Page Contains Element    ${USERNAME_XP}
        Input Text    ${USERNAME_XP}    ${username}
        Click Button   Log In
    ELSE
        Log    message=Log In page didn't appear.     level=WARN
    END

Open Trino Web UI
    [Documentation]    Launches Trino Web UI
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${url}=    Get Starburst Route
    END
    Open Browser      url=http://${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}
    Wait Until Page Contains     Cluster Overview

Check Trino Web UI Is Loaded
    [Documentation]    Checks Trino Web UI is rendered
    Page Should Contain     Active workers
    Page Should Contain     Query Details
    Page Should Contain Element     xpath=//a[text()="Log Out"]

Open Managed Staburst Web UI
    [Documentation]    Launches Starburst Web UI
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${trino_url}=    Get Starburst Route
        ${url}=     Set Variable    ${trino_url}/ui/insights
    END
    Open Browser      url=http://${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}
    Wait Until Page Contains     Cluster overview

Check Worksheet Tool Is Accessible
    [Documentation]    Check "Worksheet" tool inside Starburst UI is accessible
    ...                and able to reach test data sources
    Click Element    xpath=//div[text()="Worksheet"]
    Wait Until Page Contains Element    xpath=//div[text()="loading"]
    Wait Until Page Does Not Contain Element    xpath=//div[text()="loading"]   timeout=15s
    Wait Until Page Contains Element     xpath=//span[text()="system"]
    Wait Until Page Contains Element     xpath=//span[text()="tpch"]

Check Managed Starburst Web UI Is Loaded
    [Documentation]    Checks Starburst Web UI is rendered
    Page Should Contain     Overview
    Page Should Contain     CPU usage
    Page Should Contain     Workers
    Page Should Contain     Query history
    Page Should Contain     Cluster history
    Page Should Contain     Insights
    Page Should Contain     Worksheet
    Page Should Contain     Documentation
    Page Should Contain     Web UI
    Wait Until Page Contains Element    xpath=//canvas[@class="chartjs-render-monitor"]
    