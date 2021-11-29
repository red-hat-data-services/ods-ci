*** Settings ***
Library    OpenShiftCLI
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***
Get Build Status
  [Arguments]  ${namespace}  ${build_search_term}
  Navigate To Page    Builds    Builds
  Search Last Item Instance By Title in OpenShift Table  search_term=${build_search_term}  namespace=${namespace}
  ${build_status}=  Get Text    xpath://tr[@data-id='0-0']/td/*/span[@data-test='status-text']
  [Return]  ${build_status}

Delete BuildConfig using Name
    [Arguments]    ${namespace}                    ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    Run Keyword If          '${status}'=='PASS'   OpenShiftCLI.Delete  kind=BuildConfig   name=${name}   namespace=${namespace}
    ...        ELSE          FAIL        No BuildConfig present with name '${name}' in '${namespace}' namespace, Check the BuildConfig name and namespace provide is correct and try again
    Dependent Build should not Present     ${name}
    ${status}      Check If BuildConfig Exists    ${namespace}      ${name}
    Run Keyword IF          '${status}'!='FAIL'     FAIL       BuildConfig with name '${name}' is not deleted in '${namespace}'

Check If BuildConfig Exists
    [Arguments]    ${namespace}      ${name}
    ${status}   ${val}  Run keyword and Ignore Error   OpenShiftCLI.Get  kind=BuildConfig  namespace=${namespace}     field_selector=metadata.name==${name}
    [Return]   ${status}

Dependent Build should not Present
     [Arguments]     ${selector}
     ${isExist}      Run Keyword and Return Status          OpenShiftCLI.Get     kind=Build    label_selector=buildconfig=${selector}
     Run Keyword IF     not ${isExist}        Log    Build attached to Build config has been deleted
     ...        ELSE    FAIL       Attached Build to Build config is not deleted


