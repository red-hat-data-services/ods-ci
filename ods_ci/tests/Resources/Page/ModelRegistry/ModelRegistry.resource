# robocop: off=too-many-calls-in-keyword, mixed-tabs-and-spaces, line-too-long
*** Settings ***
Documentation    Keywords to interact with Model Registry
Library          OperatingSystem
Library          Process
Library          OpenShiftLibrary
Library          SeleniumLibrary
Resource         ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource         ../../../Resources/OCP.resource
Resource         ../../../Resources/Common.robot


*** Variables ***
${PRJ_TITLE}=                        model-registry-project-e2e
${PRJ_DESCRIPTION}=                  model resgistry test project
${WORKBENCH_TITLE}=                  registry-wb
${MODELREGISTRY_BASE_FOLDER}=        tests/Resources/CLI/ModelRegistry
${SERVICE_MESH_MEMBER}=              ${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember_template.yaml
${ENABLE_REST_API}=                  ${MODELREGISTRY_BASE_FOLDER}/enable_rest_api_route.yaml
${IPYNB_UPDATE_SCRIPT}=              ${MODELREGISTRY_BASE_FOLDER}/updateIPYNB.py
${CERTS_DIRECTORY}=                  certs
${MODEL_REGISTRY_DB_SAMPLES}=        ${MODELREGISTRY_BASE_FOLDER}/samples/secure-db/mysql-tls
${NAMESPACE_ISTIO}=                  istio-system
${SECRET_PART_NAME_1}=               modelregistry-sample-rest
${SECRET_PART_NAME_2}=               modelregistry-sample-grpc
${SECRET_PART_NAME_3}=               model-registry-db
${MR_TABLE_XPATH}=                   //table[@data-testid="registered-model-table"]
${MR_VERSION_TABLE_XPATH}=           //table[@data-testid="model-versions-table"]
${DISABLE_COMPONENT}=                ${False}
${SAMPLE_ONNX_MODEL}=                ${MODELREGISTRY_BASE_FOLDER}/mnist.onnx
${MR_PYTHON_CLIENT_FILES}=           ${MODELREGISTRY_BASE_FOLDER}/Python_Dependencies
${MR_PYTHON_CLIENT_WHL_VERSION}=     model_registry==0.2.8a1
${JUPYTER_NOTEBOOK}=                 MRMS_UPDATED.ipynb
${JUPYTER_NOTEBOOK_FILEPATH}=        ${MODELREGISTRY_BASE_FOLDER}/${JUPYTER_NOTEBOOK}
${MR_REGISTERED_MODEL_NAME}=         test minst
${MR_REGISTERED_MODEL_VERSION}=      2.0.0
${MR_REGISTERED_MODEL_AUTHOR}=       Tony
${DC_S3_TYPE}=                       Object storage
${DC_S3_NAME}=                       model-registry-connection
${AWS_BUCKET}=                       ${S3.BUCKET_2.NAME}


*** Keywords ***
Prepare Model Registry Test Setup
    [Documentation]    Suite setup steps for testing Model Registry.
    Set Library Search Order    SeleniumLibrary
    ${NAMESPACE_MODEL_REGISTRY}=    Get Model Registry Namespace From DSC
    Set Suite Variable    ${NAMESPACE_MODEL_REGISTRY}
    RHOSi Setup
    Enable Model Registry If Needed
    Component Should Be Enabled    modelregistry
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Apply ServiceMeshMember Configuration
    Get Cluster Domain And Token
    Run Update Notebook Script
    Generate ModelRegistry Certificates
    Apply Db Config Samples    namespace=${NAMESPACE_MODEL_REGISTRY}
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
    Disable Model Registry If Needed
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
    Create Generic Secret    ${NAMESPACE_MODEL_REGISTRY}  ${SECRET_PART_NAME_3}-credential
    ...    certs/${SECRET_PART_NAME_3}.key           certs/${SECRET_PART_NAME_3}.crt     certs/domain.crt
    Secret Should Exist      ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_1}-credential
    Secret Should Exist      ${NAMESPACE_ISTIO}    ${SECRET_PART_NAME_2}-credential
    Secret Should Exist      ${NAMESPACE_MODEL_REGISTRY}  ${SECRET_PART_NAME_3}-credential

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
    Wait Until Page Contains Element    xpath=//div[contains(text(),"Restart") and @class="jp-Dialog-buttonLabel"]
    Click Element    xpath=//div[contains(text(),"Restart") and @class="jp-Dialog-buttonLabel"]
    # Somehow misses the check on the active cells without the sleep
    Sleep    5s
    Wait Until JupyterLab Code Cell Is Not Active  timeout=120s
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
    Copy File    source=${SERVICE_MESH_MEMBER}    destination=${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember.yaml
    Run    sed -i '' -e 's/<MODEL_REGISTRY_NS>/${NAMESPACE_MODEL_REGISTRY}/' ${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember.yaml    # robocop: disable
    Apply OpenShift Configuration    ${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember.yaml
    Remove File    ${MODELREGISTRY_BASE_FOLDER}/serviceMeshMember.yaml

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
    # We don't want to stop the teardown if any of these resources are not found
    Run Keyword And Continue On Failure
    ...    Run And Verify Command
    ...    oc delete -n ${NAMESPACE_MODEL_REGISTRY} -k ${MODELREGISTRY_BASE_FOLDER}/samples/secure-db/mysql-tls
    Run Keyword And Continue On Failure
    ...    Run And Verify Command    oc delete secret modelregistry-sample-grpc-credential -n ${NAMESPACE_ISTIO}
    Run Keyword And Continue On Failure
    ...    Run And Verify Command    oc delete secret modelregistry-sample-rest-credential -n ${NAMESPACE_ISTIO}
    # I don't think this NS should be removed, it's managed by the DSC
    # Run And Verify Command    oc delete namespace ${NAMESPACE_MODEL_REGISTRY} --force

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
    # We could add --abi=cp311 as a parameter, but it does not appear to be needed as it will default to the cpython
    # version compatible with the specific python version. If specified it will need to be updated to point to the
    # correct cpython version (e.g. cp311 for python 3.11, cp312 for python 3.12 etc.)
    Open New Notebook
    ${python_version}=    Get XY Python Version From Jupyterlab
    ${result}=    Run Process    command=pip download --platform=manylinux2014_x86_64 --python-version=${python_version} --only-binary=:all: --dest=${destination} ${package_version}    # robocop: disable:line-too-long
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

Open Model Registry Dashboard Page
    [Documentation]    Opens the Model Registry page from the dashboard nav bar
    ${mr_present}=    Run Keyword And Return Status    SeleniumLibrary.Page Should Contain    Model Registry
    WHILE    ${mr_present}!=${TRUE}    limit=120s
        SeleniumLibrary.Reload Page
        SeleniumLibrary.Wait Until Page Contains    Home
        Maybe Wait For Dashboard Loading Spinner Page
        ${mr_present}=    Run Keyword And Return Status
        ...    SeleniumLibrary.Page Should Contain    Model Registry
    END
    SeleniumLibrary.Click Link      Model Registry
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Model Registry
    SeleniumLibrary.Wait Until Page Contains    Select a model registry to view and manage your registered models.
    Maybe Wait For Dashboard Loading Spinner Page
    ${loaded}=    Run Keyword And Return Status
    ...    SeleniumLibrary.Page Should Not Contain    Request access to model registries
    WHILE    ${loaded}!=${TRUE}    limit=5
        SeleniumLibrary.Reload Page
        SeleniumLibrary.Wait Until Page Contains    Model Registry
        SeleniumLibrary.Wait Until Page Contains    Select a model registry to view and manage your registered models.
        ${loaded}=    Run Keyword And Return Status
        ...    SeleniumLibrary.Page Should Not Contain    Request access to model registries
    END
    Maybe Wait For Dashboard Loading Spinner Page

Get Model Registry Namespace From DSC
    [Documentation]    Fetches the namespace defined for model registry in the DSC
    ${rc}  ${ns}=    Run And Return Rc And Output
    ...    oc get dsc default-dsc -o json | jq '.spec.components.modelregistry.registriesNamespace'
    Should Be Equal As Integers    ${rc}    0
    Log    ${ns}
    # Remove double quotes
    ${ns}=    Get Substring    ${ns}    1    -1
    Log    ${ns}
    RETURN    ${ns}

Enable Model Registry If Needed
    [Documentation]    While in tech preview the component will not be enabled by default. This keyword enables it.
    ${management_state}=    Get DSC Component State    default-dsc    modelregistry    ${OPERATOR_NAMESPACE}
    IF    "${management_state}" != "Managed"
            Set Component State    modelregistry    Managed
            Set Suite Variable    ${DISABLE_COMPONENT}    ${True}
            Wait For Namespace To Be Active    ${NAMESPACE_MODEL_REGISTRY}    timeout=5m
    END

Disable Model Registry If Needed
    [Documentation]    If we had to enable the component before the test run, let's also disable it at the end to leave
    ...    the cluster in the same state we found it in
    IF    ${DISABLE_COMPONENT}==${True}
        Set Component State    modelregistry    Removed
        Run And Verify Command    oc delete namespace ${NAMESPACE_MODEL_REGISTRY} --force
    END

Model Registry Pre Upgrade Scenario
    [Documentation]    Creates a Model Registry instance and registers a model/version
    Prepare Model Registry Test Setup
    Create Workbench    workbench_title=${WORKBENCH_TITLE}    workbench_description=Registry test
    ...                 prj_title=${PRJ_TITLE}    image_name=Minimal Python  deployment_size=${NONE}
    ...                 storage=Persistent   pv_existent=${NONE}
    ...                 pv_name=${NONE}  pv_description=${NONE}  pv_size=${NONE}
    Workbench Should Be Listed      workbench_title=${WORKBENCH_TITLE}
    Open Data Science Project Details Page       project_title=${PRJ_TITLE}
    ${workbenches}=    Create List    ${WORKBENCH_TITLE}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=${DC_S3_NAME}
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=${AWS_BUCKET}    connected_workbench=${workbenches}
    Data Connection Should Be Listed    name=${DC_S3_NAME}    type=${DC_S3_TYPE}    connected_workbench=${workbenches}
    Open Data Science Project Details Page       project_title=${prj_title}    tab_id=workbenches
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
    Stop Workbench    workbench_title=${WORKBENCH_TITLE}
    SeleniumLibrary.Close All Browsers

Model Registry Post Upgrade Scenario
    [Documentation]    Verifies that registered model/version in pre-upgrade is present after the upgrade
    # If the component is not enabled either it got set to Removed by the upgrade or the pre-upgrade scenario failed/
    # was not run
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Component Should Be Enabled    modelregistry
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Model Registry Dashboard Page
    SeleniumLibrary.Page Should Contain Element
    ...    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Model name"]//a[.="${MR_REGISTERED_MODEL_NAME}"]
    SeleniumLibrary.Page Should Contain Element
    ...    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Owner"]//p[.="${MR_REGISTERED_MODEL_AUTHOR}"]
    SeleniumLibrary.Page Should Contain Element    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Labels" and .="-"]
    SeleniumLibrary.Click Element
    ...    xpath:${MR_TABLE_XPATH}/tbody/tr/td[@data-label="Model name"]//a[.="${MR_REGISTERED_MODEL_NAME}"]
    Maybe Wait For Dashboard Loading Spinner Page
    SeleniumLibrary.Page Should Contain Element
    ...    xpath:${MR_VERSION_TABLE_XPATH}/tbody/tr/td[@data-label="Version name"]//a[.="${MR_REGISTERED_MODEL_VERSION}"]
    SeleniumLibrary.Page Should Contain Element
    ...    xpath:${MR_VERSION_TABLE_XPATH}/tbody/tr/td[@data-label="Author" and .="${MR_REGISTERED_MODEL_AUTHOR}"]
    SeleniumLibrary.Close All Browsers
    ${return_code}    ${output}=    Run And Return Rc And Output
    ...    oc delete project ${PRJ_TITLE} --force --grace-period=0
    Should Be Equal As Integers	  ${return_code}	 0
    Log    ${output}
    ${NAMESPACE_MODEL_REGISTRY}=    Get Model Registry Namespace From DSC
    Set Suite Variable    ${NAMESPACE_MODEL_REGISTRY}
    Remove Model Registry
    Remove Deployment Files    ${CERTS_DIRECTORY}
    Remove Deployment Files    ${MODELREGISTRY_BASE_FOLDER}/Python_Dependencies
    Disable Model Registry If Needed
    RHOSi Teardown
