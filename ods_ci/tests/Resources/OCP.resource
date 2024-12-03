*** Settings ***
Documentation  Set of Keywords for OCP checks
Library    OperatingSystem
Library    OpenShiftLibrary
Resource   Page/OCPDashboard/Pods/Pods.robot


*** Keywords ***
Verify DaemonSet Status
    [Documentation]  Verifies that a DaemonSet exists, and that the number
    ...    of available pods matches the number of desired pods
    [Arguments]  ${label}  ${dsname}
    @{ds_obj} =  OpenShiftLibrary.Oc Get  kind=DaemonSet  label_selector=${label}
    &{ds_obj_dictionary} =  Set Variable  ${ds_obj}[0]
    Should Match  ${ds_obj_dictionary.metadata.name}  ${dsname}
    Should Be Equal  ${ds_obj_dictionary.status.desiredNumberScheduled}  ${ds_obj_dictionary.status.numberAvailable}

Verify Deployment Status
    [Documentation]  Verifies that a Deployment exists, and that its status
    ...    is "Available"
    [Arguments]  ${label}  ${dname}
    @{d_obj} =  OpenShiftLibrary.Oc Get  kind=Deployment  label_selector=${label}
    &{d_obj_dictionary} =  Set Variable  ${d_obj}[0]
    Should Match  ${d_obj_dictionary.metadata.name}  ${dname}
    Should Be Equal  ${d_obj_dictionary.status.conditions[0].type}  Available

Verify Operator Status
    [Documentation]  Verifies that an Operator exists, that its status
    ...    is "Succeeded" and that the name matches
    [Arguments]  ${label}  ${operator_name}
    @{op_obj} =  OpenShiftLibrary.Oc Get  kind=ClusterServiceVersion  label_selector=${label}
    &{op_obj_dictionary} =  Set Variable  ${op_obj}[0]
    Should Match  ${op_obj_dictionary.metadata.name}  ${operator_name}
    Should Be Equal  ${op_obj_dictionary.status.phase}  Succeeded

Verify Namespace Status
    [Documentation]  Verifies that a Namespace exists, and that its status
    ...    is "Active"
    [Arguments]  ${label}
    @{ns_obj} =  OpenShiftLibrary.Oc Get  kind=Namespace  label_selector=${label}
    &{ns_obj_dictionary} =  Set Variable  ${ns_obj}[0]
    Should Be Equal  ${ns_obj_dictionary.status.phase}  Active

Verify CR Status
    [Documentation]  Verifies that a CR exists, that it's available
    ...    and that the name matches
    [Arguments]  ${crd}  ${cr_name}  ${status}=Available
    @{cr_obj} =  OpenShiftLibrary.Oc Get  kind=${crd}  name=${cr_name}
    &{cr_obj_dictionary} =  Set Variable  ${cr_obj}[0]
    Should Match  ${cr_obj_dictionary.metadata.name}  ${cr_name}
    Should Be Equal  ${cr_obj_dictionary.status.conditions[0].type}  ${status}
    Should Be Equal  ${cr_obj_dictionary.status.conditions[0].status}  True

Verify Notebook CR Is Running
    [Documentation]  Verifies that a Notebook CR exists, that it's running
    ...    and that the name matches
    [Arguments]  ${cr_name}
    @{cr_obj} =  OpenShiftLibrary.Oc Get  kind=Notebook  name=${cr_name}
    &{cr_obj_dictionary} =  Set Variable  ${cr_obj}[0]
    Should Match  ${cr_obj_dictionary.metadata.name}  ${cr_name}
    Should Be Equal  ${cr_obj_dictionary.status.conditions[0].type}  Running

