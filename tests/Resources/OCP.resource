*** Settings ***
Documentation  Set of Keywords for OCP checks
Library    OpenShiftCLI


*** Keywords ***
Verify DaemonSet Status
    [Documentation]  Verifies that a DaemonSet exists, and that the number
    ...    of available pods matches the number of desired pods
    [Arguments]  ${label}  ${DSName}
    @{DS_obj} =  Get  kind=DaemonSet  label_selector=${label}
    &{DS_obj_dictionary} =  Set Variable  ${DS_obj}[0]
    Should Match  ${DS_obj_dictionary.metadata.name}  ${DSName}
    Should Be Equal  ${DS_obj_dictionary.status.desiredNumberScheduled}  ${DS_obj_dictionary.status.numberAvailable}

Verify Deployment Status
    [Documentation]  Verifies that a Deployment exists, and that its status
    ...    is "Available"
    [Arguments]  ${label}  ${DName}
    @{D_obj} =  Get  kind=Deployment  label_selector=${label}
    &{D_obj_dictionary} =  Set Variable  ${D_obj}[0]
    Should Match  ${D_obj_dictionary.metadata.name}  ${DName}
    Should Be Equal  ${D_obj_dictionary.status.conditions[0].type}  Available

Verify Operator Status
    [Documentation]  Verifies that an Operator exists, that its status
    ...    is "Succeeded" and that the name matches
    [Arguments]  ${label}  ${operator_name}
    @{Op_obj} =  Get  kind=ClusterServiceVersion  label_selector=${label}
    &{Op_obj_dictionary} =  Set Variable  ${Op_obj}[0]
    Should Match  ${Op_obj_dictionary.metadata.name}  ${operator_name}
    Should Be Equal  ${Op_obj_dictionary.status.phase}  Succeeded

Verify Namespace Status
    [Documentation]  Verifies that a Namespace exists, and that its status
    ...    is "Active"
    [Arguments]  ${label}
    @{NS_obj} =  Get  kind=Namespace  label_selector=${label}
    &{NS_obj_dictionary} =  Set Variable  ${NS_obj}[0]
    Should Be Equal  ${NS_obj_dictionary.status.phase}  Active
