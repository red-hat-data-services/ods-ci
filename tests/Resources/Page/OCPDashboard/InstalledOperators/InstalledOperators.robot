*** Settings ***
Library  SeleniumLibrary
Library  OpenShiftCLI
Library  OperatingSystem
Library  String
Library  ../../../../libs/Helpers.py

*** Variables ***
@{verification_list}           beta   preview   stage

*** Keywords ***
Uninstall Operator
  [Arguments]    ${operator}
  ${is_all_projects_selected} =  Is All Projects Selected
  Run Keyword Unless  ${is_all_projects_selected}
  ...                 Select All Projects
  Search Installed Operator  ${operator}
  ${is_operator_installed} =  Is Operator Installed  ${operator}
  Run Keyword Unless  ${is_operator_installed}
  ...                 Pass execution  ${operator}  operator is not installed
  Expand Installed Operator Menu  ${operator}
  Click Uninstall Operator
  Confirm Uninstall
  Wait Until Uninstallation Completes  ${operator}

Is All Projects Selected
  ${is_selected} =  Run Keyword And Return Status
  ...               Page Should Contain  Project: All Projects
  [Return]  ${is_selected}

Select All Projects
  Click Element  //div[@data-test-id="namespace-bar-dropdown"]/div
  Wait Until Element is Visible  //*[contains(text(), "All Projects")]
  Click Element  //*[contains(text(), "All Projects")]

Search Installed Operator
  [Arguments]  ${operator}
  Wait Until Element is Visible  //input[@data-test-id="item-filter"]  timeout=150
  Input text  //input[@data-test-id="item-filter"]  ${operator}

Is Operator Installed
  [Arguments]  ${operator}
  Run Keyword and Return Status     Wait Until Element is Visible      //a[@data-test-operator-row="${operator}"]    timeout=10
  ${is_installed} =  Run Keyword and Return Status
  ...                Get WebElement  //a[@data-test-operator-row="${operator}"]
  [Return]  ${is_installed}

Expand Installed Operator Menu
  [Arguments]  ${operator}
  Set Local Variable  ${operator_row}  //a[@data-test-operator-row="${operator}"]/../..
  Set Local Variable  ${operator_menu}  ${operator_row}//button[@data-test-id="kebab-button"]
  ${is_operator_menu_expanded} =  Is Installed Operator Menu Expanded  ${operator_menu}
  Run Keyword if  "${is_operator_menu_expanded}" == "false"
  ...             Click Element  ${operator_menu}

Is Installed Operator Menu Expanded
  [Arguments]  ${menu}
  ${is_expanded} =  Get Element Attribute  ${menu}  attribute=aria-expanded
  [Return]  ${is_expanded}

Click Uninstall Operator
  Press Keys  //button[@data-test-action="Uninstall Operator"]  RETURN

Confirm Uninstall
  Click Button  //button[@data-test="confirm-action"]

Wait Until Uninstallation Completes
  [Arguments]  ${operator}
  Wait Until Page Does Not Contain Element  //a[@data-test-operator-row="${operator}"]  timeout=50

Operator Should Be Uninstalled
  [Arguments]  ${operator}
  Page Should Not Contain Element  //a[@data-test-operator-row="${operator}"]


Switch To New Tab
    [Arguments]  ${tabname}
     Click Element        //a[contains(text(), "${tabname}")]

Click On Searched Operator
    [Arguments]   ${operator}
     Search Installed Operator          ${operator}
     Wait Until Element is Visible     xpath=//a[@data-test-operator-row="${operator}"]    timeout=10
     Click Element       xpath=//a[@data-test-operator-row="${operator}"]
     Wait until page contains           Description           timeout=10

Check IF URL On The Page Is Commercial
    [Arguments]  ${url}
     FOR  ${value}  IN   @{verification_list}
          Run keyword If       $value in $url     FAIL    URL doesn't look like commerial it contain '${value}' in it
     END

