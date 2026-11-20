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

    ${original_component}=                          Prepare DatabaseService Lifecycle Test
    Set DatabaseService Component                   {"managementState":"Managed"}
    Wait For DatabaseService To Be Ready
    ${blocker}=             Get DatabaseService Removal Blocker
    Should Be Empty         ${blocker}              DatabaseService removal blocked. ${blocker}
    Set DatabaseService Component                   {"managementState":"Removed"}
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     5 sec
    ...                     Verify DatabaseService Is Removed

    [Teardown]              Restore DatabaseService Component               ${original_component}


*** Keywords ***
Prepare DatabaseService Lifecycle Test
    [Documentation]    Require support in the DSC schema and save the original component configuration.
    ${schema_path}=    Catenate    SEPARATOR=
    ...    jsonpath={.spec.versions[?(@.name=="v3")].schema.openAPIV3Schema
    ...    .properties.spec.properties.components.properties.databaseservice}
    ${schema}=    Run Oc    get    crd/datascienceclusters.datasciencecluster.opendatahub.io    -o    ${schema_path}
    Skip If    not $schema    The DataScienceCluster schema does not support DatabaseService.
    ${blocker}=    Get DatabaseService Removal Blocker
    Skip If    $blocker    DatabaseService lifecycle testing requires isolation. ${blocker}
    ${component}=    Run Oc    get    ${DSC}    -o    jsonpath\={.spec.components.databaseservice}
    RETURN    ${component}

Get DatabaseService Removal Blocker
    [Documentation]    Report existing claims or custom providers that block safe removal.
    FOR    ${api}    IN    databaseclaims.infrastructure.opendatahub.io    schemaclaims.infrastructure.opendatahub.io
        ${claims}=    Get Resources If API Exists    ${api}    -A    -o    name
        IF    $claims    RETURN    Database claims are present.
    END
    ${providers}=    Get Resources If API Exists    ${PROVIDER_API}    -o    jsonpath\={.items[*].metadata.name}
    IF    not $providers    RETURN    ${EMPTY}
    ${default}=    Get Resources If API Exists    ${SERVICE_API}    ${SERVICE}
    ...    --ignore-not-found    -o    jsonpath\={.status.defaultProviderName}
    IF    $providers != $default
        RETURN    Custom database providers are present.
    END
    RETURN    ${EMPTY}

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
    [Tags]    robot:recursive-stop-on-failure
    [Arguments]    ${original}
    IF    $original is None    RETURN
    ${component}=    Set Variable If    $original    ${original}    null
    ${state}=    Evaluate    (json.loads($component) or {}).get('managementState')    modules=json
    IF    $state != 'Managed'
        ${blocker}=    Get DatabaseService Removal Blocker
        Should Be Empty    ${blocker}    DatabaseService restoration blocked. ${blocker}
    END
    Set DatabaseService Component    ${component}
    ${restored}=    Run Oc    get    ${DSC}    -o    jsonpath\={.spec.components.databaseservice}
    Should Be Equal    ${restored}    ${original}
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
