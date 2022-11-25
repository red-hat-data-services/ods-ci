*** Settings ***
Library           OperatingSystem
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource          ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Suite Setup       Model Serving Suite Setup
# Suite Teardown    Teardown Model Serving


*** Variables ***
${MODEL_MESH_NAMESPACE}=    mesh-test
${ODH_NAMESPACE}=    redhat-ods-applications
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"example-onnx-mnist__isvc-b29c3d91f3","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233053,-7.7497034,-3.4236815,12.3630295,-12.079103,17.266596,-10.570976,0.7130762,3.321715,1.3621228]}]}
${PRJ_TITLE}=    model-serving-project
${PRJ_DESCRIPTION}=    project used for model serving tests

*** Test Cases ***
# Validate Model Serving quickstart
#     [Documentation]    Test the quickstart of the model serving repo, Temporary until included in RHODS
#     [Tags]    ModelMesh_Serving
#     # TODO: Replace with http://robotframework.org/robotframework/latest/libraries/Process.html#Run%20Process
#     Run    git clone ${MS_REPO}
#     Run    cd modelmesh-serving/quickstart && ./quickstart.sh ${ODH_NAMESPACE} ${MODEL_MESH_NAMESPACE}

Verify Model Serving Installation
    [Documentation]    Verifies Model Serving resources
    [Tags]    ModelMesh_Serving
    # Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Openvino Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    # Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Minio Deployment
    # Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Verify Model Can Be Deployed Via UI
    Open Model Serving Home Page
    # Verify No Models Are Present
    Click Button  Create server
    # Verify moved to DSP page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Create S3 Data Connection    project_title=${PRJ_TITLE}    dc_name=model-serving-connection
    ...            aws_access_key=${S3.AWS_ACCESS_KEY_ID}    aws_secret_access=${S3.AWS_SECRET_ACCESS_KEY}
    ...            aws_bucket_name=ods-ci-s3
    Create Model Server
    Open Model Serving Home Page
    Serve Model    project_name=${PRJ_TITLE}    model_name=test-model    framework=onnx    existing_data_connection=${TRUE}
    ...    data_connection_name=model-serving-connection    model_path=mnist-8.onnx

Verify Served Model Status
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Openvino Deployment
    Run Keyword And Continue On Failure  Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    # Verify Status In Model Serving Page


Test Inference
    [Documentation]    Test the inference result
    [Tags]    ModelMesh_Serving_Inference
    # make sure model is being served
    # TODO: find better way to understand when model is being served
    # One option is Triton pods being both 5/5 Ready
    #Sleep  10s
    # Get Route via UI
    # Get Token via UI
    #${MS_ROUTE} =    Run    oc get routes -n ${MODEL_MESH_NAMESPACE} example-onnx-mnist --template={{.spec.host}}{{.spec.path}}
    #${AUTH_TOKEN} =    Run    oc sa new-token user-one -n ${MODEL_MESH_NAMESPACE}
    ${inference_output} =    Run    curl -ks https://${MS_ROUTE}/infer -d @modelmesh-serving/quickstart/input.json -H "Authorization: Bearer ${AUTH_TOKEN}"
    Should Be Equal As Strings    ${inference_output}    ${EXPECTED_INFERENCE_OUTPUT}


*** Keywords ***
Model Serving Suite Setup
    [Documentation]    Suite setup steps for testing DSG. It creates some test variables
    ...                and runs RHOSi setup
    Set Library Search Order    SeleniumLibrary
    #${to_delete}=    Create List    ${PRJ_TITLE}
    #Set Suite Variable    ${PROJECTS_TO_DELETE}    ${to_delete}
    RHOSi Setup

Verify Etcd Pod
    # TODO: need unique label for etcd deployment
    ${etcd_name} =    Run    oc get pod -l app=model-mesh,app.kubernetes.io/part-of=model-mesh -n ${ODH_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${ODH_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    ${service} =    Oc Get    kind=Service    namespace=${MODEL_MESH_NAMESPACE}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

# Verify Minio Deployment
#     @{minio} =  Oc Get    kind=Pod    namespace=${MODEL_MESH_NAMESPACE}    label_selector=app=minio
#     ${containerNames} =  Create List  minio
#     Verify Deployment    ${minio}  1  1  ${containerNames}

Verify ModelMesh Deployment
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  3  1  ${containerNames}

Verify odh-model-controller Deployment
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

# Temporary Label MM Namespace
#     ${label} =    Run    oc label namespace ${MODEL_MESH_NAMESPACE} opendatahub.io/generated-namespace=true --overwrite=true
#     Log    ${label}
#     Run Keyword And Continue On Failure  Should Be Equal As Strings    ${label}    namespace/${MODEL_MESH_NAMESPACE} not labeled

Verify Openvino Deployment
    # Run Keyword And Continue On Failure  Temporary Label MM Namespace
    @{ovms} =  Oc Get    kind=Pod    namespace=${MODEL_MESH_NAMESPACE}    label_selector=name=modelmesh-serving-ovms-1.x
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  ovms  ovms-adapter  mm
    Verify Deployment    ${ovms}  2  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -l name=modelmesh-serving-ovms-1.x | grep 2/2 -o
    Should Be Equal As Strings    ${all_ready}    2/2

# Delete Model Serving Resources
#     [Documentation]    wrapper keyword that runs oc commands to delete model serving stuff
#     ...    Temporary until included in RHODS
#     ${output}=    Run    cd tests/Resources/Files && ./uninstall-model-serving.sh ${ODH_NAMESPACE} ${MODEL_MESH_NAMESPACE}
#     Log  ${output}
#     # Ignore all not found for delete commands, only output should be the not found of the patch command
#     Should Be Equal As Strings    Error from server (NotFound): kfdefs.kfdef.apps.kubeflow.org "odh-modelmesh" not found    ${output}

# Teardown Model Serving
#     [Documentation]  delete modelmesh stuff, Temporary until included in RHODS
#     # Seems like it's taking 10 minutes to stop reconciling deployments
#     Wait Until Keyword Succeeds  15 min  15s  Delete Model Serving Resources
#     Run    rm -rf modelmesh-serving