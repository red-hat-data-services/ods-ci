*** Settings ***
Documentation       Resource file for pachyderm operator
Library             SeleniumLibrary


*** Keywords ***
Delete Pipeline And Stop JupyterLab Server
    [Documentation]     Deletes pipeline using command from jupyterlab and clean and stops the server.
    Run Cell And Check For Errors   !pachctl delete pipeline edges
    Clean Up Server
    Stop JupyterLab Notebook Server
    Handle Start My Server
    Maybe Handle Server Not Running Page

Uninstall Pachyderm Operator
    [Documentation]    Uninstall pachyderm operator and its related component.
    Delete Pipeline And Stop JupyterLab Server
    Go To    ${OCP_CONSOLE_URL}
    Delete Tabname Instance For Installed Operator    ${pachyderm_operator_name}    Pachyderm       pachyderm
    Uninstall Operator    ${pachyderm_operator_name}
    Delete Project By Name      pachyderm
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=pachyderm
    Close All Browsers

