*** Settings ***

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

Get PVC Size
    [Documentation]    Get configure PVC size from configmap
    [Arguments]   ${namespace}   ${configmap_name}=jupyterhub-cfg
    ${data}    OpenShiftCLI.Get  kind=ConfigMap  namespace=${namespace}
    ...    field_selector=metadata.name==${configmap_name}
    ${size}    Set Variable      ${data[0]['data']['singleuser_pvc_size']}
    [Return]   ${size}[:-2]

Change PVC Size From ConfigMap
    [Documentation]    Configure PVC size for JH
    ...    Supported size are whole number(ex: 120Gi,10Gi etc)
    ...    Decimal,alphabet charcter and number below 1 is not supported
    [Arguments]   ${size}    ${configmap_name}=jupyterhub-cfg
    OpenShiftCLI.Patch   kind=ConfigMap  name=${configmap_name}  namespace=${NAMESPACE}
    ...    src={"data":{"singleuser_pvc_size": "${size}"}}
