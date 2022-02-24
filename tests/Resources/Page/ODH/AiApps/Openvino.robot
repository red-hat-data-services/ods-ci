*** Settings ***
Documentation       Resource file for openvino operator

Library             SeleniumLibrary


*** Keywords ***
Uninstall Openvino Operator
    [Documentation]    Uninstall openvino operator and it's realted component
    Go To    ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator    ${openvino_operator_name}    Notebook    redhat-ods-applications
    Uninstall Operator    ${openvino_operator_name}
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=openvino

Verify JupyterHub Can Spawn Openvino Notebook
    [Documentation]    Spawn openvino notebook and check if
    ...    current working path is matching
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element    xpath://input[@name="OpenVINO™ Toolkit"]
    Wait Until Element Is Enabled    xpath://input[@name="OpenVINO™ Toolkit"]    timeout=10
    Spawn Notebook With Arguments    image=openvino-notebook
    Run Cell And Check Output    !pwd    /opt/app-root/src
    Fix Spawner Status
