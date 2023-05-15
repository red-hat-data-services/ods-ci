*** Settings ***
Documentation    Collection of keywords to interact with Storages
Resource       ./Projects.resource

*** Variables ***
${SAVE_BUTTON}=    xpath://button[@data-id="save-rolebinding-button"]
${PERMISSIONS_DROPDOWN}=    xpath://td[@data-label="Permission"]//button[@aria-label="Options menu"] 

*** Keywords ***
Assign ${permission_type} Permissions To ${username}
    Log     ${username} - ${permission_type}
    Click Element    xpath://button[text()="Add user"]
    Element Should Be Disabled    ${SAVE_BUTTON}
    Input Text    css:input[aria-label="project-sharing-name-input"]    ${username}
    Select Permission Type    permission_type=${permission_type}

Change ${username} Permissions To ${permission_type}
    Permissions.Click Action From Actions Menu    username=${username}
    ...    action=Edit
    Select Permission Type    permission_type=${permission_type}

Remove ${username} Permissions
    Permissions.Click Action From Actions Menu    username=${username}
    ...    action=Delete

Select Permission Type
    [Arguments]    ${permission_type}
    Click Element    ${PERMISSIONS_DROPDOWN}
    Click Element    xpath://ul/li/button/span[text()="${permission_type}"]
    Element Should Be Enabled    ${SAVE_BUTTON}
    Click Element    ${SAVE_BUTTON}
    Wait Until Page Does Not Contain Element    ${SAVE_BUTTON}
Click Action From Actions Menu
    [Documentation]    Clicks an action from Actions menu (3-dots menu on the right)
    [Arguments]    ${username}    ${action}
    Click Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/button[@aria-label="Actions"]
    Wait Until Page Contains Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/ul/li/button[text()="${action}"]
    Click Element       xpath=//tr[td[@data-label="Username"]//*[text()="${username}"]]/td[contains(@class,"pf-c-table__action")]/div/ul/li/button[text()="${action}"]

Get OpenShift RoleBinding
    [Arguments]    ${namespace}    ${subject_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get rolebinding -n ${namespace} -o jsonpath='{.items[?(@.subjects[0].name=="${subject_name}")]}'
    [Return]    ${rc}    ${out}

RoleBinding Should Not Exist
    [Arguments]    ${project_title}    ${subject_name}
    ${ns}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    ${rc}    ${out}=    Get OpenShift RoleBinding    namespace=${ns}
    ...    subject_name=${subject_name}
    Run Keyword And Continue On Failure    Should Be Empty    ${out}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${rc}    0

RoleBinding Should Exist
    [Arguments]    ${project_title}    ${subject_name}
    ${ns}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    ${rc}    ${out}=    Get OpenShift RoleBinding    namespace=${ns}
    ...    subject_name=${subject_name}
    Run Keyword And Continue On Failure    Should Be Empty    ${out}
    Run Keyword And Continue On Failure    Should Be Equal As Strings    ${rc}    0
