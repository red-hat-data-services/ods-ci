*** Settings ***
Documentation       Verify DatabaseService enablement and removal through the DataScienceCluster.

Library             Process


*** Variables ***
${DSC_RESOURCE}             datascienceclusters.v3.datasciencecluster.opendatahub.io
${DSC}                      ${DSC_RESOURCE}/default-dsc
${SERVICE_API}              databaseservices.services.platform.opendatahub.io
${SERVICE}                  default-db-operator
${DEPLOYMENT}               odh-db-operator-operator
${PROVIDER_API}             databaseproviders.infrastructure.opendatahub.io
${ORIGINAL_COMPONENT}       ${NONE}


*** Test Cases ***
Validate DatabaseService Managed And Removed States
    [Documentation]    Verify that the DSC creates a Ready DatabaseService and removes it when disabled.
    [Tags]
    ...    DatabaseService
    ...    Operator
    ...    Integration
    ...    Tier1
    ...    RHOAIENG-104095
    [Setup]                 Prepare DatabaseService Lifecycle Test

    Set DatabaseService Component                   {"managementState":"Managed"}
    Wait For DatabaseService To Be Ready
    Require DatabaseService Has No Consumers
    Set DatabaseService Component                   {"managementState":"Removed"}
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     5 sec
    ...                     Verify DatabaseService Is Removed

    [Teardown]              Restore DatabaseService Component


*** Keywords ***
Prepare DatabaseService Lifecycle Test
    [Documentation]    Require support in the DSC schema and save the original component configuration.
    ${schema_path}=    Catenate    SEPARATOR=
    ...    jsonpath={.spec.versions[?(@.name=="v3")].schema.openAPIV3Schema
    ...    .properties.spec.properties.components.properties.databaseservice}
    ${schema}=    Run Oc    get    crd/datascienceclusters.datasciencecluster.opendatahub.io    -o    ${schema_path}
    Skip If    not $schema    The DataScienceCluster schema does not support DatabaseService.
    Require DatabaseService Has No Consumers
    ${component}=    Run Oc    get    ${DSC}    -o    jsonpath\={.spec.components.databaseservice}
    Set Test Variable    ${ORIGINAL_COMPONENT}    ${component}

Require DatabaseService Has No Consumers
    [Documentation]    Skip if claims or custom providers are present on this cluster.
    FOR    ${api}    IN    databaseclaims.infrastructure.opendatahub.io    schemaclaims.infrastructure.opendatahub.io
        ${claims}=    Get Resources If API Exists    ${api}    -A    -o    name
        Skip If    $claims    DatabaseService lifecycle testing requires a cluster without claims.
    END
    ${providers}=    Get Resources If API Exists    ${PROVIDER_API}    -o    jsonpath\={.items[*].metadata.name}
    IF    not $providers    RETURN
    ${default}=    Get Resources If API Exists    ${SERVICE_API}    ${SERVICE}
    ...    --ignore-not-found    -o    jsonpath\={.status.defaultProviderName}
    Skip If    $providers != $default
    ...    DatabaseService lifecycle testing requires a cluster without custom providers.

Set DatabaseService Component
    [Documentation]    Merge-patch the DatabaseService component of the DSC.
    [Arguments]    ${component}
    Run Oc    patch    ${DSC}    --type\=merge
    ...    -p    {"spec":{"components":{"databaseservice":${component}}}}

Wait For DatabaseService To Be Ready
    [Documentation]    Wait for the module singleton to appear and become Ready.
    Wait Until Keyword Succeeds    3 min    5 sec    Run Oc    get    ${SERVICE_API}/${SERVICE}
    Run Oc    wait    ${SERVICE_API}/${SERVICE}    --for\=condition\=Ready    --timeout\=5m

Verify DatabaseService Is Removed
    [Documentation]    Verify both the module singleton and its controller Deployment are gone.
    ${service}=    Get Resources If API Exists    ${SERVICE_API}    ${SERVICE}    --ignore-not-found    -o    name
    Should Be Empty    ${service}    The DatabaseService singleton still exists.
    ${deployment}=    Run Oc
    ...    get
    ...    deployments
    ...    -A
    ...    --field-selector\=metadata.name\=${DEPLOYMENT}
    ...    -o
    ...    name
    Should Be Empty    ${deployment}    The DatabaseService controller Deployment still exists.

Restore DatabaseService Component
    [Documentation]    Restore the saved component configuration, including an originally absent field.
    IF    $ORIGINAL_COMPONENT is None    RETURN
    ${component}=    Set Variable If    $ORIGINAL_COMPONENT    ${ORIGINAL_COMPONENT}    null
    Set DatabaseService Component    ${component}
    ${restored}=    Run Oc    get    ${DSC}    -o    jsonpath\={.spec.components.databaseservice}
    Should Be Equal    ${restored}    ${ORIGINAL_COMPONENT}
    ${state}=    Run Oc    get    ${DSC}    -o    jsonpath\={.spec.components.databaseservice.managementState}
    IF    $state == 'Managed'
        Wait For DatabaseService To Be Ready
    ELSE
        Wait Until Keyword Succeeds    5 min    5 sec    Verify DatabaseService Is Removed
    END

Get Resources If API Exists
    [Documentation]    Return empty output for an absent CRD and surface errors when querying a served API.
    [Arguments]    ${api}    @{arguments}
    ${crd}=    Run Oc    get    crd/${api}    --ignore-not-found    -o    name
    IF    not $crd    RETURN    ${EMPTY}
    ${output}=    Run Oc    get    ${api}    @{arguments}
    RETURN    ${output}

Run Oc
    [Documentation]    Run oc without a shell and surface command failures.
    [Arguments]    @{arguments}
    ${result}=    Run Process    oc    @{arguments}
    Should Be Equal As Integers    ${result.rc}    0    ${result.stdout}\n${result.stderr}
    RETURN    ${result.stdout}
