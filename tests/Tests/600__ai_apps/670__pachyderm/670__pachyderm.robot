*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/Page/OCPLogin/OCPLogin.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/ODH/AiApps/AiApps.resource

Test Setup          Dashboard Test Setup
Test Teardown       Dashboard Test Teardown


*** Variables ***
${pachyderm_container_name}     Pachyderm
${pachyderm_operator_name}      Pachyderm
${pachyderm_appname}            pachyderm



*** Test Cases ***
Verify Pachyderm Can Be Installed Using OpenShift Console
    [Tags]      Tier2
    ...         ODS-1137    ODS-1138
    Check And Install Operator in Openshift    ${pachyderm_container_name}    ${pachyderm_appname}
    Create Project      pachyderm
    Run     oc create secret generic pachyderm-aws-secret -n pachyderm --from-literal=access-id=${S3.AWS_ACCESS_KEY_ID} --from-literal=access-secret=${S3.AWS_SECRET_ACCESS_KEY} --from-literal=region=us-east-1 --from-literal=bucket=ods-ci-pachyderm
    Create Tabname Instance For Installed Operator        ${pachyderm_container_name}   ${pachyderm_container_name}     pachyderm
    Wait Until Keyword Succeeds     120     1       Wait Until Status Is Running
    Go To RHODS Dashboard
    Verify Service Is Enabled    Pachyderm
    [Teardown]  Uninstall Pachyderm Operator

*** Keywords ***
Dashboard Test Setup
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${OCP_CONSOLE_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login to OCP
    Wait Until OpenShift Console Is Loaded

Dashboard Test Teardown
    Close All Browsers

Wait Until Status Is Running
    Element Text Should Be    //span[@data-test="status-text"]      Running
