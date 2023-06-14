*** Settings ***
Documentation       Collcetion of keywords to manage ISV operators via CLI
Resource            ../../RHOSi.resource
Library             OperatingSystem


*** Variables ***
${FILES_RESOURCES_DIRPATH}=            ods_ci/tests/Resources/Files
${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}=            ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}=            ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml


*** Keywords ***
Install ISV Operator From OperatorHub Via CLI
    [Arguments]    ${operator_name}    ${subscription_name}    ${namespace}=openshift-operators
    ...            ${channel}=stable    ${catalog_source_name}=certified-operators
    ...            ${cs_namespace}=openshift-marketplace    ${operator_group_target_ns}=${NONE}
    # starburst-enterprise-helm-operator-rhmp-odsci
    ${operator_sub_filepath}=    Set Variable    ${FILES_RESOURCES_DIRPATH}/${operator_name}-sub.yaml
    Copy File    ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<SUBSCRIPTION_NAME>/${subscription_name}/g" ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<OPERATOR_NAMESPACE>/${namespace}/g" ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<UPDATE_CHANNEL>/${channel}/g" ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<OPERATOR_NAME>/${operator_name}/g" ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<CATALOG_SOURCE>/${catalog_source_name}/g" ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<CS_NAMESPACE>/${cs_namespace}/g" ${operator_sub_filepath}
    Oc Apply    kind=Subscription    src=${operator_sub_filepath}
    IF    "${operator_group_target_ns}" != "${NONE}"
        Create Operator Group    operator_name=${operator_name}
        ...    namespace=${namespace}    target_namespace=${operator_group_target_ns}        
    END

Create Operator Group
    [Documentation]    Creates the Operator Group object which might be needed by an operator.
    ...                It currently supports creating OperatorGroups with only 1 targeted namespace
    [Arguments]    ${operator_name}    ${namespace}    ${target_namespace}
    ${operator_group_filepath}=    Set Variable    ${FILES_RESOURCES_DIRPATH}/${operator_name}-group.yaml
    Copy File    ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${operator_group_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<BASE_NAME>/${operator_name}/g" ${operator_group_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<NAMESPACE>/${namespace}/g" ${operator_group_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i "s/<TARGET_NAMESPACE>/${target_namespace}/g" ${operator_group_filepath}
    Oc Apply    kind=OperatorGroup    src=${operator_group_filepath}    api_version=v1
    
Operator Subscription Last Condition Should Be
    [Arguments]    ${type}    ${status}    ${reason}
    ...    ${subcription_name}    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${subcription_name} -n ${namespace} -ojson | jq '.status.conditions | last | select(.type=="CatalogSourcesUnhealthy" and .status=="False" and .reason=="AllCatalogSourcesHealthy")'
    Should Be Equal As Integers    ${rc}     ${0}
    Should Not Be Empty    ${out}

Wait Until Operator Subscription Last Condition Is
    [Arguments]    ${type}    ${status}    ${reason}
    ...    ${subcription_name}    ${namespace}
    ...    ${retry}=10    ${retry_interval}=3s
    Wait Until Keyword Succeeds    ${retry}    ${retry_interval}    Operator Subscription Last Condition Should Be
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SUBSCRIPTION_NAME}
    ...    namespace=${NAMESPACE}  

Controller Manager Pod Should Be Running
    [Arguments]    ${namespace}    ${prefix}
    ${rc}    ${manager_pod_name}=    Run And Return Rc And Output    oc get pod -n ${namespace} --selector control-plane=controller-manager -ojson | jq '.items[] | select(.metadata.name | startswith("${prefix}")) | .metadata.name' | tr -d '"''
    @{manager_pod}=  Oc Get    kind=Pod  namespace=${namespace}  field_selector=metadata.name=${manager_pod_name}
    ${container_names}=  Create List  manager
    Verify Deployment  component=${manager_pod}      nPods=1  nContainers=1  containerNames=${container_names}
