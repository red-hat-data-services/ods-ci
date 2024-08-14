*** Settings ***
Documentation      Suite to test the spawn of different notebook images
Library            SeleniumLibrary
Library            OpenShiftLibrary
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Workbenches.resource
Resource           ../../../Resources/RHOSi.resource
Suite Setup        Project Suite Setup
Suite Teardown     Project Suite Teardown
Test Tags          Dashboard


*** Variables ***
${PRJ_TITLE}    ODS-CI DS Project Notebook Images
${PRJ_RESOURCE_NAME}    notebook-images-ds-project
${PRJ_DESCRIPTION}    ${PRJ_TITLE} is a test project for validating notebook images and shared by multiple tests


*** Test Cases ***
Verify User Can Create A Workbench Using Intel AiKit Image
    [Documentation]    Verifies that a workbench can be created using Intel AiKit image
    [Tags]    ODS-2173    Tier2
    Set Test Variable   ${INTEL_AIKIT_APPNAME}  aikit
    Set Test Variable   ${INTEL_AIKIT_OPERATOR_NAME}    Intel® oneAPI AI Analytics Toolkit Operator
    Set Test Variable   ${IMG_NAME}     oneAPI AI Analytics Toolkit
    Set Test Variable   ${WORKBENCH_TITLE}      aikitwb
    Set Test Variable   ${PV_DESCRIPTION}      PV for AiKit workbench
    Check And Install Operator in Openshift    ${INTEL_AIKIT_OPERATOR_NAME}    ${INTEL_AIKIT_APPNAME}
    Create Tabname Instance For Installed Operator        ${INTEL_AIKIT_OPERATOR_NAME}
    ...    AIKitContainer    ${APPLICATIONS_NAMESPACE}
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=workbench for testing
    ...        prj_title=${PRJ_TITLE}    image_name=${IMG_NAME}  version=${NONE}    deployment_size=Small
    ...        storage=Persistent  pv_name=aikitpv  pv_existent=${FALSE}
    ...        pv_description=${PV_DESCRIPTION}  pv_size=1
    ...        press_cancel=${FALSE}    envs=${NONE}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Open Data Science Projects Home Page
    Wait Until Project Is Listed    project_title=${PRJ_TITLE}
    Launch And Access Workbench From Projects Home Page    workbench_title=${WORKBENCH_TITLE}
    ...    project_title=${PRJ_TITLE}    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}    auth_type=${TEST_USER_3.AUTH_TYPE}

Verify User Can Create A Workbench Using Code Server Image
    [Documentation]    Verifies that a workbench can be created using Code Server image
    [Tags]    Sanity    Tier1
    Set Test Variable   ${IMG_NAME}    code-server
    Set Test Variable   ${WORKBENCH_TITLE}    codeServer
    Set Test Variable   ${PV_NAME}    codeServerPv
    Set Test Variable   ${PV_DESCRIPTION}    PV for codeServer
    Create Workbench    workbench_title=${WORKBENCH_TITLE}  workbench_description=workbench for testing
    ...        prj_title=${PRJ_TITLE}    image_name=${IMG_NAME}  version=${NONE}    deployment_size=Small
    ...        storage=Persistent  pv_name=${PV_NAME}  pv_existent=${FALSE}
    ...        pv_description=${PV_DESCRIPTION}  pv_size=1
    ...        press_cancel=${FALSE}    envs=${NONE}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Open Data Science Projects Home Page
    Wait Until Project Is Listed    project_title=${PRJ_TITLE}
    Launch And Access Workbench From Projects Home Page    workbench_title=${WORKBENCH_TITLE}
    ...    project_title=${PRJ_TITLE}    username=${TEST_USER_3.USERNAME}
    ...    password=${TEST_USER_3.PASSWORD}    auth_type=${TEST_USER_3.AUTH_TYPE}
    ...    expected_ide=VSCode


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing DS Projects. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    ${to_delete}    Create List    ${PRJ_TITLE}
    Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup
    Launch Data Science Project Main Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    ...    resource_name=${PRJ_RESOURCE_NAME}    existing_project=${TRUE}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing DS Projects. It Deletes
    ...                all the DS projects created by the tests and run RHOSi teardown
    Close All Browsers
    Delete List Of Projects Via CLI   ocp_projects=${PROJECTS_TO_DELETE}
    RHOSi Teardown