Is RHODS Self-Managed
    [Documentation]     Returns ${FALSE} if RHODS Managed (i.e., Cloud version) is installed
    ...    in the cluster (e.g., usually on OSD, ROSA).
    ...    Returns ${TRUE} if RHODS Self-Managed is installed or if PRODUCT=ODH
    ...
    ...    Note: this keyword is not using OpenShift library to speed up its execution on local.
    ...    You'll find more info at https://github.com/red-hat-data-services/ods-ci/pull/1366
    IF  "${PRODUCT}" == "ODH"  RETURN     ${TRUE}
    ${rc}=    Run And Return Rc    oc get catalogsource addon-managed-odh-catalog -n ${OPERATOR_NAMESPACE}
    Run Keyword And Return    Run Keyword And Return Status      Should Not Be Equal As Numbers    ${rc}    ${0}

Get MachineSets
    [Documentation]    Returns a list of machinesets names
    ${machine_sets_oc} =    Run    oc get machinesets -n openshift-machine-api | awk '{split($0,a); print a[1]}'
    @{machinesets} =    Split To Lines    ${machine_sets_oc}
    ${tmp} =    Remove From List    ${machinesets}    0
    Should Be Equal As Strings    ${tmp}    NAME
    RETURN    @{machinesets}

Fetch Openshift CA Bundle
    [Documentation]    Gets the CA bundle defined in the secret `router-certs-defaults` in namespace `openshift-ingress`
    ...    Useful when working with self-managed clusters to verify connections
    ${rc} =    Run And Return Rc
    ...    oc get secret -n openshift-ingress router-certs-default -o json | jq '.data."tls.crt"' | sed 's/"//g' | base64 -d > openshift_ca.crt  # robocop: disable
    Should Be Equal As Strings    ${rc}    0

Fetch CA Certificate If RHODS Is Self-Managed
    [Documentation]    Fetches the OpenShift CA certificate if the keyword is run in a self-managed environment
    ...    It saves it to a file called `openshift_ca.crt` in the root folder and can be used by other keywords
    ...    e.g. curl commands or Requests calls against unsecured https endpoints.
    ${self_managed} =    Is RHODS Self-Managed
    IF  ${self_managed}==${TRUE}
        Fetch Openshift CA Bundle
    END

Get Events And Pod Logs
    [Documentation]    Fetches the namespace events and the pod logs (all containers).
    ...                It prints and return both items
    [Arguments]    ${namespace}    ${label_selector}
    ${rc}    ${events}=    Run And Return Rc And Output    oc get events -n ${namespace}
    Log    ${events}
    ${rc}    ${podlogs}=    Run And Return Rc And Output
    ...    oc logs -l ${label_selector} --all-containers -n ${namespace} --ignore-errors
    Log    ${podlogs}
    RETURN    ${events}    ${podlogs}

Wait For Pods To Be Ready
    [Documentation]    Waits until the pods with given label selector in the given namespace have `condition=ready`.
    ...                This keyword can also check for the expected number of the pod replicas using `${exp_replicas}`
    ...                argument.
    [Arguments]    ${label_selector}    ${namespace}    ${timeout}=600s    ${exp_replicas}=${NONE}
    Wait Until Keyword Succeeds    ${timeout}    3s
    ...    Check If Pod Exists    namespace=${namespace}    label_selector=${label_selector}
    ...    status_only=${FALSE}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc wait --for=condition=ready=true pod -l ${label_selector} -n ${namespace} --timeout=${timeout}
    IF    ${rc} != ${0}
        ${events}    ${podlogs}=    Get Events And Pod Logs    ${namespace}    ${label_selector}

        Fail    msg=Pod defined by selector "${label_selector}" in "${namespace}" namespace is not ready by timeout.
    END
    IF    "${exp_replicas}" != "${NONE}"
        @{replicas}=    Oc Get    kind=Pod    namespace=${namespace}
        ...    label_selector=${label_selector}
        Length Should Be  ${replicas}  ${exp_replicas}
    END

