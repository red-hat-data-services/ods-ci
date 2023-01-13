*** Settings ***
Documentation   Collection of keywords to interact with RHOSAK
Library         SeleniumLibrary
Library         OpenShiftLibrary
Resource        HCCLogin.robot
Resource        ../Components/Menu.robot
Resource        ../ODH/ODHDashboard/ODHDashboard.robot
Resource        ../ODH/AiApps/Rhosak.robot


*** Variables ***
# ${PERMISSION_GRID_XPATH_PREFIX}=    table[@aria-label='permission.table.table.permission_list_table']/tbody
${PERMISSION_GRID_XPATH_PREFIX}=            table[contains(@class,'pf-m-grid-md')]/tbody
${PERMISSION_GRID_BUTTON_XPATH_PREFIX}=     div/ul[@class='pf-c-select__menu']/li
${CONFIRM_WARNING_XP}=   //div[(contains(@class, "modal")) and (contains(@class, "warning"))]
${CONFIRM_WARNING_FIRST_BUTTON_XP}=   ${CONFIRM_WARNING_XP}//button[contains(@class, "pf-m-primary")]


*** Keywords ***
Create Kafka Stream Instance
    [Documentation]    Creates a kafka stream from RHOSAK UI
    [Arguments]    ${stream_name}    ${stream_region}    ${cloud_provider}
    Click Button    Create Kafka instance
    Sleep    5
    Maybe Accept Cookie Policy
    Sleep    5
    Maybe Agree RH Terms And Conditions
    Wait Until Page Contains Element    xpath=//div[@id='modalCreateKafka']    timeout=10
    ${warn_msg}=    Run Keyword And Return Status    Page Should Not Contain
    ...    To deploy a new instance, delete your existing one first
    IF    ${warn_msg} == ${False}
        Log    level=ERROR    message=The next keywords will fail because you cannot create more than one stream.
    END
    Wait Until Element Is Enabled    xpath=//input[@id='form-instance-name']
    Input Text    xpath=//input[@id='form-instance-name']    ${stream_name}
    Click Element    xpath=//div[text()='${cloud_provider}']
    Click Element    id:form-cloud-region-option
    Click Element    xpath=//li/*[text()="${stream_region}"]
    Sleep  2s
    Click Button    Create instance
    Capture Page Screenshot    form.png
    Wait Until Page Does Not Contain Element    xpath=//div[@id='modalCreateKafka']    timeout=20

Check Stream Status
    [Documentation]    Cehcks the kafka stream status from RHOSAK UI
    [Arguments]    ${target_status}    ${target_stream}
    ${status}=    Get Text
    ...    xpath=//tr[td[@data-label='Name' and (text()='${target_stream}' or *[text()='${target_stream}'])]]/td[@data-label='Status']
    Should Be Equal    ${status}    ${target_status}

Check Stream Creation
    [Documentation]    Continuosly checks a kafka stream from RHOSAK UI
    Wait Until Keyword Succeeds    300    1    Check Stream Status    Ready

Delete Kafka Stream Instance
    [Documentation]    Deletes a kafka stream from RHOSAK UI
    [Arguments]    ${stream_name}
    Click From Actions Menu    search_col=Name    search_value=${stream_name}    action=Delete instance
    Wait Until Page Contains HCC Generic Modal
    Capture Page Screenshot    1.png
    Input Text    id:name__input    ${stream_name}
    Capture Page Screenshot    2.png
    Wait Until Element Is Enabled    xpath=//button[text()='Delete']
    Capture Page Screenshot    3.png
    Click Button    Delete
    Wait Until Page Does Not Contain Element    xpath=//div[@class='pf-l-bullseye']
    Sleep    3
    Wait Until Page Contains    Create Kafka instance
    Wait Until Keyword Succeeds    300    1    Page Should Not Contain Element
    ...    xpath=//tr/td[@data-label='Name' and (text()='${stream_name}' or *[text()='${stream_name}'])]

Create Topic
    [Documentation]    Creates a topic in a kafka stream from RHOSAK UI
    [Arguments]    ${topic_name_to_create}
    Click Button    Create topic
    Run Keyword And Ignore Error    Wait For HCC Splash Page
    Input Text    name:step-topic-name    ${topic_name_to_create}
    Click Button    Next
    Wait Until Page Contains Element    xpath=//h2[text()='Partitions']
    Click Button    Next
    Wait Until Page Contains Element    xpath=//h2[text()='Message retention']
    Click Button    Next
    Wait Until Page Contains Element    xpath=//button[text()='Finish']
    Click Button    Finish
    Run Keyword And Ignore Error    Wait For HCC Splash Page

