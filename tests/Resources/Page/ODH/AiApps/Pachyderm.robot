*** Settings ***
Documentation       Resource file for pachyderm operator
Library             SeleniumLibrary


*** Keywords ***
Uninstall Pachyderm Operator
    [Documentation]    Uninstall pachyderm operator and its related component.
    Run Cell And Check For Errors   !pachctl delete pipeline edges
    Close All Browsers
    Open Browser  ${OCP_CONSOLE_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
    LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
    Maybe Skip Tour
    Delete Pods Using Label Selector    pachyderm       app=pipeline-edges-v1
    Delete Tabname Instance For Installed Operator    ${pachyderm_operator_name}    Pachyderm       pachyderm
    Uninstall Operator    ${pachyderm_operator_name}
    Delete Project By Name      pachyderm
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=pachyderm
