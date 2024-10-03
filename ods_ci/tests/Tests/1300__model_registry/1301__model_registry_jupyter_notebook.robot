*** Settings ***
Documentation      Test suite for Model Registry
Suite Setup       Prepare Model Registry Test Setup
Suite Teardown    Teardown Model Registry Test Setup
Library           OperatingSystem
Library           Process
Library           OpenShiftLibrary
Resource          ../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource


*** Variables ***
${PRJ_TITLE}=                        model-registry-project
${PRJ_DESCRIPTION}=                  model resgistry test project
${AWS_BUCKET}=                       ${S3.BUCKET_2.NAME}
${WORKBENCH_TITLE}=                  registry-wb
${DC_S3_NAME}=                       model-registry-connection
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${SAMPLE_ONNX_MODEL}=                ${MODELREGISTRY_BASE_FOLDER}/mnist.onnx
${MODEL_REGISTRY_DB_SAMPLES}=        ${MODELREGISTRY_BASE_FOLDER}/samples
${JUPYTER_NOTEBOOK}=                 NotebookIntegration.ipynb
${JUPYTER_NOTEBOOK_FILEPATH}=        ${MODELREGISTRY_BASE_FOLDER}/${JUPYTER_NOTEBOOK}
${DC_S3_TYPE}=                       Object storage


*** Test Cases ***
Verify Model Registry Integration With Jupyter Notebook
    [Documentation]    Verifies the Integartion of Model Registry operator with Jupyter Notebook
    [Tags]    OpenDataHub
    ...       RHOAIENG-4501
    ...       ExcludeOnRHOAI
    ...       ModelRegistry
    Create Workbench    workbench_title=${WORKBENCH_TITLE}    workbench_description=Registry test
    ...                 prj_title=${PRJ_TITLE}    image_name=Minimal Python  deployment_size=Small
    ...                 storage=Persistent   pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=registry-wb
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenches}=    Create List    ${WORKBENCH_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${AWS_BUCKET}    connected_workbench=${workbenches}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${workbenches}
    Open Data Science Project Details Page       project_title=${prj_title}    tab_id=workbenches
    Wait Until Workbench Is Started     workbench_title=registry-wb
    Wait For Model Registry Containers To Be Ready
    Upload File In The Workbench     filepath=${SAMPLE_ONNX_MODEL}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Upload File In The Workbench     filepath=${JUPYTER_NOTEBOOK_FILEPATH}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE}
    ...    username=${TEST_USER.USERNAME}     password=${TEST_USER.PASSWORD}
    ...    auth_type=${TEST_USER.AUTH_TYPE}
    Jupyter Notebook Should Run Successfully     ${JUPYTER_NOTEBOOK}


*** Keywords ***
Prepare Model Registry Test Setup
    [Documentation]    Suite setup steps for testing Model Registry.
    Set Library Search Order    SeleniumLibrary
    # Skip If Component Is Not Enabled    modelregistry
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Apply Db Config Samples    namespace=${PRJ_TITLE}
    Fetch CA Certificate If RHODS Is Self-Managed

Apply Db Config Samples
    [Documentation]    Applying the db config samples from https://github.com/opendatahub-io/model-registry-operator
    [Arguments]    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -k ${MODEL_REGISTRY_DB_SAMPLES}/mysql -n ${namespace}
    Should Be Equal As Integers	  ${rc}	 0   msg=${out}

Teardown Model Registry Test Setup
    [Documentation]  Teardown Model Registry Suite
    JupyterLibrary.Close All Browsers
    ${return_code}    ${output}=    Run And Return Rc And Output    oc delete project ${PRJ_TITLE} --force --grace-period=0
    Should Be Equal As Integers	  ${return_code}	 0
    Log    ${output}
    RHOSi Teardown

Jupyter Notebook Should Run Successfully
    [Documentation]    Runs the test workbench and check if there was no error during execution
    [Arguments]    ${filepath}
    Open Notebook File In JupyterLab    ${filepath}
    # Open With JupyterLab Menu  Run  Run All Cells
    Open With JupyterLab Menu  Run  Restart Kernel and Run All Cells…
    Click Element    xpath=//div[contains(text(),"Restart") and @class="jp-Dialog-buttonLabel"]
    Wait Until JupyterLab Code Cell Is Not Active  timeout=120s
    Sleep    2m    msg=Waits until the jupyter notebook has completed execution of all cells
    JupyterLab Code Cell Error Output Should Not Be Visible
    SeleniumLibrary.Capture Page Screenshot
    Run Cell And Check For Errors    print("RegisteredModel:");print(registry.get_registered_model(registeredmodel_name))
    SeleniumLibrary.Capture Page Screenshot

Wait For Model Registry Containers To Be Ready
    [Documentation]    Wait for model-registry-deployment to be ready
    ${result}=    Run Process    oc wait --for\=condition\=Available --timeout\=5m -n ${PRJ_TITLE} deployment/model-registry-db
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    ${result}=    Run Process    oc wait --for\=condition\=Available --timeout\=5m -n ${PRJ_TITLE} deployment/model-registry-deployment
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
