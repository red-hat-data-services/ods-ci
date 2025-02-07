*** Settings ***
Documentation    Collection of keywords to interact with Storages
Resource       ./Projects.resource


*** Variables ***
${SAVE_PERMISSION_BUTTON}=    xpath://button[@data-id="save-rolebinding-button"]
${PERMISSIONS_DROPDOWN}=    xpath://td[@data-label="Permission"]//button[@aria-label="Options menu"]
${IS_CLUSTER_ADMIN}=    ${FALSE}
${USERS_TABLE}=    //table[@data-testid="role-binding-table User"]
${INPUT_USER}=    ${USERS_TABLE}//input[@data-testid="role-binding-name-input "]
${GROUPS_TABLE}=    //table[@data-testid="role-binding-table Group"]
${INPUT_GROUP}=    ${GROUPS_TABLE}//input[@data-testid="role-binding-name-input "]


*** Keywords ***
Assign ${permission_type} Permissions To User ${username}
    [Documentation]    Assign the user ${username} and level of permission ${permission_type}
    ...    to the currently open DS Project in UI
    Log     ${username} - ${permission_type}
    Click Element    //button[@data-testid="add-button user"]
    Element Should Be Disabled    ${SAVE_PERMISSION_BUTTON}
    Input Text    xpath:${INPUT_USER}    ${username}
    Select Permission Type    permission_type=${permission_type}
    Save Permission

Assign ${permission_type} Permissions To User ${username} In Project ${project_title}
    Open Data Science Projects Home Page
    Wait Until Project Is Listed    project_title=${project_title}
    Open Data Science Project Details Page    ${project_title}    tab_id=permissions
    Move To Tab             Permissions
    Assign ${permission_type} Permissions To User ${username}

Change ${username} Permissions To ${permission_type}
    [Documentation]    Change the level of permission ${permission_type} for the given user ${username}
    ...    in the currently open DS Project in UI
    Click Action From Actions Menu    item_title=${username}    action=Edit
    Select Permission Type    permission_type=${permission_type}
    Save Permission

Remove ${username} Permissions
    [Documentation]    Remove the access to the given user ${username}
    ...    from the currently open DS Project in UI
    Click Action From Actions Menu    item_title=${username}    action=Delete

Select Permission Type
    [Documentation]    Set the dropdown for selecting the level of permission of a user
    ...    to the given value ${permission_type} in the currently open DS Project in UI
    [Arguments]    ${permission_type}
    Click Element    ${PERMISSIONS_DROPDOWN}
    Click Element    xpath://button[@role="option"]//*[.="${permission_type}"]

Save Permission
    Element Should Be Enabled    ${SAVE_PERMISSION_BUTTON}
    Click Element    ${SAVE_PERMISSION_BUTTON}
    Wait Until Page Does Not Contain Element    ${SAVE_PERMISSION_BUTTON}    timeout=30s

Assign ${permission_type} Permissions To Group ${group_name}
    [Documentation]    Assign the user ${group_name} and level of permission ${permission_type}
    ...    to the currently open DS Project in UI
    Log     ${group_name} - ${permission_type}
    Click Element    //button[@data-testid="add-button group"]
    Element Should Be Disabled    ${SAVE_PERMISSION_BUTTON}
    IF    ${IS_CLUSTER_ADMIN} == ${FALSE}
        Input Text    xpath:${INPUT_GROUP}    ${group_name}
    ELSE
        Click Element    css:input[aria-label="Name selection"]
        Wait Until Page Contains Element    xpath://li/button[text()="${group_name}"]
    END
    Select Permission Type    permission_type=${permission_type}
    Save Permission

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
