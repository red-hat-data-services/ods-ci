*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource      ../../../Page/OCPDashboard/UserManagement/Groups.robot
Resource      ../../../Common.robot
Library       JupyterLibrary
Library       OpenShiftCLI


*** Variables ***
${CUSTOM_ADMINS_GROUP}=   custom-admins
${CUSTOM_USERS_GROUP}=    custom-users


*** Keywords ***
Create Custom Groups
    [Documentation]    Creates two user groups: custom-admins and customer-users
    ${admin_created}=    Run Keyword And Return Status    Create Group  group_name=${CUSTOM_ADMINS_GROUP}
    IF    $admin_created == False
          FAIL  Creation of ${CUSTOM_ADMINS_GROUP} group failed. Check the logs
    END
    ${user_created}=     Run Keyword And Return Status    Create Group  group_name=${CUSTOM_USERS_GROUP}
    IF    $user_created == False
        FAIL    Creation of ${CUSTOM_USERS_GROUP} group failed. Check the logs
    END
    Navigate To Page    User Management    Groups
    Wait Until Page Contains  Create Group
    Page Should Contain    ${CUSTOM_ADMINS_GROUP}
    Page Should Contain    ${CUSTOM_USERS_GROUP}

Delete Custom Groups
    [Documentation]    Deletes two user groups: custom-admins and customer-users
    Delete Group  group_name=${CUSTOM_ADMINS_GROUP}
    Delete Group  group_name=${CUSTOM_USERS_GROUP}
    Navigate To Page    User Management    Groups
    Wait Until Page Contains  Create Group
    Page Should Not Contain    ${CUSTOM_ADMINS_GROUP}
    Page Should Not Contain    ${CUSTOM_USERS_GROUP}

Add Test Users To Custom Groups
    [Documentation]    Adds users to custom-admins and customer-users groups
    Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Remove Test Users From RHODS Standard Groups
    Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${OCP_USER_GROUPS.ADMINS}
    Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${OCP_USER_GROUPS.USERS}
    Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${OCP_USER_GROUPS.ADMINS}
    Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${OCP_USER_GROUPS.USERS}

Add Test Users Back To RHODS Standard Groups
    Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${OCP_USER_GROUPS.ADMINS}
    Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${OCP_USER_GROUPS.USERS}
    Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${OCP_USER_GROUPS.ADMINS}
    Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${OCP_USER_GROUPS.USERS}

Remove Test Users From Custom Groups
    Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Check New Access Configuration Works As Expected
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level  ${TEST_USER.USERNAME}
    ...                                   ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}    none
    Click Link    Logout
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level    ${TEST_USER_2.USERNAME}
    ...                                   ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}    admin
    Click Link    Logout
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level    ${TEST_USER_3.USERNAME}
    ...                                   ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}    user
    Click Link    Logout

Check Standard Access Configuration Works As Expected
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level  ${TEST_USER.USERNAME}
    ...                                   ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}    admin
    Click Link    Logout

Apply New Groups Config Map
   OpenShiftCLI.Patch    kind=ConfigMap
   ...                   src={"data":{"admin_groups": "${CUSTOM_ADMINS_GROUP}","allowed_groups": "${CUSTOM_USERS_GROUP}"}}
   ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
   OpenShiftCLI.Patch    kind=ConfigMap
   ...                   src={"metadata":{"labels": {"opendatahub.io/modified": "true"}}}
   ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge

Restore RHODS Standard Groups Config Map
   OpenShiftCLI.Patch    kind=ConfigMap
   ...                   src={"data":{"admin_groups": "${OCP_USER_GROUPS.ADMINS}","allowed_groups": "${OCP_USER_GROUPS.USERS}"}}
   ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
   OpenShiftCLI.Patch    kind=ConfigMap
   ...                   src={"metadata":{"labels": {"opendatahub.io/modified": "false"}}}
   ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge