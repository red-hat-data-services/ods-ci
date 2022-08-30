*** Settings ***
Library         OpenShiftCLI
Library         OpenShiftLibrary
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/JupyterHub/JupyterHubSpawner.robot


*** Test Cases ***
Verify If Unauthorisez User Can Not Change The Permission
    [Tags]  ODS-1661
    ...     ODS-1660
    Set Library Search Order  SeleniumLibrary
    Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear All The Input Values In User Managermant
    Add OpenShift Groups To Data Science Administrators         cluster-admins  rhods-admins
    Add OpenShift Users groups to Data Science administrators   system:authenticated
    Save Changes In User Management Setting

    Verify Expect Changes In AdminGroups Are Present In CRD     cluster-admins  rhods-admins
    Verify Expect Changes In AllowedGroups Are Present In CRD   system:authenticated

    Check User Management Option Is Available For The User     ${OCP_ADMIN_USER.USERNAME}   ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
    Remove OpenShift Groups To Data Science Administrators     rhods-admins
    Save Changes In User Management Setting
    Switch Browser  1
    Add OpenShift Groups To Data Science Administrators         rhods-noaccess
    Add OpenShift Users Groups To Data Science Administrators   rhods-users

    Verify Expect Changes In AdminGroups Are Present In CRD     cluster-admins
    Verify Expect Changes In AllowedGroups Are Present In CRD   system:authenticated
    Save Changes In User Management Setting
    Page Should Contain  Unable to load User and group settings
    Switch Browser  2
    [Teardown]  Teardown For Admin UI   ${OCP_ADMIN_USER.USERNAME}   ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}

Verify User Is Able To Spawn Jupyter Notebook
    [Documentation]     Verify Correct User Is able to Spawn Jupyter Notebook
    [Tags]   ODS-1681
    Set Library Search Order  SeleniumLibrary
    Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear All The Input Values In User Managermant
    Add OpenShift Groups To Data Science Administrators         rhods-admins
    Add OpenShift Users Groups To Data Science Administrators   rhods-admins
    Save Changes In User Management Setting
    Launch JupyterHub Spawner From Dashboard     ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    [Teardown]  Teardown For Admin UI  ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}

Verify User Is Not Able To Spawn Jupyter Notebook
    [Documentation]    Verify User Is Not Able To Spawn Jupyter Notebook
    [Tags]   ODS-1680
    Set Library Search Order  SeleniumLibrary
    Check User Management Option Is Available For The User   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
    Clear All The Input Values In User Managermant
    Add OpenShift groups To Data Science Administrators         rhods-admin
    Add OpenShift Users groups To Data Science Administrators   rhods-admin
    Save Changes In User Management Setting
    Close Browser
    Launch Dashboard  ocp_user_name=${TEST_USER_3.USERNAME}  ocp_user_pw=${TEST_USER_3.PASSWORD}  ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until Page Contains    Launch application
    Click Element               //*[@class="odh-card__footer__link"]
    Wait Until Page Contains    Page Not Found   timeout=15
    Page Should Contain         Page Not Found
    [Teardown]  Teardown For Admin UI   ${TEST_USER.USERNAME}   ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}

*** Keywords ***
Add OpenShift groups To Data Science Administrators
    [Documentation]  Add OpenShift groups to Data Science administrators
    [Arguments]     @{admin_groups}
    Set Library Search Order  SeleniumLibrary
    Click Button   (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${1}]
    FOR    ${admin_group}    IN    @{admin_groups}
             ${present}=  Run Keyword And Return Status    Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${admin_group}")]
            IF  ${present} != True
                Click Button    //*[@class="pf-c-select__menu-item"and contains(text(), "${admin_group}")]
            END
    END
    Press Keys    None    ESC

Add OpenShift Users groups To Data Science Administrators
    [Documentation]  Add OpenShift Users groups to Data Science administrators
    [Arguments]     @{user_groups}
    Set Library Search Order  SeleniumLibrary
    Click Button    (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${2}]

    FOR    ${user_group}    IN    @{user_groups}
            ${present}=  Run Keyword And Return Status
               ...  Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${user_group}")]
             IF  ${present} != True
                Click Element    //*[@class="pf-c-select__menu-item"and contains(text(), "${user_group}")]
             END
    END
    Press Keys    None    ESC

Check User Management Option Is Available For The User
    [Arguments]   ${username}  ${password}  ${auth_type}
    Launch Dashboard  ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Menu.Navigate To Page    Settings    User management
    SeleniumLibrary.Wait Until Element Is Visible   //*[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"]  timeout=20

Remove OpenShift Users Groups To Data Science Administrators
    [Documentation]     Remove User from OpenShift Users groups to Data Science administrators
    [Arguments]   @{user_groups}
    Set Library Search Order  SeleniumLibrary
    FOR    ${user_group}    IN    @{user_groups}
            Click Element     (//*[@class="pf-c-form__group-control"])[${2}]//*[@class="pf-c-chip__text" and contains(text(),"${user_groups}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Remove OpenShift Groups To Data Science Administrators
    [Documentation]  Add OpenShift groups to Data Science administrators
    [Arguments]     @{admin_groups}
    Set Library Search Order  SeleniumLibrary
    FOR    ${admin_group}    IN    @{admin_groups}
            Click Button    (//*[@class="pf-c-form__group-control"])[${1}]//*[@class="pf-c-chip__text" and contains(text(),"${admin_group}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Save Changes In User Management Setting
    [Documentation]  Save User management Settings
    Click Button    Save changes
    Sleep  60s

Verify Expect Changes In AdminGroups Are Present In CRD
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]  @{UIadminGroupsList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=redhat-ods-applications  field_selector=metadata.name=odh-dashboard-config
    ${adminGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}
    @{adminGroupsList}  Split String  ${adminGroups}  ,
    Lists Should Be Equal      ${UIadminGroupsList}  ${adminGroupsList}

Verify Expect Changes in AllowedGroups Are Present In CRD
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]   @{UIallowedGroupList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=redhat-ods-applications  field_selector=metadata.name=odh-dashboard-config
    ${allowedGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}
    @{allowedGroupsList}  Split String  ${allowedGroups}  ,
    Lists Should Be Equal      ${UIallowedGroupList}  ${allowedGroupsList}

Clear All The Input Values In User Managermant
    [Documentation]  Clear All the input values in User Managermant
    Set Library Search Order  SeleniumLibrary
    @{remove_users_list}  Get Webelements  (//*[@class="pf-c-form__group-control"])//*[@class="pf-c-chip__text" ]//following-sibling::button[1]
    FOR  ${user}   IN   @{remove_users_list}
        Click Button  (//*[@class="pf-c-form__group-control"])//*[@class="pf-c-chip__text" ]//following-sibling::button[1]
    END
    Capture Page Screenshot  clean.png

Teardown For Admin UI
    [Documentation]  Setup Default Values in User Management Settings
    [Arguments]   ${username}  ${password}  ${auth_type}
    Check User Management Option is available for the user  ${username}  ${password}  ${auth_type}
    Clear All the input values in User Managermant
    Add OpenShift groups to Data Science administrators         dedicated-admins
    Add OpenShift Users groups to Data Science administrators   system:authenticated
    Save Changes In User Management Setting
    Close All Browsers
