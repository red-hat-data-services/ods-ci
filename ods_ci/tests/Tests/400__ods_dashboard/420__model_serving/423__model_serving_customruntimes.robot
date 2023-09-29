*** Settings ***
Documentation     Collection of tests to validate the model serving stack for Large Language Models (LLM)
# Resource          ../../../Resources/Page/Components/Menu.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Suite Setup       Model Serving Suite Setup
# Suite Teardown

*** Variables ***


*** Test Cases ***
Verify RHODS Admins Can Import A Custom Serving Runtime By Uploading A YAML file
    [Tags]    ODS-2276
    [Setup]    Open Custom Serving Runtime Settings
    


*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Fetch CA Certificate If RHODS Is Self-Managed

Open Custom Serving Runtime Settings
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Menu.Navigate To Page    Settings    Serving Runtimes
    
