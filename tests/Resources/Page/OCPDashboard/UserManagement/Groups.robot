*** Settings ***

Library       OperatingSystem
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
    OpenShiftCLI.Create  kind=Group   src={"metadata": {"name": "${group_name}"}, "users": null}
    # Run   oc adm groups new ${group_name}

Delete Group
    [Documentation]     Deletes a user group in OCP
    [Arguments]   ${group_name}
    OpenShiftCLI.Delete  kind=Group   name=${group_name}
    # Run   oc delete group ${group_name}

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
    Go To ${group_name} Group Page
    Page Should Contain Element    xpath://a[text()="${username}"]

Check User Is Not In A Group
    [Documentation]     Check if a user is not present in OCP user group using UI
    [Arguments]  ${username}  ${group_name}
    Go To ${group_name} Group Page
    Page Should Not Contain Element    xpath://a[text()="${username}"]

