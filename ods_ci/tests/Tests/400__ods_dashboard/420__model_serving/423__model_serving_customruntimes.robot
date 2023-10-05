*** Settings ***
Documentation     Collection of tests to validate the model serving stack for Large Language Models (LLM)
# Resource          ../../../Resources/Page/Components/Menu.robot
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDashboardSettingsRuntimes.resource
Suite Setup       Model Serving Suite Setup
# Suite Teardown


*** Variables ***
${RESOURCES_DIRPATH}=        ods_ci/tests/Resources/Files
${OVMS_RUNTIME_FILEPATH}=    ${RESOURCES_DIRPATH}/ovms_servingruntime.yaml
${UPLOADED_OVMS_DISPLAYED_NAME}=    ODS-CI Custom OpenVINO Model Server

*** Test Cases ***
Verify RHODS Admins Can Import A Custom Serving Runtime By Uploading A YAML file
    [Tags]    ODS-2276
    Open Dashboard Settings    settings_page=Serving runtimes
    Upload Serving Runtime Template    runtime_filepath=${OVMS_RUNTIME_FILEPATH}
    Serving Runtime Template Should Be Listed    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    [Teardown]    Delete Serving Runtime Template From CLI    displayed_name=${UPLOADED_OVMS_DISPLAYED_NAME}
    

*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    # Fetch CA Certificate If RHODS Is Self-Managed
