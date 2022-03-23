*** Settings ***
Documentation       Resource file for pachyderm operator
Library             OpenShiftCLI
Library             SeleniumLibrary


*** Keywords ***
Uninstall Pachyderm Operator
    [Documentation]    Uninstall pachyderm operator and it's realted component
    Go To    ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Delete Tabname Instance For Installed Operator    ${pachyderm_operator_name}    Pachyderm
    ...    redhat-ods-applications
    Uninstall Operator    ${pachyderm_operator_name}
    OpenShiftCLI.Delete    kind=ImageStream    namespace=redhat-ods-applications
    ...    label_selector=opendatahub.io/notebook-image=true    field_selector=metadata.name==pachyderm
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=pachyderm
