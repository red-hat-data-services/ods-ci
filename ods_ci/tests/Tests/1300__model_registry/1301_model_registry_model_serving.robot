# robocop: off=too-many-calls-in-keyword
*** Settings ***
Documentation     Test suite for Model Registry Integration
Suite Setup       Prepare Model Registry Test Setup
Suite Teardown    Teardown Model Registry Test Setup
Library           OperatingSystem
Library           Process
Library           OpenShiftLibrary
Resource          ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource          ../../Resources/OCP.resource
Resource          ../../Resources/Common.robot
Resource          ../../Resources/Page/ModelRegistry/ModelRegistry.resource


*** Variables ***
${PRJ_TITLE}=                        model-registry-project-e2e
${AWS_BUCKET}=                       ${S3.BUCKET_2.NAME}
${WORKBENCH_TITLE}=                  registry-wb
${DC_S3_NAME}=                       model-registry-connection
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${SAMPLE_ONNX_MODEL}=                ${MODELREGISTRY_BASE_FOLDER}/mnist.onnx
${MR_PYTHON_CLIENT_FILES}=           ${MODELREGISTRY_BASE_FOLDER}/Python_Dependencies
${MR_PYTHON_CLIENT_WHL_VERSION}=     model_registry==0.2.8a1
${ENABLE_REST_API}=                  ${MODELREGISTRY_BASE_FOLDER}/enable_rest_api_route.yaml
${CERTS_DIRECTORY}=                  certs
${JUPYTER_NOTEBOOK}=                 MRMS_UPDATED.ipynb
${JUPYTER_NOTEBOOK_FILEPATH}=        ${MODELREGISTRY_BASE_FOLDER}/${JUPYTER_NOTEBOOK}
${DC_S3_TYPE}=                       Object storage
${MR_REGISTERED_MODEL_NAME}=         test minst
${MR_REGISTERED_MODEL_VERSION}=      2.0.0
${MR_REGISTERED_MODEL_AUTHOR}=       Tony
${MR_TABLE_XPATH}=                   //table[@data-testid="registered-model-table"]
${MR_VERSION_TABLE_XPATH}=           //table[@data-testid="model-versions-table"]


*** Test Cases ***
# robocop: disable:line-too-long
Verify Model Registry Integration With Secured-DB
    [Documentation]    Verifies the Integartion of Model Registry operator with Jupyter Notebook
    [Tags]    Smoke    MRMS1301    ModelRegistry
    Create Workbench    workbench_title=${WORKBENCH_TITLE}    workbench_description=Registry test
    ...                 prj_title=${PRJ_TITLE}    image_name=Minimal Python  deployment_size=${NONE}
    ...                 storage=Persistent   pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenches}=    Create List    ${WORKBENCH_TITLE}
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}    timeout=120s
    ${handle}=    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE}
    ...    username=${TEST_USER.USERNAME}     password=${TEST_USER.PASSWORD}
    ...    auth_type=${TEST_USER.AUTH_TYPE}
    Upload File In The Workbench     filepath=${SAMPLE_ONNX_MODEL}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Upload File In The Workbench     filepath=${JUPYTER_NOTEBOOK_FILEPATH}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Download Python Client Dependencies    ${MR_PYTHON_CLIENT_FILES}    ${MR_PYTHON_CLIENT_WHL_VERSION}
    Upload Python Client Files In The Workbench    ${MR_PYTHON_CLIENT_FILES}
    Upload Certificate To Jupyter Notebook    ${CERTS_DIRECTORY}/domain.crt
    ${self_managed} =    Is RHODS Self-Managed
    IF  ${self_managed}    Upload Certificate To Jupyter Notebook    openshift_ca.crt
    Jupyter Notebook Can Query Model Registry     ${JUPYTER_NOTEBOOK}
    SeleniumLibrary.Switch Window    ${handle}
    Add User To Model Registry Default Group    ${TEST_USER.USERNAME}
    Open Model Registry Dashboard Page
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Model name"]//a[.="${MR_REGISTERED_MODEL_NAME}"]
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Owner"]//p[.="${MR_REGISTERED_MODEL_AUTHOR}"]
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Labels" and .="-"]
    SeleniumLibrary.Click Element    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Model name"]//a[.="${MR_REGISTERED_MODEL_NAME}"]
    Maybe Wait For Dashboard Loading Spinner Page
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_VERSION_TABLE_XPATH}/tbody/tr/td[@data-label="Version name"]//a[.="${MR_REGISTERED_MODEL_VERSION}"]
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_VERSION_TABLE_XPATH}/tbody/tr/td[@data-label="Author" and .="${MR_REGISTERED_MODEL_AUTHOR}"]
    SeleniumLibrary.Close All Browsers

Verify Unallowed User Cannot See Model Registry From The Dashboard
    [Documentation]    Negative path test for dashboard RBAC on the Model Registry. User not part of the group that is
    ...    allowed to use a Model Registry instace should not be able to see it from the dashboard.
    [Tags]    Smoke    MRMS1301    ModelRegistry
    Depends On Test    Verify Model Registry Integration With Secured-DB
    Launch Dashboard    ${TEST_USER_3.USERNAME}    ${TEST_USER_3.PASSWORD}    ${TEST_USER_3.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Model Registry Dashboard Page    allowed_user=${FALSE}
    SeleniumLibrary.Page Should Contain    Request access to model registries
