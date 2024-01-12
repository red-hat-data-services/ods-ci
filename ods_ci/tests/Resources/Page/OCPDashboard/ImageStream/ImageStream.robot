*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete ImageStream using Name
    [Arguments]    ${namespace}                         ${name}
    ${status}   Check If ImageStream Exists       ${namespace}      ${name}
    IF    '${status}'=='PASS'   Oc Delete   kind=ImageStream  namespace=${namespace}     label_selector=opendatahub.io/modified=false     field_selector=metadata.name==${name}
    ...        ELSE      FAIL        No ImageStream present with name '${name}' in '${namespace}' namespace, Check the ImageStream name and namespace provide is correct and try again
    ${status}   Check If ImageStream Exists       ${namespace}      ${name}
    IF    '${status}'!='FAIL'     FAIL        ImageStream with name '${name}' is not deleted in '${namespace}' namespace

Check If ImageStream Exists
    [Arguments]    ${namespace}      ${name}
    ${status}   ${val}  Run keyword and Ignore Error   Oc Get  kind=ImageStream  namespace=${namespace}         field_selector=metadata.name==${name}
    RETURN   ${status}