Get RHODS version
    #@{list} =  OpenShiftCLI.Get  kind=ClusterServiceVersion  label_selector=olm.copiedFrom=redhat-ods-operator
    #&{dict} =  Set Variable  ${list}[0]
    #Log  ${dict.spec.version}
    ${ver} =  Run  oc get csv -n redhat-ods-operator | grep "rhods-operator" | awk '{print $1}' | sed 's/rhods-operator.//'
    ${ver} =  Fetch From Left  ${ver}  -
    Log  ${ver}
    [Return]  ${ver}

Is RHODS Version Greater Or Equal Than
    [Arguments]  ${target}
    ${ver} =  Get RHODS version
    ${comparison} =  GTE  ${ver}  ${target}
    [Return]  ${comparison}

Move To Installed Operator Page Tab in Openshift
    [Documentation]   This keyword help move to any tab name present inside any installed operator
    [Arguments]   ${operator_name}     ${tab_name}      ${namespace}
    Switch To Administrator Perspective
    Navigate to Installed Operators
    Installed Operators Should Be Open
    Run Keyword If  "${namespace}" == "None"   Select Project By Name  All Projects
    ...         ELSE   Select Project By Name   ${namespace}
    Click On Searched Operator   ${operator_name}
    Switch To New Tab       ${tab_name}
    sleep    5

Create Tabname Instance For Installed Operator
    [Documentation]   This keyword check and create instance(notebook ,Imagestream etc)
    ...               for installed operator in openshift if not cretaed
    [Arguments]    ${operator_name}     ${tab_name}     ${namespace}=None
    Move To Installed Operator Page Tab in Openshift    ${operator_name}     ${tab_name}    ${namespace}
    ${is_created} =  Run Keyword and Return Status
    ...                Get WebElement  //table[contains(@class,"ReactVirtualized")]//tr
    Capture Page Screenshot
    IF  not ${is_created}
        Click Button     Create ${tab_name}
        Wait Until Element is Visible     //button[contains(text(), "Create")]          timeout=10
        Click Button      Create
        Wait Until Element Is Visible    //table[contains(@class,"ReactVirtualized")]//tr     timeout=10
    END

Delete Tabname Instance For Installed Operator
    [Documentation]   This keyword delete the instance(notebook ,Imagestream instance etc) created for installed operator in openshift
    [Arguments]    ${operator_name}     ${tab_name}     ${namespace}=None
    Move To Installed Operator Page Tab in Openshift    ${operator_name}     ${tab_name}      ${namespace}
    Wait Until Element is Visible          //button[contains(@data-test-id,"kebab")]          timeout=10
    Click Element   //button[contains(@data-test-id,"kebab")]
    Wait Until Element Is Enabled     //button[contains(text(),"Delete ${tab_name}")]
    Click Element   //button[contains(text(),"Delete ${tab_name}")]
    Wait Until Element Is Enabled   //button[contains(text(),"Delete")]
    Click Button    Delete

Check If Operator Is Already Installed In Opneshift
    [Documentation]   This keyword verify if operator is already installed and return the status
    [Arguments]    ${operator_name}
    Open Installed Operators Page
    Search Installed Operator    ${operator_name}
    ${status}   Is Operator Installed        ${operator_name}
    Run Keyword If  ${status}   Log To Console    Operator "${operator_name}" is already installed
    [Return]  ${status}

Check And Install Operator in Openshift
    [Documentation]   This keyword verify if operator is already installed or not
    ...               If not installed it matched the no of operator present and installs the operator
    [Arguments]       ${operator_name}    ${operator_appname}   ${expected_number_operator}=2
    ${status}       Check If Operator Is Already Installed In Opneshift    ${operator_name}
    IF  not ${status}
        Open OperatorHub
        ${actual_no_of_operator}    Get The Number of Operator Available    ${operator_appname}
        IF  ${actual_no_of_operator} == ${expected_number_operator}
            Install Operator      ${operator_appname}
        ELSE
            FAIL      Only ${actual_no_of_operator} ${operator_name} is found in Opearatorhub

        END
    END