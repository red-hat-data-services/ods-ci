*** Settings ***
Documentation      Suite to test Data Science Projects (a.k.a DSG) feature aimed on editing the existing instances
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=                  ODS-CI DS Project Edit
${PRJ_TITLE_2}=                ODS-CI Edit Project
${PRJ_RESOURCE_NAME}=          odscidsprojectedit
${PRJ_DESCRIPTION}=            ${PRJ_TITLE} is a test project for validating edit scenarios in DS Projects feature and shared by multiple tests    #robocop: disable
${NEW_PRJ_TITLE}=              ODS-CI DS Project Updated
${NEW_PRJ_DESCRIPTION}=        ${NEW_PRJ_TITLE} is a New edited test project for validating DS Projects feature
${NB_IMAGE}=                   Minimal Python
${WORKBENCH_TITLE}=            ODS-CI Workbench 1
${WORKBENCH_TITLE_UPDATED}=    ${WORKBENCH_TITLE} Updated
${WORKBENCH_DESCRIPTION}=      ODS-CI Workbench 1 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_DESC_UPDATED}=     ${WORKBENCH_DESCRIPTION} Updated
${PV_BASENAME}=                ods-ci-pv
${PV_DESCRIPTION}=             ods-ci-pv is a PV created to test DS Projects feature
${PV_SIZE}=                    2    # PV sizes are in GB
${DC_S3_NAME}=                 ods-ci-dc
${DC_S3_AWS_SECRET_ACCESS_KEY}=    custom dummy secret access key
${DC_S3_AWS_ACCESS_KEY}=    custom dummy access key id
${DC_S3_ENDPOINT}=    custom.endpoint.s3.com
${DC_S3_REGION}=    ods-ci-region


*** Test Cases ***
Verify User Can Edit A Data Science Project
    [Tags]    Sanity    Tier1    ODS-2112
    [Documentation]    Verifies users can edit a DS project
    [Setup]   Create Data Science Project    title=${PRJ_TITLE_2}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${NONE}
    [Teardown]    Delete Data Science Project    project_title=${NEW_PRJ_TITLE}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${PRJ_TITLE_2}
    Open Data Science Projects Home Page
    Project Should Be Listed    project_title=${PRJ_TITLE_2}
    Run Keyword And Continue On Failure         Check Resource Name Should Be Immutable    project_title=${PRJ_TITLE_2}
    Run Keyword And Continue On Failure         Check Name And Description Should Be Editable
    ...    project_title=${PRJ_TITLE_2}    new_title=${NEW_PRJ_TITLE}    new_description=${NEW_PRJ_DESCRIPTION}
    ${ns_newname}=    Get Openshift Namespace From Data Science Project   project_title=${NEW_PRJ_TITLE}
    Should Be Equal As Strings  ${ns_name}  ${ns_newname}

Verify User Can Edit A Workbench
    [Documentation]    Verifies users can edit a workbench name and description
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1931
    [Setup]    Open Data Science Project Details Page    project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}
    ...                 pv_name=${PV_BASENAME}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Workbench Status Should Be      workbench_title=${WORKBENCH_TITLE}      status=${WORKBENCH_STATUS_STARTING}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Edit Workbench    workbench_title=${WORKBENCH_TITLE}
    Input Text    ${WORKBENCH_NAME_INPUT_XP}    ${WORKBENCH_TITLE_UPDATED}
    Input Text    ${WORKBENCH_DESCR_TXT_XP}    ${WORKBENCH_DESC_UPDATED}
    Click Button    ${WORKBENCH_CREATE_BTN_2_XP}
    Workbench With Description Should Be Listed      workbench_title=${WORKBENCH_TITLE_UPDATED}
    ...                                              workbench_description=${WORKBENCH_DESC_UPDATED}
    Workbench Status Should Be      workbench_title=${WORKBENCH_TITLE_UPDATED}      status=${WORKBENCH_STATUS_RUNNING}
    [Teardown]    Clean Project From Workbench Resources    workbench_title=${WORKBENCH_TITLE_UPDATED}
    ...    project_title=${PRJ_TITLE}    pvc_title=${PV_BASENAME}

Verify User Can Edit A S3 Data Connection
    [Tags]    Sanity    Tier1    ODS-1932
    [Documentation]    Verifies users can add a Data connection to AWS S3
    [Setup]    Open Data Science Project Details Page    project_title=${PRJ_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...                          aws_access_key=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_secret_access=${DC_S3_AWS_SECRET_ACCESS_KEY}
    ...                          aws_s3_endpoint=${DC_S3_ENDPOINT}    aws_region=${DC_S3_REGION}
    Edit S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}    new_dc_name=${DC_S3_NAME}-test
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}-test    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}-test
    ...            aws_bucket_name=ods-ci-ds-pipelines-test    aws_region=${DC_S3_REGION}
    ...            aws_s3_endpoint=${DC_S3_ENDPOINT}
    ${s3_name}    ${s3_key}    ${s3_secret}    ${s3_endpoint}    ${s3_region}    ${s3_bucket}    Get Data Connection Form Values    ${DC_S3_NAME}-test
    Should Be Equal  ${s3_name}  ${DC_S3_NAME}-test
    Should Be Equal  ${s3_key}  ${S3.AWS_ACCESS_KEY_ID}-test
    Should Be Equal  ${s3_secret}  ${S3.AWS_SECRET_ACCESS_KEY}-test
    Should Be Equal  ${s3_endpoint}  ${DC_S3_ENDPOINT}
    Should Be Equal  ${s3_region}  ${DC_S3_REGION}
    Should Be Equal  ${s3_bucket}  ods-ci-ds-pipelines-test
    SeleniumLibrary.Click Button    ${GENERIC_CANCEL_BTN_XP}
    Delete Data Connection    name=${DC_S3_NAME}-test


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}
    Open Data Science Projects Home Page
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    # Delete All Data Science Projects From CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown

Check Name And Description Should Be Editable
    [Documentation]    Checks and verifies if the DSG Name and Description is editable
    [Arguments]    ${project_title}     ${new_title}    ${new_description}
    Update Data Science Project Name    ${project_title}     ${new_title}
    Update Data Science Project Description    ${new_title}    ${new_description}
    Open Data Science Project Details Page       project_title=${new_title}
    Page Should Contain    ${new_description}