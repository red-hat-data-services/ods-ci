*** Settings ***
Library    OpenShiftCLI
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete ConfigMap using Name
    [Arguments]    ${namespace}                              ${configmap_name}
    ${status}      Check If ConfigMap Exists      ${namespace}      ${configmap_name}
    Run Keyword IF          '${status}'=='PASS'   OpenShiftCLI.Delete   kind=ConfigMap   name=${configmap_name}   namespace=${namespace}
    ...        ELSE         FAIL        No configmaps present with name '${configmap_name}' in '${namespace}' namespace, Check the configmap name and namespace provide is correct and try again
    ${status}      Check If ConfigMap Exists      ${namespace}      ${configmap_name}
    Run Keyword IF          '${status}'!='FAIL'     FAIL        ConfigMaps with name '${configmap_name}' is not deleted in '${namespace}' namespace


Check If ConfigMap Exists
    [Arguments]   ${namespace}   ${configmap_name}
    ${status}     ${val}  Run keyword and Ignore Error   OpenShiftCLI.Get  kind=ConfigMap  namespace=${namespace}   field_selector=metadata.name==${configmap_name}
    [Return]   ${status}

