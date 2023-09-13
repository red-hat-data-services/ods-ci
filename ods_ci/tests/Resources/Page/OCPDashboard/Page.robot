*** Settings ***
Resource    ../Components/Menu.robot
Resource    ../../Common.robot
Library     SeleniumLibrary

*** Keywords ***
Open Page
  [Arguments]  ${url}
  Open Browser  ${url}
  ...           browser=${BROWSER.NAME}
  ...           options=${BROWSER.OPTIONS}
  Page Should be Open  ${url}

Page Should Be Open
  [Arguments]  ${url}

  ${status}       Run keyword and Return Status      Location Should Contain  ${url}
  ${new_url}       Remove string    ${url}         https://
  IF   ${status} == ${False}    Location Should Contain  ${new_url}


Maybe Click Show Default Project Button
  ${switch_button}=  Run Keyword And Return Status    Page Should Contain Element    xpath=//input[@data-test='showSystemSwitch']
  IF    ${switch_button} == True
     ${switch_status}=  Get Element Attribute    xpath=//input[@data-test='showSystemSwitch']    data-checked-state
     IF    '${switch_status}' == 'false'
          Click Element    xpath=//input[@data-test='showSystemSwitch']
     END
  END

Create Project
    [Documentation]     Creates a project in OCP Console.
    [Arguments]  ${project_name}
    Menu.Navigate To Page   Home    Projects
    Click Button    xpath://button[@id="yaml-create"]
    Input Text      xpath://input[@id="input-name"]     ${project_name}
    Click Button    xpath://button[@id="confirm-action"]

Select Project By Name
  [Arguments]  ${project_name}
  Wait Until Page Contains Element    xpath://div[@data-test-id='namespace-bar-dropdown']/div/div/button
  Click Element    xpath://div[@data-test-id='namespace-bar-dropdown']/div/div/button
  Wait Until Page Contains Element  xpath://div[@data-test-id='namespace-bar-dropdown']//li
  Maybe Click Show Default Project Button
  Click Element    xpath://div[@data-test-id='namespace-bar-dropdown']//li//*[text()='${project_name}']

Search Last Item Instance By Title in OpenShift Table
  [Arguments]  ${search_term}  ${namespace}=All Projects
  Select Project By Name    ${namespace}
  Wait Until Page Contains Element    xpath://input[@data-test='name-filter-input']
  Clear Element Text    xpath://input[@data-test='name-filter-input']
  Input Text    xpath://input[@data-test='name-filter-input']    ${search_term}
  Sleep  2
  Wait Until Page Contains Element    xpath://a[contains(., "${search_term}")]
  Click Button    xpath://*/th[@data-label='Created']/button  # asc order
  Click Button    xpath://*/th[@data-label='Created']/button  # desc order

Delete Project By Name
  [Documentation]       Deletes a project in OCP Console.
  [Arguments]  ${project_name}
  Menu.Navigate To Page   Home    Projects
  Wait Until Page Contains Element      //input[@data-test-id="item-filter"]
  Input Text    //input[@data-test-id="item-filter"]    ${project_name}
  Sleep     5
  Click Button      //button[@class="pf-c-dropdown__toggle pf-m-plain"]
  Sleep     5
  Click Button      //button[@data-test-action="Delete Project"]
  Wait Until Page Contains Element      //div[@class="modal-header"]    10
  Input Text    //input[@data-test="project-name-input"]    ${project_name}
  Click Button  //button[@data-test="confirm-action"]

Select Last Item Instance By Title In OpenShift Table
    [Documentation]    Searches last item instance and clicks on it
    [Arguments]    ${search_term}    ${namespace}=All Projects
    Search Last Item Instance By Title In OpenShift Table    ${search_term}    ${namespace}
    Click Link    xpath://a[contains(., "${search_term}")]
