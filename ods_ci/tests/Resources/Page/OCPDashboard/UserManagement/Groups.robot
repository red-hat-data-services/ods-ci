*** Settings ***
Library       OpenShiftLibrary
Library       OperatingSystem
Library       Collections
Resource      ../../../Page/Components/Components.resource


*** Keywords ***
Go To ${group_name} Group Page
    [Documentation]     Open a user group page in OCP Dashboard
    Navigate To Page    User Management    Groups
    Wait Until Page Contains Element    xpath://a[text()='${group_name}']
    Click Link    ${group_name}
    Wait Until Page Contains Element    xpath://h2/span[text()='Users']

Create Group
    [Documentation]     Creates a user group in OCP
    [Arguments]   ${group_name}
    ${res}  ${output}=    Run And Return Rc And Output    oc adm groups new ${group_name}
    # Oc Create  kind=Group   src={"metadata": {"name": "${group_name}"}, "users": null}
    Should Be Equal As Integers    ${res}    0

Delete Group
    [Documentation]     Deletes a user group in OCP
    [Arguments]   ${group_name}
    Oc Delete  kind=Group   name=${group_name}

Add User To Group
    [Documentation]     Add a user to a given OCP user group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups add-users ${group_name} ${username}

Remove User From Group
    [Documentation]     Add a user to a given OCP user group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups remove-users ${group_name} ${username}

Check User Is In A Group
    [Documentation]     Check if a user is present in OCP user group using UI
    [Arguments]  ${username}  ${group_name}
    ${users_in_group}=    OpenshiftLibrary.Oc Get    kind=Group   name=${group_name}    fields=['users']
    List Should Contain Value    ${users_in_group}[0][users]    ${username}

Check User Is Not In A Group
    [Documentation]     Check if a user is not present in OCP user group using UI
    [Arguments]  ${username}  ${group_name}
    ${users_in_group}=    OpenshiftLibrary.Oc Get    kind=Group   name=${group_name}    fields=['users']
    List Should Not Contain Value    ${users_in_group}[0][users]    ${username}

