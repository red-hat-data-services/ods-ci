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
# Set to True by "Create Feast Instance". Defined here so the teardown works
# even when the instance was never created.
${FEAST_INSTANCES_CREATED}=     False


*** Test Cases ***
Verify Feast MCP Server Deployment
    [Documentation]    Deploy a FeatureStore with spec.services.mcpServer and check that the deployment
    ...    succeeds: the pods are ready, the McpServer condition is True and the MCP server container is ready
    [Tags]    Tier1
    ...       FeatureStore
    ...       RHOAIENG-101800
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