Wait For Deployment Replica To Be Ready
    [Documentation]   Wait for Deployment of ${label_selector} in ${namespace} to have the Replica-Set Ready
    [Arguments]     ${label_selector}    ${namespace}     ${timeout}=600s    ${exp_replicas}=${NONE}
    Log To Console
    ...    Waiting for Deployment with label "${label_selector}" in Namespace "${namespace}", to have desired Replica-Set ready  #robocop: disable:line-too-long
    IF    "${exp_replicas}" != "${NONE}"
        # Check the expected number of pods replica in Deployment if desired
        Run And Verify Command
        ...    oc get deployment -l ${label_selector} -n ${namespace} -o json | jq -e '.items[].spec | .replicas == ${exp_replicas}'  #robocop: disable:line-too-long
        ...    print_to_log=${FALSE}
    END
    # Wait until pods for the replica are ready
    Wait For Pods To Be Ready    ${label_selector}    ${namespace}    ${timeout}    ${exp_replicas}
    # Now the status should match the number of expected replicas with ready replicas
    Run And Verify Command
    ...    oc get deployment -l ${label_selector} -n ${namespace} -o json | jq -e '.status | .replicas == .readyReplicas'  #robocop: disable:line-too-long
    ...    print_to_log=${FALSE}

Wait For Pods To Succeed
    [Arguments]    ${label_selector}    ${namespace}    ${timeout}=300s    ${exp_replicas}=${NONE}
    Wait Until Keyword Succeeds    ${timeout}    3s
    ...    Check If Pod Exists    namespace=${namespace}    label_selector=${label_selector}
    ...    status_only=${FALSE}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc wait --for=jsonpath='{.status.phase}'=Succeeded pod -l ${label_selector} -n ${namespace} --timeout=${timeout}
    IF    ${rc} != ${0}
        ${events}    ${podlogs}=    Get Events And Pod Logs    ${namespace}    ${label_selector}
        Fail    msg=Pod did not succeed by timeout
    END
    IF    "${exp_replicas}" != "${NONE}"
        @{replicas}=    Oc Get    kind=Pod    namespace=${namespace}
        ...    label_selector=${label_selector}
        Length Should Be  ${replicas}  ${exp_replicas}
    END

Wait For Pods To Be Terminated
    [Arguments]    ${label_selector}    ${namespace}    ${timeout}=180s
    Wait Until Keyword Succeeds    ${timeout}    3s
    ...    Check If Pod Exists    namespace=${namespace}    label_selector=${label_selector}
    ...    status_only=${FALSE}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc wait --for=delete pod -l ${label_selector} -n ${namespace} --timeout=${timeout}
    Should Be Equal As Numbers    ${rc}    ${0}

Add Secret To Service Account
    [Arguments]    ${sa_name}    ${secret_name}    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc patch sa ${sa_name} -n ${namespace} -p '{"secrets": [{"name": "${secret_name}"}]}'
    Should Be Equal As Integers    ${rc}    ${0}

Get Pod Hardware Resources And Limits
    [Arguments]    ${label_selector}    ${namespace}    ${container_name}=${NONE}
    IF    "${container_name}" == "${NONE}"
        ${rc}    ${resources}=    Run And Return Rc And Output
        ...    oc get pods -l ${label_selector} -n ${namespace} -ojson | jq '.items[].spec.containers[] | .resources'
    ELSE
        ${rc}    ${resources}=    Run And Return Rc And Output
        ...    oc get pods -l ${label_selector} -n ${namespace} -ojson | jq '.items[].spec.containers[] | select(.name=="${container_name}") | .resources'
    END
    Should Be Equal As Integers    ${rc}    ${0}
    ${resources}=    Load Json String    ${resources}
    RETURN    ${resources}

