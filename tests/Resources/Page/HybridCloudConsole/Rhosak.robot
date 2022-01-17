*** Settings ***
Library         SeleniumLibrary
Resource        HCCLogin.robot
Resource        ../Components/Menu.robot
Library         OpenShiftCLI

*** Variables ***
${PERMISSION_GRID_XPATH_PREFIX}=  table[@aria-label='permission.table.table.permission_list_table']/tbody
${PERMISSION_GRID_BUTTON_XPATH_PREFIX}=  div/ul[@class='pf-c-select__menu']/li

*** Keywords ***
Create Kafka Stream Instance
  [Arguments]  ${stream_name}  ${stream_region}  ${cloud_provider}
  Click Button  Create Kafka instance
  Sleep  5
  Maybe Accept Cookie Policy
  Sleep  5
  Maybe Agree RH Terms and Conditions
  Wait Until Page Contains Element    xpath=//div[@id='modalCreateKafka']  timeout=10
  ${warn_msg}=  Run Keyword And Return Status    Page Should Not Contain    To deploy a new instance, delete your existing one first
  IF    ${warn_msg} == ${False}
     Log  level=ERROR  message=The next keywords are going to fail because you cannot create more than one stream at a time.
  END
  Input Text    xpath=//input[@id='form-instance-name']    ${stream_name}
  Click Element    xpath=//div[text()='${cloud_provider}']
  Click Element    id:form-cloud-region-option
  Select From List By Value    id:form-cloud-region-option   ${stream_region}
  Click Button    Create instance
  Capture Page Screenshot  form.png
  Wait Until Page Does Not Contain Element    xpath=//div[@id='modalCreateKafka']  timeout=10

Check Stream Status
  [Arguments]  ${target_status}  ${target_stream}
  ${status}=  Get Text    xpath=//tr[td[@data-label='Name' and (text()='${target_stream}' or *[text()='${target_stream}'])]]/td[@data-label='Status']
  Should Be Equal    ${status}    ${target_status}

Check Stream Creation
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready

Delete Kafka Stream Instance
  [Arguments]  ${stream_name}
  Click From Actions Menu  search_col=Name  search_value=${stream_name}  action=Delete
  Wait Until Page Contains HCC Generic Modal
  Capture Page Screenshot  1.png
  Input Text    id:name__input   ${stream_name}
  Capture Page Screenshot  2.png
  Wait Until Element Is Enabled    xpath=//button[text()='Delete']
  Capture Page Screenshot  3.png
  Click Button    Delete
  Wait Until Page Does Not Contain Element    xpath=//div[@class='pf-l-bullseye']
  Sleep  3
  Wait Until Page Contains    Create Kafka instance
  Wait Until Keyword Succeeds    300  1  Page Should Not Contain Element    xpath=//tr/td[@data-label='Name' and (text()='${stream_name}' or *[text()='${stream_name}'])]

Create Topic
  [Arguments]  ${topic_name_to_create}
  Click Button  Create topic
  Wait For HCC Splash Page
  Input Text  name:step-topic-name  ${topic_name_to_create}
  Click Button   Next
  Wait Until Page Contains Element  xpath=//h2[text()='Partitions']
  Click Button   Next
  Wait Until Page Contains Element  xpath=//h2[text()='Message retention']
  Click Button   Next
  Wait Until Page Contains Element    xpath=//button[text()='Finish']
  Click Button   Finish
  Wait For HCC Splash Page

Create Service Account From Connection Menu
  [Arguments]  ${sa_description}
  Wait Until Element Is Visible    xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
  Click Button  xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
  Wait Until Page Contains Element    xpath=//div[@id='modalCreateSAccount']
  Input Text  xpath=//input[@id='text-input-short-description']  ${sa_description}
  Click Button  Create
  Wait Until Page Contains  Credentials successfully generated
  ${kafka_client_id}=  Get Element Attribute  xpath=//input[@aria-label='Client ID']  value
  ${kafka_client_secret}=  Get Element Attribute  xpath=//input[@aria-label='Client secret']  value
  &{service_account_creds}=  Create Dictionary  kafka_client_id=${kafka_client_id}  kafka_client_secret=${kafka_client_secret}
  Select Checkbox    xpath=//input[@class='pf-c-check__input']
  Wait Until Element Is Enabled    xpath=//button[@data-testid='modalCredentials-buttonClose']
  Click Button  xpath=//button[@data-testid='modalCredentials-buttonClose']
  Wait Until Element Is Not Visible    xpath=//div[@class='pf-l-bullseye']
  [Return]  &{service_account_creds}

