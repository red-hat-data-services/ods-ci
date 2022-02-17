*** Settings ***
Documentation       Resource file for aikit operator

Library             SeleniumLibrary


*** Keywords ***
Uninstall AIKIT Operator
    [Documentation]    Uninstall intel aikit operator and it's realted component
    Go To    ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator    ${intel_aikit_operator_name}    AIKitContainer
    ...    redhat-ods-applications
    Uninstall Operator    ${intel_aikit_operator_name}
    OpenShiftCLI.Delete    kind=ImageStream    namespace=redhat-ods-applications
    ...    label_selector=opendatahub.io/notebook-image=true    field_selector=metadata.name==oneapi-aikit
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=aikit

Verify JupyterHub Can Spawn AIKIT Notebook
    [Documentation]    Spawn openvino notebook and check if
    ...    current working path is matching
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element    xpath://input[@name="oneAPI AI Analytics Toolkit"]
    Wait Until Element Is Enabled    xpath://input[@name="oneAPI AI Analytics Toolkit"]    timeout=10
    Spawn Notebook With Arguments    image=oneapi-aikit
    Fix Spawner Status
