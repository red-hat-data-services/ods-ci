*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}
    ${status}     Check If Secrets Exists      ${namespace}      ${secret_name}
    IF    '${status}'=='PASS'
        Oc Delete   kind=Secret   name=${secret_name}   namespace=${namespace}
    ELSE
        FAIL    No secret present with name '${secret_name}' in '${namespace}' namespace
    END
    ${status}      Check If Secrets Exists      ${namespace}      ${secret_name}
    IF    '${status}'!='FAIL'
    ...    FAIL    Secret with name '${secret_name}' is not deleted in '${namespace}' namespace

Check If Secrets Exists
    [Arguments]   ${namespace}   ${secret_name}
    ${status}     ${val}  Run keyword and Ignore Error
    ...    Oc Get  kind=Secret  namespace=${namespace}   field_selector=metadata.name==${secret_name}
    RETURN   ${status}

Delete Data From Secrets using Name
    [Arguments]    ${namespace}     ${secret_name}
    ${return_code} =	  Run And Return Rc
    ...    oc patch secret -n ${namespace} ${secret_name} --type=json -p='[{"op": "remove", "path": "/data"}]'
    IF    ${return_code} != ${0}    Log    level=WARN
    ...    message=No Secret '${secret_name}' found in '${namespace}', or Secret Data was already deleted
