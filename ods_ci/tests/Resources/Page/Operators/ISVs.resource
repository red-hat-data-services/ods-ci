*** Settings ***
Documentation       Collcetion of keywords to manage ISV operators via CLI
Resource            ../../RHOSi.resource
Library             OperatingSystem


*** Variables ***
${FILES_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files
${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}=    ${FILES_RESOURCES_DIRPATH}/isv-operator-subscription.yaml
${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}=   ${FILES_RESOURCES_DIRPATH}/isv-operator-group.yaml


*** Keywords ***
Install ISV Operator From OperatorHub Via CLI    # robocop: disable
    [Documentation]    Installs the given operator via CLI
    [Arguments]    ${operator_name}    ${subscription_name}    ${namespace}=openshift-operators
    ...            ${channel}=stable    ${catalog_source_name}=certified-operators
    ...            ${cs_namespace}=openshift-marketplace    ${operator_group_name}=${NONE}
    ...            ${operator_group_ns}=${NONE}    ${operator_group_target_ns}=${NONE}
    Log To Console    message=Installing the '${operator_name}' Operator
    IF    "${operator_group_name}" != "${NONE}"
        Create Operator Group    name=${operator_group_name}
        ...    namespace=${operator_group_ns}    target_namespace=${operator_group_target_ns}
        ...    operator_name=${operator_name}
    END
    ${operator_sub_filepath}=    Set Variable    ${FILES_RESOURCES_DIRPATH}/${operator_name}-sub.yaml
    Copy File    ${SUBSCRIPTION_YAML_TEMPLATE_FILEPATH}    ${operator_sub_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<SUBSCRIPTION_NAME>/${subscription_name}/g" ${operator_sub_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<OPERATOR_NAMESPACE>/${namespace}/g" ${operator_sub_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<UPDATE_CHANNEL>/${channel}/g" ${operator_sub_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<OPERATOR_NAME>/${operator_name}/g" ${operator_sub_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<CATALOG_SOURCE>/${catalog_source_name}/g" ${operator_sub_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<CS_NAMESPACE>/${cs_namespace}/g" ${operator_sub_filepath}    # robocop: disable
    Oc Apply    kind=Subscription    src=${operator_sub_filepath}


Create Operator Group
    [Documentation]    Creates the Operator Group object which might be needed by an operator.
    ...                It currently supports creating OperatorGroups with only 1 targeted namespace
    [Arguments]    ${name}    ${namespace}    ${target_namespace}    ${operator_name}
    ${operator_group_filepath}=    Set Variable    ${FILES_RESOURCES_DIRPATH}/${operator_name}-group.yaml    # robocop: disable
    Copy File    ${OPERATORGROUP_YAML_TEMPLATE_FILEPATH}    ${operator_group_filepath}
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<BASE_NAME>/${name}/g" ${operator_group_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<NAMESPACE>/${namespace}/g" ${operator_group_filepath}    # robocop: disable
    ${rc}    ${out}=    Run And Return Rc And Output    sed -i'' -e "s/<TARGET_NAMESPACE>/${target_namespace}/g" ${operator_group_filepath}    # robocop: disable
    Oc Apply    kind=OperatorGroup    src=${operator_group_filepath}    api_version=v1
    IF    "${target_namespace}" == "${NONE}"
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc patch OperatorGroup ${name} -n ${namespace} -p '{"spec": null}' --type=merge
        Should Be Equal As Integers    ${rc}    ${0}
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc patch OperatorGroup ${name} -n ${namespace} -p '{"spec": {}}' --type=merge
        Should Be Equal As Integers    ${rc}    ${0}
    END

Operator Subscription Last Condition Should Be
    [Documentation]    Checks the subscription status matches the expected status
    [Arguments]    ${type}    ${status}    ${reason}
    ...    ${subcription_name}    ${namespace}=openshift-operators
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${subcription_name} -n ${namespace} -ojson | jq '.status.conditions[] | select(.type=="${type}" and .status=="${status}" and .reason=="${reason}")'    # robocop: disable
    Should Be Equal As Integers    ${rc}     ${0}
    Should Not Be Empty    ${out}

Wait Until Operator Subscription Last Condition Is    # robocop: disable
    [Documentation]    Keeps checking until the subscription status matches the expected status
    [Arguments]    ${type}    ${status}    ${reason}
    ...    ${subcription_name}    ${namespace}=openshift-operators
    ...    ${retry}=60
    ...    ${retry_interval}=3s
    Wait Until Keyword Succeeds    ${retry} times    ${retry_interval}    Operator Subscription Last Condition Should Be    # robocop: disable
    ...    type=${type}     status=${status}
    ...    reason=${reason}    subcription_name=${subcription_name}
    ...    namespace=${namespace}

Deploy Custom Resource
    [Documentation]    Deploys the operator Custom Resource instance
    [Arguments]    ${kind}    ${namespace}    ${filepath}
    Oc Apply    kind=${kind}    namespace=${namespace}    src=${filepath}

Operator Pods Should Be Running    # robocop: disable
    [Documentation]    Checks the expected pods of an operator are running
    [Arguments]    ${namespace}    ${expected_pods_dict}
    ${tot_pods}=    Set Variable    ${0}
    FOR    ${index}    ${pod_info}    IN ENUMERATE    @{expected_pods_dict}
        Log    ${index}: ${pod_info}[label_selector]
        ${startswith_flag}=    Run Keyword And Return Status
        ...    Dictionary Should Contain Key    ${pod_info}    starts_with
        IF    ${startswith_flag} == ${TRUE}
            ${rc}    ${pod_name}=    Run And Return Rc And Output
            ...    oc get pod -n ${namespace} --selector ${pod_info}[label_selector] -ojson | jq '.items[] | select(.metadata.name | startswith("${pod_info}[starts_with]")) | .metadata.name' | tr -d '"'    # robocop: disable
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

Wait Until Operator Pods Are Running    # robocop: disable
    [Documentation]    Keeps checking until the expected pods of an operator are running
    [Arguments]    ${namespace}    ${expected_pods_dict}
    ...            ${pods_chk_retries}=30    ${pods_chk_retries_interval}=30s
    Wait Until Keyword Succeeds    ${pods_chk_retries} times    ${pods_chk_retries_interval}
    ...    Operator Pods Should Be Running    namespace=${namespace}
    ...    expected_pods_dict=${expected_pods_dict}

Delete Custom Resource
    [Documentation]    Deletes the operator custom resource
    [Arguments]    ${kind}    ${namespace}    ${name}
    ${status}=    Run Keyword And Return Status
    ...    Oc Delete    kind=${kind}   name=${name}
    ...    namespace=${namespace}
    # ...    field_selector=metadata.name=${name}}
    IF    ${status} == ${FALSE}
        Fail    msg=Failed to delete ${kind} CR
    ELSE
        Log    successfully deleted ${kind} CR
    END

Uninstall ISV Operator From OperatorHub Via CLI
    [Documentation]    Uninstalls the given operator via CLI
    [Arguments]    ${subscription_name}    ${namespace}=openshift-operators
    ${rc}    ${current_csv_name}=    Run And Return Rc And Output
    ...    oc get subscription ${subscription_name} -n ${namespace} -ojson | jq '.status.currentCSV' | tr -d '"'    # robocop: disable
    Oc Delete    kind=Subscription    name=${subscription_name}    namespace=${namespace}
    Oc Delete    kind=ClusterServiceVersion    name=${current_csv_name}    namespace=${namespace}

Check If Operator Is Installed Via CLI
    [Documentation]    Check If Operator Is Installed Via CLI and Return the Status
    [Arguments]    ${operator_name}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscriptions.operators.coreos.com --all-namespaces -o custom-columns="PACKAGE:.spec.name" | awk '$1 == "${operator_name}"'    # robocop: disable
    ${status}   Run Keyword And Return Status    Should Not Be Empty    ${out}
    IF    ${status}
           RETURN   True
    ELSE
           RETURN  False
    END
