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
    ...                 in the cluster (e.g., usually on OSD, ROSA).
    ...                 Returns ${TRUE} if RHODS Self-Managed is installed or if PRODUCT=ODH
    IF  "${PRODUCT}" == "ODH"  RETURN     ${TRUE}
    ${is_managed} =    Run Keyword And Return Status    OpenshiftLibrary.Oc Get
    ...                                                      kind=CatalogSource
    ...                                                      name=addon-managed-odh-catalog
    ...                                                      namespace=${OPERATOR_NAMESPACE}
    Run Keyword And Return    Evaluate    not ${is_managed}

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

Wait For Pods To Be Ready
    [Arguments]    ${label_selector}    ${namespace}    ${timeout}=300s    ${exp_replicas}=${NONE}
    Wait Until Keyword Succeeds    ${timeout}    3s
    ...    Check If Pod Exists    namespace=${namespace}    label_selector=${label_selector}
    ...    status_only=${FALSE}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc wait --for=condition=ready pod -l ${label_selector} -n ${namespace} --timeout=${timeout}
    Should Be Equal As Numbers    ${rc}    ${0}
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
    [Arguments]    ${container_name}    ${pod_label_selector}    ${namespace}
    ...            ${exp_requests}=${NONE}    ${exp_limits}=${NONE}
    ${resources_dict}=    Get Pod Hardware Resources And Limits    label_selector=${pod_label_selector}
    ...    namespace=${namespace}    container_name=${container_name}
    IF    ${exp_requests} == ${NONE}
        Dictionary Should Not Contain Key    ${resources_dict}    requests
    ELSE
        ${requests}=    Set Variable    ${resources_dict}[requests]
        FOR    ${index}    ${resource}    IN ENUMERATE    @{requests.keys()}
            Should Be Equal As Strings    ${requests}[${resource}]    ${exp_requests}[${resource}]
        END
    END
    IF    ${exp_limits} == ${NONE}
        Dictionary Should Not Contain Key    ${resources_dict}    limits
    ELSE
        ${limits}=    Set Variable    ${resources_dict}[limits]
        FOR    ${index}    ${resource}    IN ENUMERATE    @{limits.keys()}
            Should Be Equal As Strings    ${limits}[${resource}]    ${exp_limits}[${resource}]
        END
    END

Wait Until CRD Exists
    [Documentation]    Repeatedly searches for the expected CRD. Stops when it finds it
    [Arguments]    ${crd_fullname}
    Wait Until Keyword Succeeds    15 times    5s
    ...    Oc Get    kind=CustomResourceDefinition    name=${crd_fullname}