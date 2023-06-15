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
    ...    ${retry}=20    ${retry_interval}=3s
    Wait Until Keyword Succeeds    ${retry} times    ${retry_interval}    Operator Subscription Last Condition Should Be
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SUBSCRIPTION_NAME}
    ...    namespace=${NAMESPACE}  

Deploy Custom Resource
    [Arguments]    ${kind}    ${namespace}    ${filepath}
    Oc Apply    kind=${kind}    namespace=${namespace}    src=${filepath}

Operator Pods Should Be Running
    [Arguments]    ${namespace}    ${expected_pods_dict}
    ${tot_pods}=    Set Variable    ${0}
    FOR    ${index}    ${pod_info}    IN ENUMERATE    @{expected_pods_dict}
        Log    ${index}: ${pod_info}[label_selector]
        ${startswith_flag}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${pod_info}    starts_with
        IF    ${startswith_flag} == ${TRUE}
            ${rc}    ${pod_name}=    Run And Return Rc And Output    oc get pod -n ${namespace} --selector ${pod_info}[label_selector] -ojson | jq '.items[] | select(.metadata.name | startswith("${pod_info}[starts_with]")) | .metadata.name' | tr -d '"'    # robocop: disable
            @{pod}=  Oc Get    kind=Pod  namespace=${namespace}    label_selector=${pod_info}[label_selector]
            ...    field_selector=metadata.name=${manager_pod_name}
        ELSE
            @{pod}=  Oc Get    kind=Pod  namespace=${namespace}  label_selector=${pod_info}[label_selector]
        END
        Verify Deployment  component=${pod}  nPods=${pod_info}[n_pods] 
        ...    nContainers=${pod_info}[n_containers]  containerNames=${pod_info}[containers_names]
        ${tot_pods}=    Evaluate    ${tot_pods} + ${pod_info}[n_pods] 
    END
    ${pods}=     Run    oc get pods -n ${namespace} -o json | jq '.items[] | .metadata.name' | sed 's/"//g'
    ${pods_list}=    Text To List    ${pods}
    Run Keyword And Continue On Failure    Length Should Be    ${pods_list}    ${tot_pods}

Wait Until Operator Pods Are Running
    [Documentation]    Keeps checking for Starburst Enterprise resources until
    ...                all of them get the expected status
    [Arguments]    ${namespace}    ${expected_pods_dict}    ${cr_chk_retries}=30
    ...            ${cr_chk_retries_interval}=30s    ${pods_chk_retries}=30
    ...            ${pods_chk_retries_interval}=30s
    Wait Until Keyword Succeeds    ${pods_chk_retries} times    ${pods_chk_retries_interval}
    ...    Operator Pods Should Be Running    namespace=${namespace}
    ...    expected_pods_dict=${expected_pods_dict}
