*** Settings ***
Library         OpenShiftLibrary
Resource        ../../LoginPage.robot

*** Keywords ***
Add OpenShift Groups To Data Science Administrators
    [Documentation]  Add OpenShift groups to Data Science administrators
    [Arguments]     @{admin_groups}
    Click Button   (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${1}]
    FOR    ${admin_group}    IN    @{admin_groups}
             ${present}=  Run Keyword And Return Status    Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${admin_group}")]
            IF  ${present} != True
                Click Button    //*[@class="pf-c-select__menu-item"and contains(text(), "${admin_group}")]
            END
    END
    Press Keys    None    ESC

Add OpenShift Groups To Data Science User Groups
    [Documentation]  Add OpenShift Groups To Data Science User Groups
    [Arguments]     @{user_groups}
    Click Button    (//button[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"])[${2}]

    FOR    ${user_group}    IN    @{user_groups}
            ${present}=  Run Keyword And Return Status
               ...  Element Should Be Visible   //*[@class="pf-c-select__menu-item pf-m-selected" and contains(text(), "${user_group}")]
             IF  ${present} != True
                Click Element    //*[@class="pf-c-select__menu-item"and contains(text(), "${user_group}")]
             END
    END
    Press Keys    None    ESC

Launch Dashboard And Check User Management Option Is Available For The User
    [Documentation]  Launch Dashboard And Check User Management Option Is
     ...    Available For The User
    [Arguments]   ${username}  ${password}  ${auth_type}
    Launch Dashboard  ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${auth_type}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ${authorization_required} =  Is Service Account Authorization Required
    Run Keyword If  ${authorization_required}  Authorize jupyterhub service account
    Menu.Navigate To Page    Settings    User management
    SeleniumLibrary.Wait Until Element Is Visible   //*[@class="pf-c-button pf-c-select__toggle-button pf-m-plain"]  timeout=20

Remove OpenShift Groups From Data Science User Groups
    [Documentation]   Remove OpenShift Groups From Data Science User Groups
    [Arguments]   @{user_groups}
    FOR    ${user_group}    IN    @{user_groups}
            Click Element     (//*[@class="pf-c-form__group-control"])[${2}]//*[@class="pf-c-chip__text" and contains(text(),"${user_groups}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Remove OpenShift Groups From Data Science Administrator Groups
    [Documentation]  Remove OpenShift Groups From Data Science Administrator Groups
    [Arguments]     @{admin_groups}
    FOR    ${admin_group}    IN    @{admin_groups}
            Click Button    (//*[@class="pf-c-form__group-control"])[${1}]//*[@class="pf-c-chip__text" and contains(text(),"${admin_group}")]//following-sibling::button[${1}]
    END
    Press Keys    None    ESC

Save Changes In User Management Setting
    [Documentation]  Save User management Settings
    Click Button    Save changes
    Sleep  60s

AdminGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]  @{UIadminGroupsList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=redhat-ods-applications  field_selector=metadata.name=odh-dashboard-config
    ${adminGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["adminGroups"]}
    @{adminGroupsList}  Split String  ${adminGroups}  ,
    Lists Should Be Equal      ${UIadminGroupsList}  ${adminGroupsList}

AllowedGroups In OdhDashboardConfig CRD Should Be
    [Documentation]  Verify Expect Changes Are Present In CRD
    [Arguments]   @{UIallowedGroupList}
    ${dashnoardConfig}   Oc Get   kind=OdhDashboardConfig   namespace=redhat-ods-applications  field_selector=metadata.name=odh-dashboard-config
    ${allowedGroups}  Set Variable  ${dashnoardConfig[0]["spec"]["groupsConfig"]["allowedGroups"]}
    @{allowedGroupsList}  Split String  ${allowedGroups}  ,
    Lists Should Be Equal      ${UIallowedGroupList}  ${allowedGroupsList}

Clear User Management Settings
    [Documentation]  Clear User Management Settings
    @{remove_users_list}  Get Webelements  (//*[@class="pf-c-form__group-control"])//*[@class="pf-c-chip__text" ]//following-sibling::button[1]
    FOR  ${user}   IN   @{remove_users_list}
        Click Button  (//*[@class="pf-c-form__group-control"])//*[@class="pf-c-chip__text" ]//following-sibling::button[1]
    END
