*** Settings ***
Documentation       Test suite for OpenShift Pipeline
Resource            ../../../RHOSi.resource
Resource            ../../../ODS.robot
Resource            ../../../Common.robot
Resource            ../../../Page/ODH/ODHDashboard/ODHDashboard.robot
Library             DateTime
Library             ../../../../../libs/DataSciencePipelinesAPI.py


*** Variables ***
${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}=    ods_ci/tests/Resources/Files/data-science-pipelines-sample.yaml
${PIPELINES_IMPORT_BTN_FORM_XP}=    xpath://footer/button[text()="Import pipeline"]
${PIPELINE_NAME_INPUT_XP}=    id:pipeline-name
${PIPELINE_DESC_INPUT_XP}=    id:pipeline-description


*** Keywords ***
Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}     namespace=${project}    # robocop: disable:line-too-long
    ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'    # robocop: disable:line-too-long
    Should Be True    ${generation_value} == 1    DataSciencePipelinesApplication created

Fill In Pipeline Import Form
    [Documentation]    Compiles the form to create a pipeline server.
    ...                It works when you start server creation from either
    ...                DS Project details page or DS Pipelines page.
    [Arguments]    ${name}    ${filepath}    ${project_title}
    ...            ${description}=${NONE}    ${press_cancel}=${FALSE}
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_FORM_XP}
    Input Text    ${PIPELINE_NAME_INPUT_XP}    ${name}
    Input Text    ${PIPELINE_DESC_INPUT_XP}    ${description}
    ${rc}    ${pwd}=    Run And Return Rc And Output    echo $PWD
    Choose File    //div[@class="pf-c-file-upload"]//input[@type="file"]    ${pwd}/${filepath}
    Element Should Be Enabled    ${PIPELINES_IMPORT_BTN_FORM_XP}
    IF    ${press_cancel} == ${TRUE}
        Click Button    ${GENERIC_CANCEL_BTN_XP}
    ELSE
        Click Button    ${PIPELINES_IMPORT_BTN_FORM_XP}
    END
