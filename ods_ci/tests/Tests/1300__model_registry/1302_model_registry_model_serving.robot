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


*** Variables ***
${PRJ_TITLE}=                        model-registry-project-tony
${PRJ_DESCRIPTION}=                  model resgistry test project
${AWS_BUCKET}=                       ${S3.BUCKET_2.NAME}
${WORKBENCH_TITLE}=                  registry-wb
${DC_S3_NAME}=                       model-registry-connection
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${EXAMPLE_ISTIO_ENV}=                ${MODELREGISTRY_BASE_FOLDER}/samples/istio/components/example_istio.env
${ISTIO_ENV}=                        ${MODELREGISTRY_BASE_FOLDER}/samples/istio/components/istio.env
${SAMPLE_ONNX_MODEL}=                ${MODELREGISTRY_BASE_FOLDER}/mnist.onnx
${MR_PYTHON_CLIENT_FILES}=           ${MODELREGISTRY_BASE_FOLDER}/Python_Dependencies
${MR_PYTHON_CLIENT_WHL_VERSION}=     model_registry==0.2.5a1
${SERVICE_MESH_MEMBER}=              ${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember.yaml
${ENABLE_REST_API}=                  ${MODELREGISTRY_BASE_FOLDER}/enable_rest_api_route.yaml
${IPYNB_UPDATE_SCRIPT}=              ${MODELREGISTRY_BASE_FOLDER}/updateIPYNB.py
${CERTS_DIRECTORY}=                  certs
${MODEL_REGISTRY_DB_SAMPLES}=        ${MODELREGISTRY_BASE_FOLDER}/samples/secure-db/mysql-tls
${JUPYTER_NOTEBOOK}=                 MRMS_UPDATED.ipynb
${JUPYTER_NOTEBOOK_FILEPATH}=        ${MODELREGISTRY_BASE_FOLDER}/${JUPYTER_NOTEBOOK}
${DC_S3_TYPE}=                       Object storage
${NAMESPACE_ISTIO}=                  istio-system
${NAMESPACE_MODEL-REGISTRY}=         odh-model-registries
${SECRET_PART_NAME_1}=               modelregistry-sample-rest
${SECRET_PART_NAME_2}=               modelregistry-sample-grpc
${SECRET_PART_NAME_3}=               model-registry-db


*** Test Cases ***
# robocop: disable:line-too-long
Verify Model Registry Integration With Secured-DB
    [Documentation]    Verifies the Integartion of Model Registry operator with Jupyter Notebook
    [Tags]    OpenDataHub    MRMS1302
    Create Workbench    workbench_title=${WORKBENCH_TITLE}    workbench_description=Registry test
    ...                 prj_title=${PRJ_TITLE}    image_name=Minimal Python  deployment_size=Small
    ...                 storage=Persistent   pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=registry-wb
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenches}=    Create List    ${WORKBENCH_TITLE}
    # Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    # ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    # ...            aws_bucket_name=${AWS_BUCKET}    connected_workbench=${workbenches}
    # Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${workbenches}
    # Open Data Science Project Details Page       project_title=${prj_title}    tab_id=workbenches
    Wait Until Workbench Is Started     workbench_title=registry-wb
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${AWS_BUCKET}    connected_workbench=${workbenches}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${workbenches}
    Open Data Science Project Details Page       project_title=${prj_title}    tab_id=workbenches
    Wait Until Workbench Is Started     workbench_title=${WORKBENCH_TITLE}
    Upload File In The Workbench     filepath=${SAMPLE_ONNX_MODEL}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Upload File In The Workbench     filepath=${JUPYTER_NOTEBOOK_FILEPATH}    workbench_title=${WORKBENCH_TITLE}
    ...         workbench_namespace=${PRJ_TITLE}
    Download Python Client Dependencies    ${MR_PYTHON_CLIENT_FILES}    ${MR_PYTHON_CLIENT_WHL_VERSION}
    Upload Python Client Files In The Workbench    ${MR_PYTHON_CLIENT_FILES}
    Launch And Access Workbench    workbench_title=${WORKBENCH_TITLE}
    ...    username=${TEST_USER.USERNAME}     password=${TEST_USER.PASSWORD}
    ...    auth_type=${TEST_USER.AUTH_TYPE}
    Upload Certificate To Jupyter Notebook    ${CERTS_DIRECTORY}/domain.crt
    Jupyter Notebook Can Query Model Registry     ${JUPYTER_NOTEBOOK}


