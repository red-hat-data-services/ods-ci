*** Settings ***
Documentation       Feast MCP server tests - deploy a FeatureStore with a standalone MCP server
...                 (spec.services.mcpServer), check that the deployment succeeds and clean up.
Library             Process
Resource            ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/Page/FeatureStore/FeatureStore.resource
Suite Setup         Prepare Feature Store Test Suite
Test Tags           ExcludeOnODH


*** Variables ***
${FEAST_MCP_CR_FILE}=           tests/Resources/Page/FeatureStore/feature_store_mcp_cr.yaml
${PRJ_TITLE}=                   test-ns-feast-mcp
${FEAST_INSTANCE_NAME}=         test-mcp-server
${MCP_CONTAINER_NAME}=          mcpserver
# Set to True by "Create Feast Instance". Defined here so the teardown works
# even when the instance was never created.
${FEAST_INSTANCES_CREATED}=     False


*** Test Cases ***
Verify Feast MCP Server Deployment
    [Documentation]    Deploy a FeatureStore with spec.services.mcpServer and check that the deployment
    ...    succeeds: the pods are ready, the McpServer condition is True and the MCP server container is ready
    [Tags]    Tier1
    ...       FeatureStore
    Feast CRD Should Have MCP Server Field
    Log To Console    Creating Data Science Project ${PRJ_TITLE}
    Create Data Science Project From CLI    ${PRJ_TITLE}    as_user=${OCP_ADMIN_USER.USERNAME}
    Create Feast Instance    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}    ${FEAST_MCP_CR_FILE}
    Log To Console    Waiting for Feast instance ${FEAST_INSTANCE_NAME} pods to be ready
    Wait For Pods To Be Ready    feast.dev/name=${FEAST_INSTANCE_NAME}    ${PRJ_TITLE}
    Wait Until Keyword Succeeds    5 min    10 s
    ...    Feast MCP Server Condition Should Be True    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}
    Feast MCP Server Container Should Be Ready    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}
    [Teardown]    Delete Feast Instance And Project    ${PRJ_TITLE}    ${FEAST_INSTANCE_NAME}


*** Keywords ***
Feast CRD Should Have MCP Server Field
    [Documentation]    Check that the FeatureStore CRD exists and has the spec.services.mcpServer field
    ${rc}    ${out}=    Run And Return Rc And Output    oc get crd featurestores.feast.dev
    Should Be Equal As Integers    ${rc}    0    msg=FeatureStore CRD not found: ${out}
    ${jsonpath}=    Catenate    SEPARATOR=
    ...    {.spec.versions[?(@.name=="v1")].schema.openAPIV3Schema
    ...    .properties.spec.properties.services.properties.mcpServer.type}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get crd featurestores.feast.dev -o jsonpath='${jsonpath}'
    Should Be Equal As Integers    ${rc}    0    msg=${out}
    Should Be Equal As Strings    ${out}    object
    ...    msg=FeatureStore CRD has no spec.services.mcpServer field, the installed operator has no MCP server support

Feast MCP Server Condition Should Be True
    [Documentation]    Check that the McpServer condition of the FeatureStore is True
    [Arguments]    ${namespace}    ${feast_instance_name}
    ${command}=    Catenate    oc get featurestore ${feast_instance_name} -n ${namespace}
    ...    -o jsonpath='{.status.conditions[?(@.type=="McpServer")].status}'
    ${rc}    ${status}=    Run And Return Rc And Output    ${command}
    Should Be Equal As Integers    ${rc}    0    msg=${status}
    Should Be Equal As Strings    ${status}    True    msg=McpServer condition is not True

Feast MCP Server Container Should Be Ready
    [Documentation]    Check that the Feast pod has a ready MCP server container
    [Arguments]    ${namespace}    ${feast_instance_name}
    ${jsonpath}=    Catenate    SEPARATOR=
    ...    {.items[*].status.containerStatuses[?(@.name=="${MCP_CONTAINER_NAME}")].ready}
    ${rc}    ${ready}=    Run And Return Rc And Output
    ...    oc get pods -l feast.dev/name=${feast_instance_name} -n ${namespace} -o jsonpath='${jsonpath}'
    Should Be Equal As Integers    ${rc}    0    msg=${ready}
    Should Be Equal As Strings    ${ready}    true    msg=MCP server container is missing or not ready
