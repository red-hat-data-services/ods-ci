*** Settings ***
Documentation       Resource file for openvino operator
Resource            ../JupyterHub/JupyterHubSpawner.robot
Library             SeleniumLibrary


*** Variables ***
${OPENVINO_IMAGE_XP}=   //input[contains(@name,"OpenVINO™ Toolkit")]


*** Keywords ***
Remove Openvino Operator
    [Documentation]     Cleans up the server and uninstall the openvino operator.
    Fix Spawner Status
    Uninstall Openvino Operator

Uninstall Openvino Operator
    [Documentation]    Uninstall openvino operator and it's realted component
    [Arguments]    ${cr_kind}=Notebook    ${cr_name}=v2022.3
    ...            ${cr_ns}=${APPLICATIONS_NAMESPACE}
    Go To    ${OCP_CONSOLE_URL}
    Maybe Skip Tour
    Move To Installed Operator Page Tab In Openshift    operator_name=${openvino_operator_name}
    ...    tab_name=Notebook    namespace=${cr_ns}
    Delete Openvino Notebook CR    cr_kind=${cr_kind}    cr_name=${cr_name}
    ...    cr_ns=${cr_ns}
    Uninstall Operator    ${openvino_operator_name}
    Sleep    30s
    ...    reason=There is a bug in dashboard showing an error message after ISV uninstall
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}        wait_for_cards=${FALSE}
    Remove Disabled Application From Enabled Page    app_id=openvino

Delete Openvino Notebook CR
    [Documentation]    Deletes the openvino CRs using OpenshiftLibrary.
    ...                Temporarily, it deletes all the CRs it finds, but
    ...                this going to change when installation will be replaces with CLI:
    ...                at that point the kw will delete a specific CR by name
    [Arguments]    ${cr_kind}    ${cr_name}    ${cr_ns}
    ${openvinos}=    Oc Get    api_version=intel.com/v1alpha1    kind=${cr_kind}   namespace=${cr_ns}
    ...            fields=['metadata.name']
    ${n_openvinos}=    Get Length    ${openvinos}
    IF    "${n_openvinos}" > "${1}"
        Log    message=There are more than once instance of Openvino..deleting all of them!
        ...    level=WARN
    END
    FOR    ${instance}    IN    @{openvinos}
        Oc Delete    api_version=intel.com/v1alpha1
        ...    kind=${cr_kind}  name=${instance}[metadata.name]  namespace=${cr_ns}
    END

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
