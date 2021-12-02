*** Settings ***
Library         SeleniumLibrary
Resource        HCCLogin.robot


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
     Log  level=WARN  message=The next keywords are going to fail because you cannot create more than one stream at a time.
  END
  Input Text    xpath=//input[@id='form-instance-name']    ${stream_name}
  Click Element    xpath=//div[text()='${cloud_provider}']
  Select From List By Value    id:cloud-region-select   ${stream_region}
  Click Button    Create instance
  Capture Page Screenshot  form.png

Check Stream Status
  [Arguments]  ${target_status}
  ${status}=  Get Text    xpath://tr[@tabindex='0']/td[@data-label='Status']
  Should Be Equal    ${status}    ${target_status}

Check Stream Creation
  Wait Until Keyword Succeeds    300  1  Check Stream Status  Ready

Delete Kafka Stream Instance
  [Arguments]  ${stream_name}  ${stream_owner}
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='Delete']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='Delete']
  Wait Until Page Contains Element    xpath=//div[contains(@id, 'pf-modal-part')]
  Input Text    id:name__input   ${stream_name}
  Click Button    Delete

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

Click ${action} Submenu From Actions Menu
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/button[@aria-label='Actions']
  Wait Until Page Contains Element    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='${action}']
  Click Button    xpath=//tr[@tabindex='0']/td[contains(@class, 'pf-c-table__action')]/div/ul/li/button[text()='${action}']

Create Service Account From Connection Menu
  [Arguments]  ${sa_description}
  # Set Log Level    NONE
  Wait Until Page Contains Element    xpath=//section[contains(@id, 'pf-tab-section-connection')]/div/button[text()='Create service account']
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
      Wait Until Page Contains Element  xpath=//button[text()='Manage access']
  END