Container Hardware Resources Should Match Expected
    [Documentation]    This keyword checks that the requests/limits set in a specific container in a pod contain the
    ...    requests and limits passed in with `exp_requests` and `exp_limits`. This means that the container might have
    ...    additional requests/limits set which are not explicitly checked against. If you want to make sure you're
    ...    checking all attributes you have to explicitly pass them in with `exp_requests/limits`.
    [Arguments]    ${container_name}    ${pod_label_selector}    ${namespace}
    ...            ${exp_requests}=${NONE}    ${exp_limits}=${NONE}
    ${resources_dict}=    Get Pod Hardware Resources And Limits    label_selector=${pod_label_selector}
    ...    namespace=${namespace}    container_name=${container_name}
    IF    ${exp_requests} == ${NONE}
        Dictionary Should Not Contain Key    ${resources_dict}    requests
    ELSE
        ${requests}=    Set Variable    ${resources_dict}[requests]
        FOR    ${index}    ${resource}    IN ENUMERATE    @{exp_requests.keys()}
            Should Be Equal As Strings    ${requests}[${resource}]    ${exp_requests}[${resource}]
        END
    END
    IF    ${exp_limits} == ${NONE}
        Dictionary Should Not Contain Key    ${resources_dict}    limits
    ELSE
        ${limits}=    Set Variable    ${resources_dict}[limits]
        FOR    ${index}    ${resource}    IN ENUMERATE    @{exp_limits.keys()}
            Should Be Equal As Strings    ${limits}[${resource}]    ${exp_limits}[${resource}]
        END
    END

Wait Until CRD Exists
    [Documentation]    Repeatedly searches for the expected CRD. Stops when it finds it
    [Arguments]    ${crd_fullname}
    Wait Until Keyword Succeeds    15 times    5s
    ...    Oc Get    kind=CustomResourceDefinition    name=${crd_fullname}

Resource Should Exist
    [Documentation]    Check resource existson a namespace
    [Arguments]       ${resource}     ${resource_name}    ${namespace}
    ${rc}    ${out}=     Run and Return Rc And Output
    ...  oc get ${resource} ${resource_name} -n ${namespace}
    Should Be Equal    "${rc}"    "0"    msg=${out}

Resource Status Should Be
    [Documentation]    Check Resource Status
    [Arguments]       ${oc_get}     ${resource}    ${expected_status}
    ${status}=     Run
    ...  ${oc_get}
    Log    ${status}    console=True
    Should Be Equal    ${status}    ${expected_status}   msg=${resource} is not in ${expected_status} status

Verify Pod Logs Do Not Contain
    [Documentation]    Checks there are no errors on Pod Logs
    [Arguments]    ${pod_name}    ${pod_namespace}    ${regex_pattern}    ${container}
    ${pod_logs}=    Oc Get Pod Logs  name=${pod_name}  namespace=${pod_namespace}  container=${container}
    ${match_list}    Get Regexp Matches   ${pod_logs}     ${regex_pattern}
    ${entry_msg}      Remove Duplicates      ${match_list}
    ${length}         Get Length   ${entry_msg}
    IF   ${length} != ${0}    FAIL    Pod ${pod_name} logs should not contain regexp ${regex_pattern}. Matching log entry: ${entry_msg}
    ...    ELSE    Log    message=Pod ${pod_name} logs does not contain regexp ${regex_pattern}    level=INFO

Is Resource Present
    [Documentation]    Check If Resource Is Present In Namespace
    [Arguments]    ${resource}    ${resource_name}    ${namespace}    ${expected_result}
    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get ${resource} ${resource_name} -n ${namespace}
    Should Be Equal    "${rc}"    "${expected_result}"    msg=${resource} does not exist in ${namespace}, ${output}

Create Namespace In Openshift
    [Documentation]    Create a new namespace if it does not already exist
    [Arguments]    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output    oc get project ${namespace}
    IF    ${rc} != 0
        ${rc}=     Run And Return Rc    oc new-project ${namespace}
        Should Be Equal    "${rc}"    "0"   msg=${output}
    END

