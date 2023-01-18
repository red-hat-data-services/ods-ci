*** Settings ***
Documentation      Suite to test additional scenarios for Data Science Projects (a.k.a DSG) feature
Resource           ../../../Resources/OCP.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettings.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Teardown      Close All Browsers

*** Variables ***
${PRJ_TITLE}=   ODS-CI DS Project 2
${PRJ_RESOURCE_NAME}=   ods-ci-ds-project-test-additional
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating DS Project feature
${TOLERATIONS}=    workbench-tolerations
${DEFAULT_TOLERATIONS}=    NotebooksOnly   
${WORKBENCH_TITLE}=   ODS-CI Workbench Tolerations
${WORKBENCH_DESCRIPTION}=   ${WORKBENCH_TITLE} is a test workbench using to check tolerations are applied
${NB_IMAGE}=        Minimal Python
${PV_NAME}=         ods-ci-tolerations
${PV_DESCRIPTION}=         ${PV_NAME} is a PV created to test DS Projects feature
${PV_SIZE}=         1


*** Test Cases ***
Verify Notebook Tolerations Are Applied To Workbenches When Set Up
    [Documentation]    Verifies workbenches get the custom tolerations set by
    ...                admins in "Cluster Settings" page
    [Tags]    Tier1    Sanity
    ...       ODS-1969
    Open Dashboard Cluster Settings
    Set Pod Toleration Via UI    ${TOLERATIONS}
    Save Changes In Cluster Settings
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=${WORKBENCH_DESCRIPTION}
    ...                 prj_title=${PRJ_TITLE}    image_name=${NB_IMAGE}   deployment_size=Small
    ...                 storage=Persistent  pv_existent=${FALSE}    pv_name=${PV_NAME}  pv_description=${PV_DESCRIPTION}  pv_size=${PV_SIZE}
    Verify Server Workbench Has The Expected Toleration    workbench_title=${WORKBENCH_TITLE}
    ...    toleration=${TOLERATIONS}    project_title=${PRJ_TITLE}
    [Teardown]    Restore Tolerations Settings


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DSG. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    #Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    #RHOSi Teardown

Verify Server Workbench Has The Expected Toleration
    [Documentation]    Verifies notebook pod created as workbench
    ...                contains toleration
    [Arguments]    ${workbench_title}    ${project_title}    ${toleration}
    ${expected}=    Set Variable    ${toleration}:NoSchedule op=Exists
    ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${workbench_cr_name}=    Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}
    ...    namespace=${namespace}
    ${received}=    Get Pod Tolerations    ${workbench_cr_name}-0
    ...    ns=${namespace}
    List Should Contain Value  ${received}  ${expected}
    ...    msg=Unexpected Pod Toleration

Restore Tolerations Settings
    [Documentation]    Reset the notebook tolerations after testing
    Open Dashboard Cluster Settings
    Wait for RHODS Dashboard to Load    expected_page=Cluster Settings
    ...    wait_for_cards=${FALSE}
    Set Pod Toleration Via UI    ${DEFAULT_TOLERATIONS}
    Disable Pod Toleration Via UI
    Save Changes In Cluster Settings
    