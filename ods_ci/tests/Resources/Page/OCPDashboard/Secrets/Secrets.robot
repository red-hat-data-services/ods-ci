*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}
    ${status}     Check If Secrets Exists      ${namespace}      ${secret_name}
    IF          '${status}'=='PASS'   Oc Delete   kind=Secret   name=${secret_name}   namespace=${namespace}
    ...        ELSE      FAIL        No secrets present with name '${secret_name}' in '${namespace}' namespace, Check the secret name and namespace provide is correct and try again
    ${status}      Check If Secrets Exists      ${namespace}      ${secret_name}
    IF          '${status}'!='FAIL'     FAIL        Secret with name '${secret_name}' is not deleted in '${namespace}' namespace


Check If Secrets Exists
    [Arguments]   ${namespace}   ${secret_name}
    ${status}     ${val}  Run keyword and Ignore Error   Oc Get  kind=Secret  namespace=${namespace}   field_selector=metadata.name==${secret_name}
    RETURN   ${status}

Delete Data From Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}    ${body}
    Oc Patch   kind=Secret   name=${secret_name}   namespace=${namespace}       src=${body}

