*** Settings ***
Library    OpenShiftCLI


*** Keywords ***
Create Group
    [Arguments]   ${group_name}
    #OpenShiftCLI.Create  kind=group   ${group_name}
    Run   oc adm groups new ${group_name}

Add User To Group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups add-users ${group_name} ${username}

Remove User From Group
    [Arguments]  ${username}  ${group_name}
    Run    oc adm groups remove-users ${group_name} ${username}

