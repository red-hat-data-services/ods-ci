*** Settings ***
Documentation    Collection of keywords to interact with Storages
Resource       ./Projects.resource
Resource       ../../../../../Resources/ODS.robot


*** Variables ***
${SAVE_BUTTON}=    xpath://button[@data-id="save-rolebinding-button"]
${PERMISSIONS_DROPDOWN}=    xpath://td[@data-label="Permission"]//button[@aria-label="Options menu"]
${IS_CLUSTER_ADMIN}=    ${FALSE}
${CUSTOM_EMPTY_GROUP}=    empty-group


*** Keywords ***
Assign ${permission_type} Permissions To User ${username}
    [Documentation]    Assign the user ${username} and level of permission ${permission_type}
    ...    to the currently open DS Project in UI
    Log     ${username} - ${permission_type}
    Click Element    xpath://button[text()="Add user"]
    Element Should Be Disabled    ${SAVE_BUTTON}
    Input Text    css:input[aria-label="project-sharing-name-input"]    ${username}
    Select Permission Type    permission_type=${permission_type}
    Save Permission

Change ${username} Permissions To ${permission_type}
    [Documentation]    Change the level of permission ${permission_type} for the given user ${username}
    ...    in the currently open DS Project in UI
    Permissions.Click Action From Actions Menu    username=${username}
    ...    action=Edit
    Select Permission Type    permission_type=${permission_type}
    Save Permission

Remove ${username} Permissions
    [Documentation]    Remove the the access to the given user ${username}
    ...    from the currently open DS Project in UI
    Permissions.Click Action From Actions Menu    username=${username}
    ...    action=Delete

Select Permission Type
    [Documentation]    Set the dropdown for selecting the level of permission of a user
    ...    to the given value ${permission_type} in the currently open DS Project in UI
    [Arguments]    ${permission_type}
    Click Element    ${PERMISSIONS_DROPDOWN}
    Click Element    xpath://ul/li/button/span[text()="${permission_type}"]

Save Permission
    Element Should Be Enabled    ${SAVE_BUTTON}
    Click Element    ${SAVE_BUTTON}
    Wait Until Page Does Not Contain Element    ${SAVE_BUTTON}

Assign ${permission_type} Permissions To Group ${group_name}
    [Documentation]    Assign the user ${group_name} and level of permission ${permission_type}
    ...    to the currently open DS Project in UI
    Log     ${group_name} - ${permission_type}
    Click Element    xpath://button[text()="Add group"]
    Element Should Be Disabled    ${SAVE_BUTTON}
    IF    ${IS_CLUSTER_ADMIN} == ${FALSE}
        Input Text    css:input[aria-label="project-sharing-name-input"]    ${group_name}
    ELSE
        Click Element    css:input[aria-label="Name selection"]
        Wait Until Page Contains Element    xpath://li/button[text()="${group_name}"]
    END
    Select Permission Type    permission_type=${permission_type}
    Save Permission

Click Action From Actions Menu
    [Documentation]    Click an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${username}    ${action}
    Click Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/button[@aria-label="Actions"]    # robocop: disable
    Wait Until Page Contains Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/ul/li/button[text()="${action}"]    # robocop: disable
    Click Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/ul/li/button[text()="${action}"]    # robocop: disable

Get OpenShift RoleBinding
    [Documentation]    Fetch the RoleBinding object defining the level of permission of a
    ...    given subject ${subject_name} (i.e., user or group) to the given namespace ${namespace}
    [Arguments]    ${namespace}    ${subject_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get rolebinding -n ${namespace} -o jsonpath='{.items[?(@.subjects[0].name=="${subject_name}")]}'
    RETURN    ${rc}    ${out}

RoleBinding Should Not Exist
    [Documentation]    Verify a RoleBinding to give access to the given subject ${subject_name} (i.e., user or group)
    ...    for a given DS Project ${project_title} does not exist
    [Arguments]    ${project_title}    ${subject_name}
    ${ns}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    ${rc}    ${out}=    Get OpenShift RoleBinding    namespace=${ns}
    ...    subject_name=${subject_name}
    Run Keyword And Continue On Failure    Should Be Empty    ${out}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${rc}    0

RoleBinding Should Exist
    [Documentation]    Verify a RoleBinding to give access to the given subject ${subject_name} (i.e., user or group)
    ...    for a given DS Project ${project_title} does exist
    [Arguments]    ${project_title}    ${subject_name}
    ${ns}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    ${rc}    ${out}=    Get OpenShift RoleBinding    namespace=${ns}
    ...    subject_name=${subject_name}
    Run Keyword And Continue On Failure    Should Not Be Empty    ${out}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${rc}    0

Is ${username} In The Permissions Table
    ${present}=    Run Keyword And Return Status
    ...    Page Should Contain Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]
    RETURN    ${present}

Set RHODS Admins Group Empty Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${CUSTOM_EMPTY_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}

Set RHODS Admins Group To system:authenticated    # robocop:disable
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=system:authenticated
    ...     users_group=${STANDARD_USERS_GROUP}

Set RHODS Users Group Empty Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given empty group (i.e., with no users)
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${CUSTOM_EMPTY_GROUP}

Set RHODS Admins Group To Inexistent Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given inexistent group
    Set Access Groups Settings    admins_group=${CUSTOM_INEXISTENT_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}

Set RHODS Users Group To Inexistent Group
    [Documentation]     Sets the "admins_groups" field in "rhods-groups-config" ConfigMap
    ...                 to the given inexistent group
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${CUSTOM_INEXISTENT_GROUP}

Set Default Groups And Check Logs Do Not Change
    [Documentation]     Teardown for ODS-1408 and ODS-1494. It sets the default configuration of "rhods-groups-config"
    ...                 ConfigMap and checks if no new lines are generated in the logs after that.
    [Arguments]     ${delete_group}=${FALSE}
    ${lengths_dict}=    Get Lengths Of Dashboard Pods Logs
    Set Access Groups Settings    admins_group=${STANDARD_ADMINS_GROUP}
    ...     users_group=${STANDARD_USERS_GROUP}
    Logs Of Dashboard Pods Should Not Contain New Lines  lengths_dict=${lengths_dict}
    IF  "${delete_group}" == "${TRUE}"
        Delete Group    group_name=${CUSTOM_EMPTY_GROUP}
    END
