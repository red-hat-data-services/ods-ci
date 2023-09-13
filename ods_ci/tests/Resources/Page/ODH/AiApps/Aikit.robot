*** Settings ***
Documentation       Resource file for aikit operator

Resource           ../JupyterHub/JupyterHubSpawner.robot
Library             SeleniumLibrary
Library             OpenShiftLibrary


*** Keywords ***
Remove AIKIT Operator
    [Documentation]     Cleans up the server and uninstall the aikit operator.
    Fix Spawner Status
    Uninstall AIKIT Operator

Uninstall AIKIT Operator
    [Documentation]    Uninstall intel aikit operator and it's realted component
    [Arguments]    ${cr_kind}=AIKitContainer    ${cr_name}=intel-aikit-container
    ...            ${cr_ns}=${APPLICATIONS_NAMESPACE}
    Go To    ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Oc Delete    kind=${cr_kind}  name=${cr_name}  namespace=${cr_ns}
    Move To Installed Operator Page Tab In Openshift    operator_name=${intel_aikit_operator_name}
    ...    tab_name=AIKitContainer    namespace=${cr_ns}
    Uninstall Operator    ${intel_aikit_operator_name}
    Oc Delete    kind=ImageStream    namespace=${cr_ns}
    ...    label_selector=opendatahub.io/notebook-image=true    field_selector=metadata.name==oneapi-aikit
    Sleep    30s
    ...    reason=There is a bug in dashboard showing an error message after ISV uninstall
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}    wait_for_cards=${FALSE}
    Remove Disabled Application From Enabled Page    app_id=aikit

Verify JupyterHub Can Spawn AIKIT Notebook
    [Documentation]    Spawn openvino notebook and check if
    ...    current working path is matching
    Launch JupyterHub Spawner From Dashboard
    Wait Until Page Contains Element    xpath://input[@name="oneAPI AI Analytics Toolkit"]
    Wait Until Element Is Enabled    xpath://input[@name="oneAPI AI Analytics Toolkit"]    timeout=10
    Spawn Notebook With Arguments    image=oneapi-aikit
    Verify Library Version Is Greater Than  jupyterlab  3.1.4
    Verify Library Version Is Greater Than  notebook    6.4.1
