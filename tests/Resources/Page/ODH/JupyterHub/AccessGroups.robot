*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource      ../../../Page/OCPDashboard/UserManagement/Groups.robot
Resource      ../../../Common.robot
Resource      JupyterHubSpawner.robot
Resource      HighAvailability.robot
Library       JupyterLibrary
Library       OpenShiftCLI


*** Variables ***
${CUSTOM_ADMINS_GROUP}=   custom-admins-group
${CUSTOM_USERS_GROUP}=    custom-users-group
${STANDARD_ADMINS_GROUP}=  rhods-admins
${STANDARD_USERS_GROUP}=   rhods-users


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
    Capture Page Screenshot    user_groups.png
    Page Should Contain    ${CUSTOM_ADMINS_GROUP}
    Page Should Contain    ${CUSTOM_USERS_GROUP}


Delete Custom Groups
    [Documentation]    Deletes two user groups: custom-admins and customer-users
    Delete Group  group_name=${CUSTOM_ADMINS_GROUP}
    Delete Group  group_name=${CUSTOM_USERS_GROUP}
    Navigate To Page    User Management    Groups
    Wait Until Page Contains  Create Group
    Capture Page Screenshot    user_groups_deletion.png
    Page Should Not Contain    ${CUSTOM_ADMINS_GROUP}
    Page Should Not Contain    ${CUSTOM_USERS_GROUP}

Add Test Users To Custom Groups
    [Documentation]    Adds two tests users to custom-admins and customer-users groups
    Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Remove Test Users From RHODS Standard Groups
    [Documentation]    Removes two tests users from rhods-admins and rhods-users
    Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${STANDARD_ADMINS_GROUP}
    Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${STANDARD_USERS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${STANDARD_ADMINS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${STANDARD_USERS_GROUP}

Add Test Users Back To RHODS Standard Groups
    [Documentation]    Adds two tests users back to rhods-admins and rhods-users
    Add User To Group    username=${TEST_USER_2.USERNAME}    group_name=${STANDARD_ADMINS_GROUP}
    Add User To Group    username=${TEST_USER_3.USERNAME}    group_name=${STANDARD_USERS_GROUP}
    Check User Is In A Group    username=${TEST_USER_2.USERNAME}   group_name=${STANDARD_ADMINS_GROUP}
    Check User Is In A Group    username=${TEST_USER_3.USERNAME}   group_name=${STANDARD_USERS_GROUP}

Remove Test Users From Custom Groups
    [Documentation]    Removes two tests users from custom-admins and customer-users groups
    Remove User From Group    username=${TEST_USER_2.USERNAME}    group_name=${CUSTOM_ADMINS_GROUP}
    Remove User From Group    username=${TEST_USER_3.USERNAME}    group_name=${CUSTOM_USERS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_2.USERNAME}   group_name=${CUSTOM_ADMINS_GROUP}
    Check User Is Not In A Group    username=${TEST_USER_3.USERNAME}   group_name=${CUSTOM_USERS_GROUP}

Check New Access Configuration Works As Expected
    [Documentation]    Checks if the new access configuration (using two custom groups)
    ...                works as expected in JH
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Handle Bad Gateway Page
    Run Keyword And Continue On Failure   Login Verify Access Level  ${TEST_USER.USERNAME}
    ...                                   ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}    none
    Capture Page Screenshot    perm_denied.png
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level    ${TEST_USER_2.USERNAME}
    ...                                   ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}    admin
    Capture Page Screenshot    perm_admin.png
    Logout Via Button
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level    ${TEST_USER_3.USERNAME}
    ...                                   ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}    user
    Capture Page Screenshot    perm_user.png
    Logout Via Button

Check Standard Access Configuration Works As Expected
    [Documentation]    Checks if the standard access configuration
    ...                works as expected in JH
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Handle Bad Gateway Page
    Run Keyword And Continue On Failure   Login Verify Access Level  ${TEST_USER.USERNAME}
    ...                                   ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}    admin
    Capture Page Screenshot    perm_admin_std.png
    Logout Via Button
    Go To RHODS Dashboard
    Launch JupyterHub From RHODS Dashboard Link
    Run Keyword And Continue On Failure   Login Verify Access Level    ${TEST_USER_4.USERNAME}
    ...                                   ${TEST_USER_4.PASSWORD}    ${TEST_USER_4.AUTH_TYPE}    user
    Capture Page Screenshot    perm_user_std.png
    Logout Via Button

Apply New Groups Config Map
    [Documentation]    Changes the rhods-groups config map to set the new access configuration
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"data":{"admin_groups": "${CUSTOM_ADMINS_GROUP}","allowed_groups": "${CUSTOM_USERS_GROUP}"}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"metadata":{"labels": {"opendatahub.io/modified": "${STANDARD_GROUPS_MODIFIED}"}}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge

Restore RHODS Standard Groups Config Map
    [Documentation]    Restores the standard rhods-groups config map
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"data":{"admin_groups": "${STANDARD_ADMINS_GROUP}","allowed_groups": "${STANDARD_USERS_GROUP}"}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge
    OpenShiftCLI.Patch    kind=ConfigMap
    ...                   src={"metadata":{"labels": {"opendatahub.io/modified": "true"}}}
    ...                   name=rhods-groups-config   namespace=redhat-ods-applications  type=merge

Restore Standard Configuration
    [Documentation]    Restores the standard RHODS access configuration
    Restore RHODS Standard Groups Config Map
    Rollout JupyterHub
    Go To    ${OCP_CONSOLE_URL}
    Add Test Users Back To RHODS Standard Groups
    Remove Test Users From Custom Groups
    Delete Custom Groups
    Check Standard Access Configuration Works As Expected

Set Standard RHODS Groups Variables
    [Documentation]     Sets the RHODS groups name based on RHODS version
    ${version_check}=    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check} == True
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}      dedicated-admins
        Set Suite Variable    ${STANDARD_USERS_GROUP}       'system:authenticated'
        Set Suite Variable    ${STANDARD_GROUPS_MODIFIED}       'true'
    ELSE
        Set Suite Variable    ${STANDARD_ADMINS_GROUP}      rhods-admins
        Set Suite Variable    ${STANDARD_USERS_GROUP}       rhods-users
        Set Suite Variable    ${STANDARD_GROUPS_MODIFIED}       'false'
    END
