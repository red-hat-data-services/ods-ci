*** Settings ***

Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}
    ${status}     Check If Secrets Exists      ${namespace}      ${secret_name}
    Run Keyword IF          '${status}'=='PASS'   OpenShiftCLI.Delete   kind=Secret   name=${secret_name}   namespace=${namespace}
    ...        ELSE      FAIL        No secrets present with name '${secret_name}' in '${namespace}' namespace, Check the secret name and namespace provide is correct and try again
    ${status}      Check If Secrets Exists      ${namespace}      ${secret_name}
    Run Keyword IF          '${status}'!='FAIL'     FAIL        Secret with name '${secret_name}' is not deleted in '${namespace}' namespace


Check If Secrets Exists
    [Arguments]   ${namespace}   ${secret_name}
    ${status}     ${val}  Run keyword and Ignore Error   OpenShiftCLI.Get  kind=Secret  namespace=${namespace}   field_selector=metadata.name==${secret_name}
    [Return]   ${status}

Delete Data From Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}    ${body}
    OpenShiftCLI.Patch   kind=Secret   name=${secret_name}   namespace=${namespace}       src=${body}

