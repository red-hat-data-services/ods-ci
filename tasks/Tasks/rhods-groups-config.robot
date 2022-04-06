*** Settings ***
Documentation       Task to modify groups
...                 How to change groups dynamically:
...                 ./run_robot_test.sh --test-case ./tasks/Tasks/rhods-groups-config.robot
...                 -i Custom-Groups --test-variable ADMIN_GROUPS:<admin_groups>
...                 --test-variable ALLOWED_GROUPS:<allowed_groups>


Library             OpenShiftLibrary
Resource            ../Resources/Configurations/groups/rhods-groups-config.resource


*** Variables ***
${ADMIN_GROUPS} =       rhods-admins
${ALLOWED_GROUPS} =     rhods-users


*** Tasks ***
Configure Custom ODS Groups
    [Documentation]  Task that allows to configure dynamically cus 
    [Tags]    Custom-Groups
    Set Test Variable    ${EXPECTED_ADMIN_GROUPS}    ${ADMIN_GROUPS}
    Set Test Variable    ${EXPECTED_ALLOWED_GROUPS}    ${ALLOWED_GROUPS}
    ${actual_value} =    Modify ODS Groups    ${ADMIN_GROUPS}    ${ALLOWED_GROUPS}
    Should Be Equal As Strings    ${actual_value['admin_groups']}
    ...    ${EXPECTED_ADMIN_GROUPS}
    Should Be Equal As Strings    ${actual_value['allowed_groups']}
    ...    ${EXPECTED_ALLOWED_GROUPS}
