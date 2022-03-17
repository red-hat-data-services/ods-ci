*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/Page/OCPLogin/OCPLogin.resource
Resource            ../../../Resources/OCP.resource

Test Setup          Dashboard Test Setup
Test Teardown       Dashboard Test Teardown


*** Variables ***
${pachyderm_container_name}     Pachyderm
${pachyderm_appname}            pachyderm


*** Test Cases ***
Verify Pachyderm Can Be Installed Using OpenShift Console
    [Tags]    Tier2    ODS-1137
    Check And Install Operator in Openshift    ${pachyderm_container_name}    ${pachyderm_appname}
    Go To RHODS Dashboard
    Verify Service Is Enabled    Pachyderm


*** Keywords ***
Dashboard Test Setup
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${OCP_CONSOLE_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login to OCP
    Wait Until OpenShift Console Is Loaded

Dashboard Test Teardown
    Close All Browsers
