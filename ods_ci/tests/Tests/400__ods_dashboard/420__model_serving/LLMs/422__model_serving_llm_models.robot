*** Settings ***
Documentation     Collection of CLI tests to validate the deployment of specific LLM models.
...               These tests leverage on TGIS Standalone Serving Runtime
Resource          ../../../../Resources/OCP.resource
Resource          ../../../../Resources/CLI/ModelServing/llm.resource
Library            OpenShiftLibrary
Suite Setup       Suite Setup
Suite Teardown    RHOSi Teardown
Test Tags         KServe


*** Variables ***
${TEST_NS}=    tgis-standalone
${TGIS_RUNTIME_NAME}=    tgis-runtime
${ACCELERATOR}=    GPU    # or ${NONE} for using CPU
${KSERVE_DEPLOYMENT_MODE}=    Raw    # or Serverless


*** Test Cases ***
Verify bigcode/starcoder Can Be Deployed And Queried
    #    Deploy Model
    #    Wait For ...
    #    Query Model ...
    #    Answer Should Be ...

Verify Models Can Be Deployed And Queries
    [Template]    Model ${model_name} Can Be Deployed And Queried Template    


*** Keywords ***
Model ${model_name} Can Be Deployed And Queried Template
    [Arguments]
    #    Deploy Model
    #    Wait For ...
    #    Query Model ...
    #    Answer Should Be ...