Delete Namespace From Openshift
    [Documentation]    Delete namespace from opneshift if it exists
    [Arguments]    ${namespace}
    ${rc}   ${output}=    Run And Return Rc And Output    oc get project ${namespace}
    IF    ${rc} == 0
        ${rc}   ${output}=    Run And Return Rc And Output    oc delete project ${namespace}
        Should Be Equal    "${rc}"    "0"   msg=${output}
    END

Check If Pod Does Not Exist
    [Documentation]    Check if pod does not exist using pod label-selector
    [Arguments]        ${label_selector}    ${namespace}

    ${rc}   ${output}=    Run And Return Rc And Output
    ...    oc get pod -l {label_selector} -n ${namespace}
    Should Be Equal    "${rc}"    "1"    msg=${output}

Set Default Storage Class In GCP
    [Documentation]    If the storage class exists we can assume we are in GCP. We force ssd-csi to be the default class
    ...    for the duration of this test suite.
    [Arguments]    ${default}
    ${rc}=    Run And Return Rc    oc get storageclass ${default}
    IF    ${rc} == ${0}
        IF    "${default}" == "ssd-csi"
            Run    oc patch storageclass standard-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'  #robocop: disable
            Run    oc patch storageclass ssd-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  #robocop: disable
        ELSE
            Run    oc patch storageclass ssd-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'  #robocop: disable
            Run    oc patch storageclass standard-csi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  #robocop: disable
        END
    ELSE
        Log    Proceeding with default storage class because we're not in GCP
    END

Apply OpenShift Configuration
    [Documentation]    Apply the provided OpenShift configuration using oc apply -f -.
    [Arguments]    ${config}
    ${command}=    Set Variable    oc apply -f ${config}
    ${result}=    Run Process    ${command}    stdin=${config}    shell=True    stdout=PIPE    stderr=PIPE
    Should Be Equal As Strings    ${result.rc}    0    The oc apply command failed
    Log    ${result.stdout}

Get Resource Attribute
    [Documentation]    Gets the value of an attribute of a specific resource
    [Arguments]    ${namespace}    ${resource_type}    ${resource_name}    ${attribute_path}
    ${rc}   ${value}=    Run And Return Rc And Output
    ...    oc get ${resource_type}/${resource_name} -n ${namespace} -o 'jsonpath={${attribute_path}}'
    Should Be Equal    "${rc}"    "0"    msg=${value}
    IF    "${value}" != "${EMPTY}"
        Log To Console    ${resource_type} ${resource_name} in the namespace ${namespace} attribute ${attribute_path} value is ${value}
    ELSE 
        Log To Console    ${resource_type} ${resource_name} in the namespace ${namespace} attribute ${attribute_path} value is EMPTY
    END
    RETURN    ${value}

Wait For Namespace To Be Active
    [Documentation]    Waits for a given namespace to become active
    [Arguments]    ${namespace}    ${timeout}=30s
    WHILE    True    limit=${timeout}
        ${rc}=    Run And Return Rc    oc get namespace/${namespace}
        IF    "${rc}" == "0"
            BREAK
        END
    END
    ${rc}  ${value}=    Run And Return Rc And Output
    ...    oc wait --for jsonpath='{.status.phase}=Active' --timeout=${timeout} namespace/${namespace}
    Log    ${rc}
    Log    ${value}
    Should Be Equal As Integers    ${rc}    0

Is Cluster Type Self-Managed
    [Documentation]    Get the value of cluster type depending on the console URL domain
    ...    Returns ${TRUE} if cluster type is Self-Managed
    ...    Returns ${FALSE} if cluster type is Managed
    ${matches}=    Get Regexp Matches    ${OCP_CONSOLE_URL}    rh-ods
    ${size}=    Get Length    ${matches}
    IF    ${size}>0
        ${domain}=    Get From List    ${matches}    0
        IF    "${domain}" == "rh-ods"
            RETURN    ${TRUE}
        END
    ELSE
        RETURN    ${FALSE}
    END
