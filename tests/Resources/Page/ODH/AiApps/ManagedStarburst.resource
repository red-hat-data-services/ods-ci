*** Settings ***
Library    OperatingSystem
Library    OpenShiftLibrary
Library    SeleniumLibrary



*** Variables ***
${STARBURST_CR_DEFAULT_NAMESPACE}=    redhat-starburst-operator
${USERNAME_XP}=    xpath=//input[@id="username"]
${STARBURST_ROUTE}=    web-ui

*** Keywords ***
Create Starburst Route
    [Arguments]    ${name}
    ${rc}=    Run And Return Rc    oc expose svc starburst --name ${name} -n ${STARBURST_CR_DEFAULT_NAMESPACE}
    ${route}=    Get Starburst Route
    [Return]    ${rc}    ${route}

Get Starburst Route
    [Arguments]    ${name}=${STARBURST_ROUTE}
    ${route}=    Get Starburst Route
    [Return]    ${route}

Create Starburst Route If Not Exists
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
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${url}=    Get Starburst Route
    END
    Open Browser      url=${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}    

Open Managed Staburst Web UI
    [Arguments]    ${url}=${NONE}    ${user}=dummy-user
    IF    "${url}" == "${NONE}"
        Log    message=Fetching Starburst Route...
        ${trino_url}=    Get Starburst Route
        ${url}=     Set Variable    ${trino_url}/ui/insights
    END
    Open Browser      url=${url}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Perform Log In    username=${user}    
