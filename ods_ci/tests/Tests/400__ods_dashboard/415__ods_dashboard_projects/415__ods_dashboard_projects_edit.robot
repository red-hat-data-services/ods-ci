*** Settings ***
Documentation      Suite to test Data Science Projects (a.k.a DSG) feature aimed on editing the existing instances
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Setup         Launch Data Science Project Main Page
Test Teardown      Close All Browsers


*** Variables ***
${PRJ_TITLE}=                  ODS-CI DS Project Editing
${NB_IMAGE}=                   Minimal Python
${WORKBENCH_TITLE}=            ODS-CI Workbench 1
${WORKBENCH_TITLE_UPDATED}=    ${WORKBENCH_TITLE} Updated
${WORKBENCH_DESCRIPTION}=      ODS-CI Workbench 1 is a test workbench using ${NB_IMAGE} image to test DS Projects feature
${WORKBENCH_DESC_UPDATED}=     ${WORKBENCH_DESCRIPTION} Updated
${PV_BASENAME}=                ods-ci-pv
${PV_DESCRIPTION}=             ods-ci-pv is a PV created to test DS Projects feature
# PV size are in GB
${PV_SIZE}=                    2


*** Test Cases ***
Verify User Can Edit A Workbench
    [Documentation]    Verifies users can edit a workbench name and description
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-1931
    Create Data Science Project    title=${PRJ_TITLE}    description=${EMPTY}
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


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    # Delete All Data Science Projects From CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
