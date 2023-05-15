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


*** Keywords ***
Install DataSciencePipelinesApplication CR
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    [Arguments]     ${project}
    Log    ${project}
    Oc Apply    kind=DataSciencePipelinesApplication    src=${DATA_SCIENCE_PIPELINES_APPLICATION_YAML}     namespace=${project}    # robocop: disable:line-too-long
    ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${project} -o json | jq '.items[0].metadata.generation'    # robocop: disable:line-too-long
    Should Be True    ${generation_value} == 1    DataSciencePipelinesApplication created
