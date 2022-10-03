*** Settings ***
Documentation  Set of Keywords for OCP checks
Library    OpenShiftLibrary
Library    ../../venv_ods/lib64/python3.8/site-packages/robot/libraries/OperatingSystem.py


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
    [Arguments]  ${crd}  ${cr_name}
    @{cr_obj} =  OpenShiftLibrary.Oc Get  kind=${crd}
    &{cr_obj_dictionary} =  Set Variable  ${cr_obj}[0]
    Should Match  ${cr_obj_dictionary.metadata.name}  ${cr_name}
    Should Be Equal  ${cr_obj_dictionary.status.conditions[0].type}  Available
    Should Be Equal  ${cr_obj_dictionary.status.conditions[0].status}  True

Is RHODS Self-Managed
    [Documentation]     Returns ${FALSE} if RHODS Managed (i.e., Cloud version) is installed
    ...                 in the cluster (e.g., usually on OSD, ROSA).
    ...                 Returns ${TRUE} if RHODS Self-Managed is installed (e.g., usually on PSI or baremetal)
    ${self_managed_cs} =    OpenshiftLibrary.Oc Get    kind=CatalogSource  name=self-managed-rhods  namespace=openshift-marketplace
    IF    ${self_managed_cs} == ${NONE}
        ${is_self_managed} =    Set Variable   ${FALSE}
    ELSE
        ${is_self_managed} =    Set Variable   ${TRUE}
    END
    [Return]    ${is_self_managed}
