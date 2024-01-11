*** Settings ***
Documentation      Suite to test the spawn of different notebook images
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/RHOSi.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown

*** Variables ***
${PRJ_TITLE}=                  ODS-CI DS Project Notebook Images
${PRJ_RESOURCE_NAME}=   notebook-images-ds-project
${PRJ_DESCRIPTION}=   ${PRJ_TITLE} is a test project for validating notebook images and shared by multiple tests
${intel_aikit_appname}           aikit
${intel_aikit_container_name}    Intel® oneAPI AI Analytics Toolkit Container
${intel_aikit_operator_name}    Intel® oneAPI AI Analytics Toolkit Operator
${image_name}    oneAPI AI Analytics Toolkit
${workbench_title}    aikitwb
${pv_description}    PV for AiKit workbench

*** Test Cases ***
Verify user can create a workbench using Intel AiKit image
    [Documentation]    Verifies that a workbench can be created using Intel AiKit image
    [Tags]    ODS-2173    Tier2
    Check And Install Operator in Openshift    ${intel_aikit_operator_name}    ${intel_aikit_appname}
    Create Tabname Instance For Installed Operator        ${intel_aikit_operator_name}      AIKitContainer    ${APPLICATIONS_NAMESPACE}
    Go To RHODS Dashboard
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    Create Workbench    workbench_title=${workbench_title}  workbench_description=workbench for testing
    ...        prj_title=${PRJ_TITLE}    image_name=${image_name}   version=${NONE}    deployment_size=Small
    ...        storage=Persistent  pv_name=aikitpv  pv_existent=${FALSE}
    ...        pv_description=${pv_description}  pv_size=1
    ...        press_cancel=${FALSE}    envs=${NONE}
    Wait Until Workbench Is Started     workbench_title=${workbench_title}
    Open Data Science Projects Home Page
    Wait Until Project Is Listed    project_title=${PRJ_TITLE}
    Launch And Access Workbench From Projects Home Page    workbench_title=${workbench_title}
    ...    project_title=${PRJ_TITLE}    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}    auth_type=${TEST_USER_3.AUTH_TYPE}


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}=    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    # Delete All Data Science Projects From CLI
    Delete Data Science Projects From CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