Assign Permissions To ServiceAccount in RHOSAK
  [Arguments]  ${sa_client_id}  ${sa_to_assign}  ${topic_to_assign}  ${cg_to_assign}

  &{topic_read_permissions}=  Create Dictionary  resource_name=Topic  search_type=Is  name_text=${topic_to_assign}  permissions_value=Read
  &{topic_write_permissions}=  Create Dictionary  resource_name=Topic  search_type=Is  name_text=${topic_to_assign}  permissions_value=Write
  &{cg_permissions}=  Create Dictionary  resource_name=Consumer group  search_type=Is  name_text=${cg_to_assign}  permissions_value=Read
  &{permissions_grid}=  Create Dictionary  row1=&{topic_read_permissions}  row2=&{topic_write_permissions}  row3=&{cg_permissions}

  ${permissions_items}     Get Dictionary Items   ${permissions_grid}

  FOR    ${index}    ${row_n}   ${resource_dict}  IN ENUMERATE    @{permissions_items}  start=1
      Click Button  Manage access
      Wait Until Page Contains Element  xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//input[@aria-label='Select an account']
      Sleep  1
      Input Text  xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//input[@aria-label='Select an account']   ${sa_to_assign}
      Click Element   xpath=//div[(@id='manage-permissions-modal') and (@class='pf-c-modal-box__body')]/form//div[@class='pf-c-select__menu']/li/button/span[text()='${sa_client_id}']
      Wait Until Element Is Enabled  xpath=//button[text()='Next']
      Click Button  Next
      Wait Until Page Contains  Assign permissions

      ${resource}=  Set Variable  ${resource_dict}[resource_name]
      ${searchtype}=  Set Variable  ${resource_dict}[search_type]
      ${nametext}=  Set Variable  ${resource_dict}[name_text]
      ${permissionvalue}=  Set Variable  ${resource_dict}[permissions_value]

      ${index}=  Set Variable  1
      Click Element  xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[@data-label='Resource']//button[@aria-label='Options menu']
      Wait Until Page Contains Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${resource}']
      Click Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${resource}']

      Click Element  xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[@data-key='1']//button[@aria-label='Options menu']
      Wait Until Page Contains Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button/span[text()='${searchtype}']
      Click Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button/span[text()='${searchtype}']

      Input Text  xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]//input[@aria-label='permission.manage_permissions_dialog.assign_permissions.resource_name_aria']  ${nametext}

      Click Element  xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[@data-key='4']/div[contains(@class, 'f-u-display-flex')]/div//button[@aria-label='Options menu']
      Click Element  xpath=//${PERMISSION_GRID_XPATH_PREFIX}/tr[${index}]/td[@data-key='4']/div[contains(@class, 'f-u-display-flex')]/div//button[@aria-label='Options menu']
      Wait Until Page Contains Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${permissionvalue}']
      Click Element  xpath=//${PERMISSION_GRID_BUTTON_XPATH_PREFIX}/button[text()='${permissionvalue}']

      Click Button    Save
      Wait Until Page Does Not Contain Element   xpath=//div[(@id='manage-permissions-modal')]
  END

Enter Stream
  [Arguments]  ${stream_name}
  Wait Until Page Contains Element  xpath=//a[text()='${stream_name}']
  Click Link    xpath=//a[text()='${stream_name}']
  Wait For HCC Splash Page

Enter Stream ${sec_title} Section
  Click Button    xpath=//button[@aria-label='${sec_title}']
  Wait For HCC Splash Page

Click From Actions Menu
  [Arguments]  ${search_col}  ${search_value}  ${action}
  ${SEARCH_ROW_PATH}=  Set Variable  //tr[td[@data-label='${search_col}' and (text()='${search_value}' or *[text()='${search_value}'])]]
  ${SIDE_BUTTON_PATH}=  Set Variable  ${SEARCH_ROW_PATH}/td[contains(@class, 'pf-c-table__action')]
  ${ACTION_MENU_PATH}=  Set Variable  ${SIDE_BUTTON_PATH}//button[@aria-label='Actions']
  ${TARGET_ACTION_PATH}=  Set Variable  ${SIDE_BUTTON_PATH}//button[text()='${action}']
  Wait Until Page Contains Element    xpath=${ACTION_MENU_PATH}
  Click Button    xpath=${ACTION_MENU_PATH}
  Capture Page Screenshot  sa_action.png
  Sleep  3
  Wait Until Page Contains Element    xpath=${TARGET_ACTION_PATH}
  Click Button    xpath=${TARGET_ACTION_PATH}

Delete Stream Topic
  [Arguments]   ${topic_to_delete}
  Click From Actions Menu  search_col=Name  search_value=${topic_to_delete}  action=Delete
  Wait Until Page Contains HCC Generic Modal
  Input Text    id:delete-text-input   DELETE
  Click Button  Delete
  Capture Page Screenshot  deleting_inside_modal.png
  Wait Until Page Does Not Contains HCC Generic Modal
  Capture Page Screenshot  deleting_after_modal.png
  Wait Until Page Contains    Create topic
  Wait Until Keyword Succeeds    300  1  Page Should Not Contain Element    xpath=//tr/td[@data-label='Name' and *[text()='${topic_to_delete}']]
  Capture Page Screenshot  deletion_topic.png

Delete Service Account By Client ID
  [Arguments]  ${client_id_delete}
  Click From Actions Menu  search_col=Client ID  search_value=${client_id_delete}  action=Delete service account
  Wait Until Page Contains HCC Generic Modal
  Click Button  Delete
  Wait Until Page Does Not Contains HCC Generic Modal
  Wait Until Page Contains    Create service account
  Wait Until Keyword Succeeds    300  1  Page Should Not Contain Element    xpath=//tr/td[@data-label='Client ID' and text()='${client_id_delete}']


Clean Up RHOSAK
  [Arguments]  ${stream_to_delete}  ${topic_to_delete}  ${sa_clientid_to_delete}
  OpenShiftCLI.Delete      kind=ConfigMap  name=rhosak-validation-result  namespace=redhat-ods-applications
  Switch Window  title:Red Hat OpenShift Streams for Apache Kafka
  Menu.Navigate To Page    Streams for Apache Kafka   Kafka Instances
  Enter Stream  stream_name=${stream_to_delete}
  Enter Stream Topics Section
  Delete Stream Topic  topic_to_delete=${topic_to_delete}
  Menu.Navigate To Page    Streams for Apache Kafka   Kafka Instances
  Wait For HCC Splash Page
  Wait Until Page Contains    Create Kafka instance
  Delete Kafka Stream Instance  stream_name=${stream_to_delete}
  Capture Page Screenshot  after deleting_stream.png
  Click Link  Service Accounts
  Delete Service Account By Client ID  client_id_delete=${sa_clientid_to_delete}
