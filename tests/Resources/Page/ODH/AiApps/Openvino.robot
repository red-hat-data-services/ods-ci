*** Settings ***
Documentation       Resource file for openvino operator

Library             SeleniumLibrary


*** Variables ***
${OPENVINO_IMAGE_XP}=   //input[contains(@name,"OpenVINO™ Toolkit")]


*** Keywords ***
Uninstall Openvino Operator
    [Documentation]    Uninstall openvino operator and it's realted component
    Clean Up Server
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
    Wait Until Page Contains Element    xpath=${OPENVINO_IMAGE_XP}
    Wait Until Element Is Enabled    xpath=${OPENVINO_IMAGE_XP}    timeout=10
    ${image_id}=    Get Element Attribute    xpath=${OPENVINO_IMAGE_XP}  id
    Spawn Notebook With Arguments    image=${image_id}
    Run Cell And Check Output    !pwd    /opt/app-root/src
    Verify Library Version Is Greater Than  jupyterlab  3.1.4
    Verify Library Version Is Greater Than  notebook    6.4.1
    Fix Spawner Status
