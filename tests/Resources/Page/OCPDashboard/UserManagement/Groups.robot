*** Settings ***
Library    OpenShiftCLI
Resource      ../../../Page/Components/Components.resource


*** Keywords ***
Go To ${group_name} Group Page
    Navigate To Page    User Management    Groups
    Wait Until Page Contains Element    xpath://a[text()='${group_name}']
    Click Link    ${group_name}
    Wait Until Page Contains Element    xpath://h2/span[text()='Users']

Create Group
    [Arguments]   ${group_name}
    OpenShiftCLI.Create  kind=Group   src={"metadata": {"name": "${group_name}"}, "users": null}
    # Run   oc adm groups new ${group_name}

Delete Group
    [Arguments]   ${group_name}
    OpenShiftCLI.Delete  kind=Group   name=${group_name}
    # Run   oc delete group ${group_name}

Add User To Group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups add-users ${group_name} ${username}

Remove User From Group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups remove-users ${group_name} ${username}

Check User Is In A Group
    [Arguments]  ${username}  ${group_name}
    Go To ${group_name} Group Page
    Page Should Contain Element    xpath://a[text()="${username}"]

Check User Is Not In A Group
    [Arguments]  ${username}  ${group_name}
    Go To ${group_name} Group Page
    Page Should Not Contain Element    xpath://a[text()="${username}"]