*** Keywords ***
Prepare Model Registry Test Setup
    [Documentation]    Suite setup steps for testing Model Registry.
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create Namespace In Openshift    ${NAMESPACE_MODEL-REGISTRY}
    Apply ServiceMeshMember Configuration
    Get Cluster Domain And Token
    Run Update Notebook Script
    Copy File    ${EXAMPLE_ISTIO_ENV}    ${ISTIO_ENV}
    Append Key Value To Env File    ${ISTIO_ENV}    DOMAIN    ${DOMAIN}
    File Should Exist    ${ISTIO_ENV}
    Log File Content    ${ISTIO_ENV}
    Generate ModelRegistry Certificates
    Apply Db Config Samples    namespace=${NAMESPACE_MODEL-REGISTRY}
    Create Model Registry Secrets
    Fetch CA Certificate If RHODS Is Self-Managed

Teardown Model Registry Test Setup
    [Documentation]  Teardown Model Registry Suite
    JupyterLibrary.Close All Browsers
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc delete project ${PRJ_TITLE} --force --grace-period=0
    Should Be Equal As Integers	  ${return_code}	 0
    Log    ${output}
    Remove Model Registry
    Remove Deployment Files    ${CERTS_DIRECTORY}
    Remove Deployment Files    ${MODELREGISTRY_BASE_FOLDER}/Python_Dependencies
    RHOSi Teardown

Get Cluster Domain And Token
    [Documentation]  Logs the Domain and Token capture.
    ${domain}=    Get Domain
    ${token}=    Get Token
    Set Suite Variable    ${DOMAIN}    ${domain}
    Set Suite Variable    ${TOKEN}    ${token}
    Log    Domain: ${DOMAIN}

Generate ModelRegistry Certificates
    [Documentation]    Generates OpenSSL certificates for Model-Registry using the generate_certs.sh script.
    ${output}=    Run Process    pwd    shell=True    stdout=PIPE
    Log    Bash Command Output: ${output.stdout}
    ${generate_certs_script}=    Set Variable    tests/Resources/CLI/ModelRegistry/generate_certs.sh
    ${certs_dir}=    Set Variable    certs
    ${cert_files}=    Create List
    ...    ${certs_dir}/domain.crt    ${certs_dir}/domain.key    ${certs_dir}/model-registry-db.crt
    ...    ${certs_dir}/model-registry-db.csr    ${certs_dir}/model-registry-db.key
    ...    ${certs_dir}/modelregistry-sample-grpc.domain.crt    ${certs_dir}/modelregistry-sample-grpc.domain.csr
    ...    ${certs_dir}/modelregistry-sample-grpc.domain.ext    ${certs_dir}/modelregistry-sample-grpc.domain.key
    ...    ${certs_dir}/modelregistry-sample-rest.domain.crt    ${certs_dir}/modelregistry-sample-rest.domain.csr
    ...    ${certs_dir}/modelregistry-sample-rest.domain.ext    ${certs_dir}/modelregistry-sample-rest.domain.key
    Generate Local ModelRegistry Certificates    ${DOMAIN}    ${generate_certs_script}    ${cert_files}

Generate Local ModelRegistry Certificates
    [Documentation]    Generates ModelRegistry certificates using the generate_certs.sh script
    [Arguments]    ${domain}    ${generate_certs_script}    ${cert_files}
    Run Process    ${generate_certs_script}    ${domain}    stdout=PIPE    stderr=PIPE
    Check Certificate Files Created    ${cert_files}