Create Service Account From Connection Menu
    [Documentation]    Creates a service account (SA) from RHOSAK UI
    [Arguments]    ${sa_description}
    Wait Until Element Is Visible
    ...    xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
    Click Button
    ...    xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
    Wait Until Page Contains Element    xpath=//div[@id='modalCreateSAccount']
    Input Text    xpath=//input[@id='text-input-short-description']    ${sa_description}
    Click Button    Create
    Wait Until Page Contains    Credentials successfully generated
    ${KAFKA_CLIENT_ID}=    Get Element Attribute    xpath=//input[@aria-label='Client ID']    value
    ${KAFKA_CLIENT_SECRET}=    Get Element Attribute    xpath=//input[@aria-label='Client secret']    value
    &{service_account_creds}=    Create Dictionary    KAFKA_CLIENT_ID=${KAFKA_CLIENT_ID}
    ...                                               KAFKA_CLIENT_SECRET=${KAFKA_CLIENT_SECRET}
    Select Checkbox    xpath=//input[@class='pf-c-check__input']
    Wait Until Element Is Enabled    xpath=//button[@data-testid='modalCredentials-buttonClose']
    Click Button    xpath=//button[@data-testid='modalCredentials-buttonClose']
    Wait Until Element Is Not Visible    xpath=//div[@class='pf-l-bullseye']
    RETURN    &{service_account_creds}

Assign Permissions To ServiceAccount In RHOSAK
    [Documentation]    Configures the SA's permission on a kafka stream from RHOSAK UI
    [Arguments]    ${sa_client_id}    ${sa_to_assign}    ${topic_to_assign}    ${cg_to_assign}
    Reload Page
    Run Keyword And Ignore Error    Wait For HCC Splash Page
    Wait Until Page Contains Element    xpath://button[text()='Manage access']
    &{topic_read_permissions}=    Create Dictionary    resource_name=Topic    search_type=Is
    ...    name_text=${topic_to_assign}    permissions_value=Read
    &{topic_write_permissions}=    Create Dictionary    resource_name=Topic    search_type=Is
    ...    name_text=${topic_to_assign}    permissions_value=Write
    &{cg_permissions}=    Create Dictionary    resource_name=Consumer group    search_type=Is
    ...    name_text=${cg_to_assign}    permissions_value=Read
    &{permissions_grid}=    Create Dictionary    row1=&{topic_read_permissions}    row2=&{topic_write_permissions}
    ...    row3=&{cg_permissions}

    ${permissions_items}=    Get Dictionary Items    ${permissions_grid}

    FOR    ${index}    ${row_n}    ${resource_dict}    IN ENUMERATE    @{permissions_items}    start=1
        Click Button    Manage access
        Wait Until Page Contains Element
        ...    xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//input[@aria-label='Select an account']
        Sleep    1
        Input Text
        ...    xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//input[@aria-label='Select an account']
        ...    ${sa_to_assign}
        Click Element
        ...    xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//div[@class='pf-c-select__menu']/li/button/span[text()='${sa_client_id}']
        Wait Until Element Is Enabled    xpath=//button[text()='Next']
        Click Button    Next
        Run Keyword And Ignore Error    Wait For HCC Splash Page
        Wait Until Page Contains    Assign permissions
        Wait Until Page Contains Element    xpath://button[text()='Add permission']
        Click Button    Add permission

        ${resource}=    Set Variable    ${resource_dict}[resource_name]
        ${searchtype}=    Set Variable    ${resource_dict}[search_type]
        ${nametext}=    Set Variable    ${resource_dict}[name_text]
        ${permissionvalue}=    Set Variable    ${resource_dict}[permissions_value]

        ${index}=    Set Variable    1
        Wait Until Page Contains Element    xpath=//${PERMISSION_GRID_XPATH_PREFIX}
        Click Element    xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[1]//button[@aria-label='Options menu']
        Wait Until Page Contains Element    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${resource}']
        Click Element    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${resource}']

        Click Element    xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[2]//button[@aria-label='Options menu']
        Wait Until Page Contains Element
        ...    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button/span[text()='${searchtype}']
        Click Element    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button/span[text()='${searchtype}']

        Input Text
        ...    xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]//input[@aria-label='permission.manage_permissions_dialog.assign_permissions.resource_name_aria']
        ...    ${nametext}

        Click Element
        ...    xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[5]/div//button[@aria-label='Options menu']
        Wait Until Page Contains Element
        ...    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${permissionvalue}']
        Click Element    xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${permissionvalue}']

        Click Button    Save
        Wait Until Page Does Not Contain Element    xpath=//div[(@id='manage-permissions-modal')]
    END

Enter Stream
    [Documentation]    Moves inside the kafka stream page from RHOSAK UI
    [Arguments]    ${stream_name}
    Wait Until Page Contains Element    xpath=//a[text()='${stream_name}']
    Click Link    xpath=//a[text()='${stream_name}']
    Run Keyword And Ignore Error    Wait For HCC Splash Page

Enter Stream ${sec Title} Section
    [Documentation]    Keyword to navigate inside kafka stream page from RHOSAK UI
    Click Button    xpath=//button[@aria-label='${sec_title}']
    Run Keyword And Ignore Error    Wait For HCC Splash Page

