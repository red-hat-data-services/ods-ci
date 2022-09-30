*** Settings ***
Library           OperatingSystem
Resource          ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Suite Teardown    Teardown Model Serving


*** Variables ***
${MODEL_MESH_NAMESPACE}=    mesh-test
${ODH_NAMESPACE}=    redhat-ods-applications
${MS_REPO}=    https://github.com/opendatahub-io/modelmesh-serving
${EXPECTED_INFERENCE_OUTPUT}=    {"model_name":"example-onnx-mnist__isvc-82e2bf7ea4","model_version":"1","outputs":[{"name":"Plus214_Output_0","datatype":"FP32","shape":[1,10],"data":[-8.233052,-7.749704,-3.4236808,12.363028,-12.079106,17.26659,-10.570972,0.7130786,3.3217115,1.3621225]}]}


*** Test Cases ***
Validate Model Serving quickstart
    [Documentation]    Test the quickstart of the model serving repo, Temporary until included in RHODS
    [Tags]    Install
    # TODO: Replace with http://robotframework.org/robotframework/latest/libraries/Process.html#Run%20Process
    Run    git clone ${MS_REPO}
    Run    cd modelmesh-serving/quickstart && ./quickstart.sh ${ODH_NAMESPACE} ${MODEL_MESH_NAMESPACE}

Verify Model Serving Installation
    [Documentation]    Verifies Model Serving resources
    [Tags]    Resources
    # Needed for now in RHODS, temporary until included in RHODS
    ${label} =    Run    oc label namespace ${MODEL_MESH_NAMESPACE} opendatahub.io/generated-namespace=true
    Log    ${label}
    Run Keyword And Continue On Failure  Should Be Equal As Strings    ${label}    namespace/${MODEL_MESH_NAMESPACE} labeled
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Triton Deployment
    Wait Until Keyword Succeeds  5 min  10 sec  Verify odh-model-controller Deployment
    Wait Until Keyword Succeeds  5 min  10 sec  Verify ModelMesh Deployment
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Minio Deployment
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Serving Service
    Wait Until Keyword Succeeds  5 min  10 sec  Verify Etcd Pod

Test Inference
    [Documentation]    Test the inference result
    [Tags]    Inference
    # make sure model is being served
    # TODO: find better way to understand when model is being served
    # One option is Triton pods being both 5/5 Ready
    #Sleep  1m
    ${MS_ROUTE} =    Run    oc get routes -n ${MODEL_MESH_NAMESPACE} example-onnx-mnist --template={{.spec.host}}{{.spec.path}}
    ${AUTH_TOKEN} =    Run    oc sa new-token user-one -n ${MODEL_MESH_NAMESPACE}
    ${inference_output} =    Run    curl -ks https://${MS_ROUTE}/infer -d @modelmesh-serving/quickstart/input.json -H "Authorization: Bearer ${AUTH_TOKEN}"
    Should Be Equal As Strings    ${inference_output}    ${expected_inference_output}


*** Keywords ***
Verify Etcd Pod
    # TODO: need unique label for etcd deployment
    ${etcd_name} =    Run    oc get pod -l app=model-mesh,app.kubernetes.io/part-of=model-mesh -n ${ODH_NAMESPACE} | grep etcd | awk '{split($0, a); print a[1]}'
    ${etcd_running} =    Run    oc get pod ${etcd_name} -n ${ODH_NAMESPACE} | grep 1/1 -o
    Should Be Equal As Strings    ${etcd_running}    1/1

Verify Serving Service
    ${service} =    Oc Get    kind=Service    namespace=${MODEL_MESH_NAMESPACE}    label_selector=modelmesh-service=modelmesh-serving
    Should Not Be Equal As Strings    Error from server (NotFound): services "modelmesh-serving" not found    ${service}

Verify Minio Deployment
    @{minio} =  Oc Get    kind=Pod    namespace=${MODEL_MESH_NAMESPACE}    label_selector=app=minio
    ${containerNames} =  Create List  minio
    Verify Deployment    ${minio}  1  1  ${containerNames}

Verify ModelMesh Deployment
    @{modelmesh_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=modelmesh-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${modelmesh_controller}  1  1  ${containerNames}

Verify odh-model-controller Deployment
    @{odh_model_controller} =  Oc Get    kind=Pod    namespace=${ODH_NAMESPACE}    label_selector=control-plane=odh-model-controller
    ${containerNames} =  Create List  manager
    Verify Deployment    ${odh_model_controller}  3  1  ${containerNames}

Verify Triton Deployment
    @{triton} =  Oc Get    kind=Pod    namespace=${MODEL_MESH_NAMESPACE}    label_selector=name=modelmesh-serving-triton-2.x
    ${containerNames} =  Create List  rest-proxy  oauth-proxy  triton  triton-adapter  mm
    Verify Deployment    ${triton}  2  5  ${containerNames}
    ${all_ready} =    Run    oc get deployment -l name=modelmesh-serving-triton-2.x | grep 2/2 -o
    Should Be Equal As Strings    ${all_ready}    2/2

Delete Model Serving Resources
    [Documentation]    wrapper keyword that runs oc commands to delete model serving stuff
    ...    Temporary until included in RHODS
    ${output}=    Run    cd tests/Resources/Files && ./uninstall-model-serving.sh ${ODH_NAMESPACE} ${MODEL_MESH_NAMESPACE}
    Log  ${output}
    # Ignore all not found for delete commands, only output should be the not found of the patch command
    Should Be Equal As Strings    Error from server (NotFound): kfdefs.kfdef.apps.kubeflow.org "odh-modelmesh" not found    ${output}

Teardown Model Serving
    [Documentation]  delete modelmesh stuff, Temporary until included in RHODS
    # Seems like it's taking 10 minutes to stop reconciling deployments
    Wait Until Keyword Succeeds  15 min  1 min  Delete Model Serving Resources
    Run    rm -rf modelmesh-serving