*** Settings ***
Library    OpenShiftLibrary
Resource   ../../OCPDashboard/Page.robot
Resource   ../../ODH/ODHDashboard/ODHDashboard.robot

*** Keywords ***

Delete ConfigMap using Name
    [Arguments]    ${namespace}    ${configmap_name}
    ${config_exists}=      Check If ConfigMap Exists      ${namespace}      ${configmap_name}
    IF    '${config_exists}'=='PASS'
        ${deleted_config}=    Oc Delete   kind=ConfigMap   name=${configmap_name}   namespace=${namespace}
        IF    len(${deleted_config}) == 0
            FAIL    Error deleting configmaps: ${deleted_config}
        END
        ${config_exists}=      Check If ConfigMap Exists      ${namespace}      ${configmap_name}
        IF    '${config_exists}'=='PASS'
        ...    FAIL    ConfigMap '${configmap_name}' in namespace '${namespace}' still exists
    ELSE
        Log    level=WARN
        ...    message=No configmaps present with name '${configmap_name}' in '${namespace}' namespace
    END

Check If ConfigMap Exists
    [Arguments]   ${namespace}   ${configmap_name}
    ${status}     ${val}  Run keyword and Ignore Error
    ...    Oc Get  kind=ConfigMap  namespace=${namespace}   field_selector=metadata.name==${configmap_name}
    RETURN   ${status}

Get PVC Size
    [Documentation]    Get configure PVC size from OdhDashboardConfig CR
    [Arguments]   ${namespace}   ${configmap_name}=odh-dashboard-config
    ${data}    Oc Get  kind=OdhDashboardConfig  namespace=${namespace}
    ...    field_selector=metadata.name==${configmap_name}
    ${size}    Set Variable      ${data[0]['spec']['notebookController']['pvcSize']}
    RETURN   ${size}[:-2]

Change PVC Size From ConfigMap
    [Documentation]    Configure PVC size for Notebook controller
    ...    Supported size are whole number(ex: 120Gi,10Gi etc)
    ...    Decimal,alphabet charcter and number below 1 is not supported
    [Arguments]   ${size}    ${configmap_name}=odh-dashboard-config
    Oc Patch   kind=OdhDashboardConfig  name=${configmap_name}  namespace=${NAMESPACE}
    ...    src={"spec": {"notebookController": {"pvcSize": "${size}"}}}   type=merge