Click From Actions Menu
    [Documentation]    Clicks button from actions menu of a kafka stream from RHOSAK UI
    [Arguments]    ${search_col}    ${search_value}    ${action}
    ${SEARCH_ROW_PATH}=    Set Variable
    ...    //tr[td[@data-label='${search_col}' and (text()='${search_value}' or *[text()='${search_value}'])]]
    ${SIDE_BUTTON_PATH}=    Set Variable    ${SEARCH_ROW_PATH}/td[contains(@class, 'pf-c-table__action')]
    ${ACTION_MENU_PATH}=    Set Variable    ${SIDE_BUTTON_PATH}//button[@aria-label='Actions']
    ${TARGET_ACTION_PATH}=    Set Variable    ${SIDE_BUTTON_PATH}//button[text()='${action}']
    Wait Until Page Contains Element    xpath=${ACTION_MENU_PATH}
    Click Button    xpath=${ACTION_MENU_PATH}
    Capture Page Screenshot    sa_action.png
    Sleep    3
    Wait Until Page Contains Element    xpath=${TARGET_ACTION_PATH}
    Click Button    xpath=${TARGET_ACTION_PATH}

Delete Stream Topic
    [Documentation]    Deletes a topic in a kafka stream from RHOSAK UI
    [Arguments]    ${topic_to_delete}
    Click From Actions Menu    search_col=Name    search_value=${topic_to_delete}    action=Delete
    Wait Until Page Contains HCC Generic Modal
    Input Text    id:delete-text-input    DELETE
    Click Button    Delete
    Capture Page Screenshot    deleting_inside_modal.png
    Wait Until Page Does Not Contains HCC Generic Modal
    Capture Page Screenshot    deleting_after_modal.png
    Wait Until Page Contains    Create topic
    Wait Until Keyword Succeeds    300    1    Page Should Not Contain Element
    ...    xpath=//tr/td[@data-label='Name' and *[text()='${topic_to_delete}']]
    Capture Page Screenshot    deletion_topic.png

Delete Service Account By Client ID
    [Documentation]    Deletes a SA from RHOSAK UI
    [Arguments]    ${client_id_delete}
    Click From Actions Menu    search_col=Client ID    search_value=${client_id_delete}    action=Delete service account
    Wait Until Page Contains HCC Generic Modal
    Click Button    Delete
    Wait Until Page Does Not Contains HCC Generic Modal
    Wait Until Page Contains    Create service account
    Wait Until Keyword Succeeds    300    1    Page Should Not Contain Element
    ...    xpath=//tr/td[@data-label='Client ID' and text()='${client_id_delete}']

Clean Up RHOSAK
    [Documentation]    Cleans up all the RHOSAK created resources from RHOSAK and RHODS UI
    [Arguments]    ${stream_to_delete}    ${topic_to_delete}    ${sa_clientid_to_delete}  ${rhosak_app_id}
    ${window_title}=    Get Title
    IF    $window_title == "Streams for Apache Kafka | Red Hat OpenShift Application Services" or $window_title == "Red Hat OpenShift Streams for Apache Kafka"
        Maybe Skip RHOSAK Tour
        ${modal_exists}=     Run Keyword And Return Status   Wait Until Page Contains Element    xpath=//*[contains(@class, "modal")]
        IF    ${modal_exists}==${TRUE}
           Click Button    xpath=//button[@aria-label="Close"]
           ${confirm_exists}=     Run Keyword And Return Status   Wait Until Page Contains Element    xpath=${CONFIRM_WARNING_XP}
           IF    ${confirm_exists}==${TRUE}
                Click Button   xpath=${CONFIRM_WARNING_FIRST_BUTTON_XP}
           END
        END
    ELSE
        Switch Window    title:Red Hat OpenShift Streams for Apache Kafka
    END
    Oc Delete    kind=ConfigMap    name=rhosak-validation-result    namespace=redhat-ods-applications
    Menu.Navigate To Page    Streams for Apache Kafka    Kafka Instances
    Enter Stream    stream_name=${stream_to_delete}
    Enter Stream Topics Section
    Delete Stream Topic    topic_to_delete=${topic_to_delete}
    Menu.Navigate To Page    Streams for Apache Kafka    Kafka Instances
    Run Keyword And Ignore Error    Wait For HCC Splash Page
    Wait Until Page Contains    Create Kafka instance
    Delete Kafka Stream Instance    stream_name=${stream_to_delete}
    Capture Page Screenshot    after deleting_stream.png
    Click Link    Service Accounts
    Run Keyword And Ignore Error    Wait For HCC Splash Page
    Maybe Skip RHOSAK Tour
    Delete Service Account By Client ID    client_id_delete=${sa_clientid_to_delete}
    Close All Browsers
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}  ocp_user_auth_type=${TEST_USER.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page   app_id=${rhosak_app_id}
