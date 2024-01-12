*** Settings ***
Documentation    Collections of keywords to interact with Managed Starburst
Resource   ../JupyterHub/JupyterLabLauncher.robot
Library    OperatingSystem
Library    OpenShiftLibrary
Library    SeleniumLibrary


*** Variables ***
${STARBURST_CR_DEFAULT_NAMESPACE}=    redhat-starburst-operator
${USERNAME_XP}=    xpath=//input[@name="username"]
${STARBURST_ROUTE}=    web-ui


*** Keywords ***
Create Starburst Route
    [Documentation]    Exposes starburst service for external connections
    [Arguments]    ${name}    ${namespace}=${STARBURST_CR_DEFAULT_NAMESPACE}
    ${rc}=    Run And Return Rc    oc expose svc starburst --name ${name} -n ${namespace}
    Should Be Equal As Integers    ${rc}    ${0}
    ${route}=    Get Starburst Route    name=${name}    namespace=${namespace}
    RETURN    ${rc}    ${route}

Get Starburst Route
    [Documentation]    Gets the starburst route
    [Arguments]    ${name}=${STARBURST_ROUTE}    ${namespace}=${STARBURST_CR_DEFAULT_NAMESPACE}
    ${route}=    Oc Get    kind=Route  name=${name}  namespace=${namespace}  fields=['spec.host']
    RETURN    ${route[0]['spec.host']}

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
    RETURN    ${host}

Perform Log In
    [Documentation]    Performs Log In of Trino/Starburst Dashboard
    [Arguments]    ${username}
    ${is_login_required}=    Run Keyword And Return Status
    ...    Wait Until Page Contains Element   xpath=//h3[text()="Sign in to your account"]
    IF    ${is_login_required} == ${TRUE}
        Wait Until Page Contains Element    ${USERNAME_XP}
        Input Text    ${USERNAME_XP}    ${username}
        Click Button   Sign in
    ELSE
        Log    message=Log In page didn't appear.     level=WARN
    END

Open Trino Web UI
    [Documentation]    Launches Trino Web UI
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${starburst_url}=    Get Starburst Route
        ${url}=     Set Variable    ${starburst_url}/ui
    END
    Open Browser      url=http://${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}
    Go To    http://${url}
    Wait Until Page Contains     Cluster Overview

Check Trino Web UI Is Loaded
    [Documentation]    Checks Trino Web UI is rendered
    Wait Until Page Contains     Active workers
    Wait Until Page Contains     Query Details
    Wait Until Page Contains Element     xpath=//a[text()="Log Out"]

Open Managed Staburst Web UI
    [Documentation]    Launches Starburst Web UI
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${url}=    Get Starburst Route
    END
    Open Browser      url=http://${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}
    Wait Until Page Contains     Overview

Check Worksheet Tool Is Accessible
    [Documentation]    Check "Worksheet" tool inside Starburst UI is accessible
    ...                and able to reach test data sources
    Click Element    xpath=//span[text()="Query editor"]
    Wait Until Page Contains Element     xpath=//div[text()="system"]    timeout=10s
    Wait Until Page Contains Element     xpath=//div[text()="tpch"]      timeout=10s

Check Managed Starburst Web UI Is Loaded
    [Documentation]    Checks Starburst Web UI is rendered
    Wait Until Page Contains     Overview
    Wait Until Page Contains     CPU usage
    Wait Until Page Contains     Workers
    Wait Until Page Contains     Query overview
    Wait Until Page Contains     Cluster history
    Wait Until Page Contains     Query editor
    Wait Until Page Contains     Insights
    Wait Until Page Contains Element    xpath=//canvas[@class="chartjs-render-monitor"]

Run Query And Check Output
    [Documentation]    Runs a query against Starburst and checks the output matches
    ...                the expected values. If ${cli} is set to ${FALSE}, the keyword
    ...                expects a JupyterLab notebook to be open before running.
    ...                If If ${cli} is set to ${TRUE} the keyword expects to receive a ${host}
    [Arguments]    ${query_code}    ${expected_output}    ${use_regex}=${FALSE}    ${cli}=${FALSE}    ${host}=${NONE}
    IF    ${cli} == ${FALSE}
        ${output}=    Run Cell And Get Output    ${query_code}
        ${output}=    Replace String    ${output}    \n    ${EMPTY}
    ELSE
        ${rc}  ${output}=    Run And Return Rc And Output    echo "${query_code}" | trino --server http://${host}
        ${output}=    Replace String Using Regexp    ${output}    .+\nWARNING:.+\n    ${EMPTY}
        ${output}=    Replace String    ${output}    "    '
        ${output}=    Replace String    ${output}    \n    ${SPACE}
        ${output}=    Set Variable    [${output}]
    END
    IF    ${use_regex} == ${FALSE}
        Run Keyword And Continue On Failure    Should Be Equal As Strings    ${output}
        ...    ${expected_output}
    ELSE
        Run Keyword And Continue On Failure    Should Match Regexp    ${output}    ${expected_output}
    END

