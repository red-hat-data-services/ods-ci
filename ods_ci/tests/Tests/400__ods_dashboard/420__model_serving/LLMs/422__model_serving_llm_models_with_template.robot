*** Settings ***
Documentation     Collection of CLI tests to validate the deployment of specific LLM models.
...               These tests leverage on TGIS Standalone Serving Runtime
Test Template    Model Can Be Deployed And Queried Template

*** Variables ***
${TEST_NS}=    tgis-standalone
${TGIS_RUNTIME_NAME}=    tgis-runtime


*** Test Cases ***                     model_name            accelerator    kserve_mode
bigcode/starcoder On GPU               bigcode/starcoder     GPU            Raw
bigcode/starcoder On CPU               bigcode/starcoder     ${NONE}            Raw
meta-llama/llama-2-13b-chat On GPU     bigcode/starcoder     ${NONE}            Raw

*** Keywords ***
Model Can Be Deployed And Queried Template
    [Arguments]    ${model_name}    ${accelerator}    ${kserve_mode}
    #    Deploy Model
    #    Wait For ...
    #    Query Model ...
    #    Answer Should Be ...
    Log    deploying ${model_name}