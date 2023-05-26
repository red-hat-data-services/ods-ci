*** Settings ***
Documentation    Collection of keywords to interact with DS Pipelines
Resource       Projects.resource


*** Variables ***
${PIPELINES_SECTION_XP}=    xpath://div[@id="pipelines-projects"]
${PIPELINES_SERVER_BTN_XP}=    xpath://button[text()="Create a pipeline server"]
${PIPELINES_SERVER_CONFIG_BTN_XP}=    xpath://button[text()="Configure"]
${PIPELINES_IMPORT_BTN_XP}=    xpath://button[text()="Import pipeline"]


*** Keywords ***
Create Pipeline server
    [Documentation]    Creates the DS Pipeline server from DS Project details page
    ...                It assumes the Data Connection is aleady created
    ...                and you wants to use defaul DB configurations [TEMPORARY]
    [Arguments]    ${dc_name}
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_IMPORT_BTN_XP}
    Element Should Be Enabled    ${PIPELINES_SERVER_BTN_XP}
    Click Button    ${PIPELINES_SERVER_BTN_XP}
    Wait Until Generic Modal Appears
    Run Keyword And Continue On Failure    Element Should Be Disabled    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    Select Data Connection    dc_name=${dc_name}
    Element Should Be Enabled    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    # Sleep    10s    Waiting to give time the dc secret to be fully ready
    Click Element    ${PIPELINES_SERVER_CONFIG_BTN_XP}
    Wait Until Generic Modal Disappears

Select Data Connection
    [Documentation]    Selects an existing data connection from the dropdown
    ...                in the modal for Pipeline Server creation
    [Arguments]    ${dc_name}
    Click Element    css:form div span button[aria-label="Options menu"]
    Wait Until Page Contains Element    xpath://button[text()="${dc_name}"]
    Click Element    xpath://button[text()="${dc_name}"]

Verify Pipeline Server Deployments
    [Documentation]    Verifies the correct deployment of modelmesh in the rhods namespace
    [Arguments]    ${project_title}
    ${namespace}=    Get Openshift Namespace From Data Science Project
    ...    project_title=${project_title}
    @{persistenceagent} =  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-pipelines-definition
    ${containerNames} =  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${persistenceagent}  1  1  ${containerNames}

    @{pipeline_definition} =  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-pipelines-definition
    ${containerNames} =  Create List  oauth-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_definition}  1  2  ${containerNames}

    @{schedule_workflow} =  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-pipelines-definition
    ${containerNames} =  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${schedule_workflow}  1  1  ${containerNames}

    @{db} =  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-pipelines-definition
    ${containerNames} =  Create List  mariadb
    Verify Deployment    ${db}  1  1  ${containerNames}