Create Model Registry Secrets
    [Documentation]    Create multiple generic secrets in the specified namespace with specified files
    Create Generic Secret    ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_1}-credential
    ...    certs/${SECRET_PART_NAME_1}.domain.key    certs/${SECRET_PART_NAME_1}.domain.crt    certs/domain.crt
    Create Generic Secret    ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_2}-credential
    ...    certs/${SECRET_PART_NAME_2}.domain.key    certs/${SECRET_PART_NAME_2}.domain.crt    certs/domain.crt
    Create Generic Secret    ${NAMESPACE_MODEL-REGISTRY}  ${SECRET_PART_NAME_3}-credential
    ...    certs/${SECRET_PART_NAME_3}.key           certs/${SECRET_PART_NAME_3}.crt     certs/domain.crt
    Secret Should Exist      ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_1}-credential
    Secret Should Exist      ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_2}-credential
    Secret Should Exist      ${NAMESPACE_MODEL-REGISTRY}  ${SECRET_PART_NAME_3}-credential

Secret Should Exist
    [Documentation]    Check if the specified secret exists in the given namespace
    [Arguments]    ${namespace}    ${secret_name}
    ${output}=    Run Process    oc get secret ${secret_name} -n ${namespace}    shell=True
    Should Contain    ${output.stdout}    ${secret_name}

Check Certificate Files Created
    [Documentation]    Checks that all expected certificate files have been created
    [Arguments]    ${cert_files}
    ${file_count}=    Get Length    ${cert_files}
    Should Be Equal As Numbers    ${file_count}    13    The number of certificate files created should be 13
    FOR    ${file}    IN    @{cert_files}
        File Should Exist    ${file}
    END

Upload Certificate To Jupyter Notebook
    [Documentation]    Uploads file to Jupyter Notebook
    [Arguments]    ${domain_cert}
    Upload File In The Workbench     filepath=${domain_cert}    workbench_title=${WORKBENCH_TITLE}
    ...    workbench_namespace=${PRJ_TITLE}

Create Generic Secret
    [Documentation]    Creates Secret for model registry in a given namespace
    [Arguments]    ${namespace}    ${secret_name}    ${key_file}    ${crt_file}    ${ca_file}
    Log    This is the secret name ${secret_name}
    ${command}=    Set Variable
    ...    oc create secret -n ${namespace} generic ${secret_name} --from-file=tls.key=${key_file} --from-file=tls.crt=${crt_file} --from-file=ca.crt=${ca_file}    # robocop: disable:line-too-long
    Run Process    ${command}    shell=True
    Log    Secret ${secret_name}, namespace ${namespace}
    ${output}=    Run Process    oc get secret ${secret_name} -n ${namespace}    shell=True
    Should Contain    ${output.stdout}    ${secret_name}

Apply Db Config Samples
    [Documentation]    Applying the db config samples from https://github.com/opendatahub-io/model-registry-operator
    [Arguments]    ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc apply -k ${MODEL_REGISTRY_DB_SAMPLES} -n ${namespace}
    Should Be Equal As Integers	  ${rc}	 0   msg=${out}

Jupyter Notebook Can Query Model Registry
    [Documentation]    Runs the test workbench and check if there was no error during execution
    [Arguments]    ${filepath}
    Open Notebook File In JupyterLab    ${filepath}
    Open With JupyterLab Menu  Run  Restart Kernel and Run All Cells…
    Click Element    xpath=//div[contains(text(),"Restart") and @class="jp-Dialog-buttonLabel"]
    Wait Until JupyterLab Code Cell Is Not Active  timeout=120s
    Sleep    2m    msg=Waits until the jupyter notebook has completed execution of all cells
    JupyterLab Code Cell Error Output Should Not Be Visible
    SeleniumLibrary.Capture Page Screenshot

Wait For Model Registry Containers To Be Ready
    [Documentation]    Wait for model-registry-deployment to be ready
    ${result}=    Run Process
    ...        oc wait --for\=condition\=Available --timeout\=5m -n ${PRJ_TITLE} deployment/model-registry-db
    ...        shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    ${result}=    Run Process
    ...        oc wait --for\=condition\=Available --timeout\=5m -n ${PRJ_TITLE} deployment/model-registry-deployment
    ...        shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}

Get Domain
    [Documentation]  Gets the Domain and returns it to 'Get Cluster Domain And Token'.
    # Run the command to get the ingress domain
    ${domain_result}=    Run Process    oc    get    ingresses.config/cluster
    ...    -o    yaml    stdout=PIPE    stderr=PIPE
    ${rc}=    Set Variable    ${domain_result.rc}
    IF    $rc > 0    Fail    Command 'oc whoami -t' returned non-zero exit code: ${rc}
    ${domain_yaml_output}=    Set Variable    ${domain_result.stdout}

    # Return the domain from stdout
    ${domain_parsed_yaml}=    Evaluate    yaml.load('''${domain_yaml_output}''', Loader=yaml.FullLoader)
    ${ingress_domain}=    Set Variable    ${domain_parsed_yaml['spec']['domain']}

    # Return both results
    RETURN    ${ingress_domain}

Get Token
    [Documentation]    Gets the Token and returns it to 'Get Cluster Domain And Token'.
    ${token_result}=    Run Process    oc    whoami    -t    stdout=YES
    ${rc}=    Set Variable    ${token_result.rc}
    IF    ${rc} > 0    Fail    Command 'oc whoami -t' returned non-zero exit code: ${rc}
    ${token}=    Set Variable    ${token_result.stdout}
    RETURN    ${token}

Apply ServiceMeshMember Configuration
    [Documentation]    Apply a ServiceMeshMember configuration using oc.
    Apply OpenShift Configuration    ${SERVICE_MESH_MEMBER}

Apply Rest API Configuration
    [Documentation]    Apply a Rest API configuration using oc.
    Apply OpenShift Configuration    ${ENABLE_REST_API}

Log File Content
    [Documentation]    Logs the contents of given file
    [Arguments]    ${file_path}
    ${content}=    Get File    ${file_path}
    Log    ${content}

Append Key Value To Env File
    [Documentation]    Applies key and value to an env file
    [Arguments]    ${env_file}    ${key}    ${value}
    ${formatted_line}=    Set Variable    \n${key}=${value}
    Append To File    ${env_file}    ${formatted_line}

Run Update Notebook Script
    [Documentation]    Update the notebook
    ${result}=    Run Process    python
    ...    ${IPYNB_UPDATE_SCRIPT}    stdout=TRUE    stderr=TRUE
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Contain    ${result.stdout}    Modified notebook saved

Remove Model Registry
    [Documentation]    Run multiple oc delete commands to remove model registry components
    Run And Verify Command    oc delete smm default -n ${NAMESPACE_MODEL-REGISTRY}
    Run And Verify Command    oc delete -k ${MODELREGISTRY_BASE_FOLDER}/samples/secure-db/mysql-tls
    Run And Verify Command    oc delete secret modelregistry-sample-grpc-credential -n ${NAMESPACE_ISTIO}
    Run And Verify Command    oc delete secret modelregistry-sample-rest-credential -n ${NAMESPACE_ISTIO}
    Run And Verify Command    oc delete namespace ${NAMESPACE_MODEL-REGISTRY} --force

Remove Deployment Files
    [Documentation]    Remove all files from the given directory
    [Arguments]  ${directory}
    ${files}=    List Files In Directory    ${directory}
    FOR    ${file}    IN    @{files}
        Remove Files  ${directory}/${file}
    END

Download Python Client Dependencies
    [Documentation]  Download the model-registry package for a specific platform
    [Arguments]  ${destination}  ${package_version}
    ${result}=    Run Process    command=pip download --platform=manylinux2014_x86_64 --python-version=3.9 --abi=cp39 --only-binary=:all: --dest=${destination} ${package_version}    # robocop: disable:line-too-long
    ...    shell=yes
    Should Be Equal As Numbers  ${result.rc}  0  ${result.stderr}

Upload Python Client Files In The Workbench
    [Documentation]    Uploads the dependency files for python client installation
    [Arguments]  ${file_location}
    ${files}=  List Files In Directory  ${file_location}
    FOR  ${file}  IN  @{files}
        Upload File In The Workbench
        ...    filepath=${file_location}/${file}    workbench_title=${WORKBENCH_TITLE}
        ...    workbench_namespace=${PRJ_TITLE}
    END
