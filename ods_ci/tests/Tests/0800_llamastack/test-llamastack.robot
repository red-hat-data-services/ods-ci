*** Settings ***
Documentation       Deploying LlamaStack following ODH docs: https://github.com/opendatahub-io/llama-stack-k8s-operator/blob/odh/docs/odh/llama-stack-with-odh.md

Resource            ../../Resources/OCP.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/ServiceMesh.resource


*** Variables ***
${LLAMASTACK_NAMESPACE}         llamastack
${LLAMASTACK_CR_FILE}           ./tests/Resources/Files/llamastack/llamastackdistribution.yaml
${NOTEBOOK_CR_FILE}             ./tests/Resources/Files/llamastack/notebook.yaml
${CONNECTION_CR_FILE}           ./tests/Resources/Files/llamastack/connection.yaml
${INFERENCE_SERVICE_CR_FILE}    ./tests/Resources/Files/llamastack/inferenceservice.yaml
${SERVING_RUNTIME_CR_FILE}      ./tests/Resources/Files/llamastack/servingruntime.yaml
${LLAMASTACK_CR_NAME}           llamastack-custom-distribution
${NOTEBOOK_CR_NAME}             llamastack-notebook
${LLAMASTACK_INFERENCE_SCRIPT}  ./tests/Resources/Files/llamastack/llamastack_inference.py
${NOTEBOOK_PV_CR_FILE}          ./tests/Resources/Files/llamastack/notebook-pvc.yaml


*** Test Cases ***
Setup LlamaStack Environment
    [Documentation]    Sets up the LlamaStack environment with connection, inference service, and distribution
    [Tags]      llamastack          Integration     Resources-GPU       NVIDIA-GPUs
    [Setup]     Setup Test Environment

    # Create connection by creating a secret from CONNECTION_CR_FILE
    Run And Verify Command    oc apply -f ${CONNECTION_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    # Create inference service from INFERENCE_SERVICE_CR_FILE
    Run And Verify Command    oc apply -f ${INFERENCE_SERVICE_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    # Verify the model deployment with retry logic
    Wait Until Keyword Succeeds    5 min    20s    Verify Model Deployment

    # Create LlamaStackDistribution CR
    Run And Verify Command    oc apply -f ${LLAMASTACK_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    Verify LlamaStack Deployment

Deploy LlamaStack Notebook
    [Documentation]    Deploys and verifies the LlamaStack notebook with PVC
    [Tags]      llamastack          Integration     Resources-GPU       NVIDIA-GPUs

    # Create notebook PVC
    Run And Verify Command    oc apply -f ${NOTEBOOK_PV_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    # Create Notebook CR
    Run And Verify Command    oc apply -f ${NOTEBOOK_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    # Verify the notebook deployment with retry logic
    Wait Until Keyword Succeeds    5 min    20s     Verify Notebook CR Is Running    ${NOTEBOOK_CR_NAME}

Test LlamaStack Inference
    [Documentation]    Tests LlamaStack inference by installing dependencies and running Python script
    [Tags]      llamastack          Integration     Resources-GPU       NVIDIA-GPUs

    # Install dependencies
    Run Command In Container    pip install llama-stack

    # Copy Python script to container
    Copy File To Container    ${LLAMASTACK_INFERENCE_SCRIPT}    /opt/app-root/src/llamastack_inference.py

    # Execute complete Python test script
    Run Command In Container    python /opt/app-root/src/llamastack_inference.py

    [Teardown]      Teardown Test Environment


*** Keywords ***
Setup Test Environment
    [Documentation]    Sets up the test environment by checking CRD, creating namespace, and configuring DSCI
    RHOSi Setup

    # Create namespace for the distribution
    Create Namespace In Openshift    ${LLAMASTACK_NAMESPACE}
    Wait For Namespace To Be Active    ${LLAMASTACK_NAMESPACE}

    # Create serving runtime from YAML
    Create Serving Runtime From YAML

    # Wait for serving runtime to be ready
    Wait Until Keyword Succeeds    2 min    10s    Check Serving Runtime Ready

    # Set DSCI serviceMesh managementState to Removed
    Set Service Mesh Management State    Removed    ${APPLICATIONS_NAMESPACE}

    # Configure DSC components
    Configure DSC Components

    # Ensure the CRD is present
    Wait Until CRD Exists    llamastackdistributions.llamastack.io

    # Verify the setup by checking that required pods are running
    Verify Required Pods Are Running

Configure DSC Components
    [Documentation]    Configures DSC components: sets kserve.serving.managementState to Removed,
    ...    kserve.defaultDeploymentMode to RawDeployment, kserve.RawDeploymentServiceConfig to Headed,
    ...    and llamastackoperator.managementState to Managed
    # Apply all DSC component changes in a single patch operation
    ${patch_data}=    Set Variable    [{"op": "replace", "path": "/spec/components/kserve/serving/managementState", "value": "Removed"}, {"op": "replace", "path": "/spec/components/kserve/defaultDeploymentMode", "value": "RawDeployment"}, {"op": "replace", "path": "/spec/components/kserve/RawDeploymentServiceConfig", "value": "Headed"}, {"op": "replace", "path": "/spec/components/llamastackoperator/managementState", "value": "Managed"}]        #robocop: disable: line-too-long
    ${rc}    ${output}=    Run And Return Rc And Output    oc patch DataScienceCluster/default-dsc -n ${OPERATOR_NAMESPACE} --type='json' -p='${patch_data}'        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to configure DSC components: ${output}
    Log    Successfully configured DSC components: kserve.serving.managementState=Removed, kserve.defaultDeploymentMode=RawDeployment, kserve.RawDeploymentServiceConfig=Headed, llamastackoperator.managementState=Managed     #robocop: disable: line-too-long
    # Verify the patch was applied correctly
    ${rc}    ${current_state}=    Run And Return Rc And Output    oc get DataScienceCluster/default-dsc -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.components.kserve.serving.managementState}'        #robocop: disable: line-too-long
    Should Be Equal As Strings    ${current_state}    Removed    msg=DSC patch verification failed: kserve.serving.managementState is not Removed    #robocop: disable: line-too-long

Create Serving Runtime From YAML
    [Documentation]    Creates a serving runtime from YAML file in the llamastack namespace
    ${rc}    ${output}=    Run And Return Rc And Output    oc apply -f ${SERVING_RUNTIME_CR_FILE} -n ${LLAMASTACK_NAMESPACE}        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to create serving runtime: ${output}
    Log    Successfully created serving runtime: ${output}

Check Serving Runtime Ready
    [Documentation]    Checks that the serving runtime is ready - used by Wait Until Keyword Succeeds
    ${rc}    ${output}=    Run And Return Rc And Output    oc get servingruntime llama-32-3b-instruct -n ${LLAMASTACK_NAMESPACE}        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Serving runtime not found: ${output}
    Log    Serving runtime is ready: ${output}

Check LlamaStackDistribution Pod Ready
    [Documentation]    Checks that LlamaStack pods have all required conditions set to True
    ...    - used by Wait Until Keyword Succeeds
    # Get LlamaStackDistribution pod and check its conditions
    ${pods}=    Get LlamaStackDistribution Pod

    # Get the single pod (there should be only one)
    @{pod_list}=    Split String    ${pods}
    ${pod}=    Get From List    ${pod_list}    0
    Log    Checking pod conditions for: ${pod}

    # Check all required conditions at once
    Check All Pod Conditions    ${pod}

    Log    All LlamaStack pods have required conditions set to True

Get LlamaStackDistribution Pod
    [Documentation]    Gets the LlamaStackDistribution pod and validates it exists
    ${rc}    ${pods}=    Run And Return Rc And Output    oc get pods -n ${LLAMASTACK_NAMESPACE} -l app=llama-stack -o name        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to get LlamaStack pods: ${pods}
    Should Not Be Empty    ${pods}    msg=No LlamaStack pods found
    RETURN    ${pods}

Check Pod Condition
    [Documentation]    Checks a specific pod condition
    [Arguments]    ${pod}    ${condition_type}
    ${jp}=    Set Variable    {.status.conditions[?(@.type=="${condition_type}")].status}
    ${rc}    ${status}=    Run And Return Rc And Output    oc get ${pod} -n ${LLAMASTACK_NAMESPACE} -o jsonpath='${jp}'        #robocop: disable:line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to get ${condition_type} status for ${pod}: ${status}
    Should Not Be Empty    ${status}    msg=Condition ${condition_type} not found for ${pod}
    Should Be Equal As Strings    ${status}    True    msg=${condition_type} is not True for ${pod}: ${status}

Get First Pod By Name
    [Documentation]    Gets the first pod by name in the specified namespace
    [Arguments]    ${namespace}    ${pod_name_pattern}
    ${rc}    ${pods}=    Run And Return Rc And Output    oc get pods -n ${namespace} -l app=${pod_name_pattern} -o name        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to get pods for ${pod_name_pattern} in namespace ${namespace}: ${pods}        #robocop: disable: line-too-long
    Should Not Be Empty    ${pods}    msg=No pods found for ${pod_name_pattern} in namespace ${namespace}
    @{pod_list}=    Split String    ${pods}
    ${first_pod}=    Get From List    ${pod_list}    0
    # Remove the 'pod/' prefix from the pod name
    ${pod_name}=    Remove String    ${first_pod}    pod/
    RETURN    ${pod_name}

Check All Pod Conditions
    [Documentation]    Checks all required pod conditions at once
    [Arguments]    ${pod}
    # Check each required condition
    Check Pod Condition    ${pod}    PodReadyToStartContainers
    Check Pod Condition    ${pod}    Initialized
    Check Pod Condition    ${pod}    Ready
    Check Pod Condition    ${pod}    ContainersReady
    Check Pod Condition    ${pod}    PodScheduled
    Log    All conditions are True for pod: ${pod}

Revert DSC Components
    [Documentation]    Reverts DSC components to their original state: sets kserve.serving.managementState to Managed,
    ...    kserve.defaultDeploymentMode to Serverless, removes kserve.RawDeploymentServiceConfig,
    ...    and sets llamastackoperator.managementState to Removed
    # Revert most DSC component changes in a single patch operation (except RawDeploymentServiceConfig)
    ${revert_patch_data}=    Set Variable    [{"op": "replace", "path": "/spec/components/kserve/serving/managementState", "value": "Managed"}, {"op": "replace", "path": "/spec/components/kserve/defaultDeploymentMode", "value": "Serverless"}, {"op": "replace", "path": "/spec/components/llamastackoperator/managementState", "value": "Removed"}]        #robocop: disable: line-too-long
    ${rc}    ${output}=    Run And Return Rc And Output    oc patch DataScienceCluster/default-dsc -n ${OPERATOR_NAMESPACE} --type='json' -p='${revert_patch_data}'        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to revert DSC components: ${output}

    # Try to remove RawDeploymentServiceConfig if it exists, ignore if it doesn't
    ${remove_patch_data}=    Set Variable    [{"op": "remove", "path": "/spec/components/kserve/RawDeploymentServiceConfig"}]        #robocop: disable: line-too-long
    ${output}=    Run And Return Rc And Output    oc patch DataScienceCluster/default-dsc -n ${OPERATOR_NAMESPACE} --type='json' -p='${remove_patch_data}' 2>&1 || true        #robocop: disable: line-too-long
    Log    RawDeploymentServiceConfig removal attempted: ${output}

    Log    Successfully reverted DSC components to original state

Verify Required Pods Are Running
    [Documentation]    Verifies that kserve-controller-manager and odh-model-controller
    ...    pods are running with retry logic
    Wait Until Keyword Succeeds    5 min    30s    Check Required Pods Are Running

Check Required Pods Are Running
    [Documentation]    Single check for required pods - used by Wait Until Keyword Succeeds
    ${grep_pattern}=    Set Variable    kserve-controller-manager|odh-model-controller
    ${rc}    ${output}=    Run And Return Rc And Output    oc get pods -n ${APPLICATIONS_NAMESPACE} | grep -E '${grep_pattern}'        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Required pods are not running: ${output}
    Should Contain    ${output}    kserve-controller-manager    msg=kserve-controller-manager pod not found
    Should Contain    ${output}    odh-model-controller    msg=odh-model-controller pod not found
    Log    Required pods are running: ${output}

Verify Model Deployment
    [Documentation]    Verifies that the inference service and llama pods are properly deployed and running
    # Check that the inference service exists
    ${rc}    ${output}=    Run And Return Rc And Output    oc get inferenceservice -n ${LLAMASTACK_NAMESPACE}        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Inference service not found: ${output}

    # Wait for all pods to be up and running
    Wait For Pods To Be Ready
    ...    label_selector=app=isvc.llama-3-2-3b-instruct-predictor
    ...    namespace=${LLAMASTACK_NAMESPACE}
    ...    timeout=5m
    Log    Model deployment verified successfully: all pods are running

Verify LlamaStack Deployment
    [Documentation]    Verifies that the LlamaStack deployment is working by checking
    ...    for pods in the namespace and the llamastackdistribution CR
    # Check that the llamastackdistribution CR exists
    ${rc}    ${output}=    Run And Return Rc And Output    oc get llamastackdistribution -n ${LLAMASTACK_NAMESPACE}        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=LlamaStackDistribution CR not found: ${output}
    Should Not Be Empty    ${output}    msg=LlamaStackDistribution CR output is empty

    # Check that all pods are running in the namespace
    Wait For Pods To Be Ready
    ...    label_selector=app=llama-stack
    ...    namespace=${LLAMASTACK_NAMESPACE}
    ...    timeout=5m

    # Check that LlamaStack pods have ready conditions
    Wait Until Keyword Succeeds    2 min    10s    Check LlamaStackDistribution Pod Ready

Verify Notebook CR Is Running
    [Documentation]    Verifies that the notebook CR is running
    [Arguments]    ${notebook_name}
    ${rc}    ${output}=    Run And Return Rc And Output    oc get notebook -n ${LLAMASTACK_NAMESPACE}        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Notebook CR not found: ${output}
    Should Not Be Empty    ${output}    msg=Notebook CR output is empty

    # Check that all pods are running in the namespace
    Wait For Pods To Be Ready
    ...    label_selector=app=${notebook_name}
    ...    namespace=${LLAMASTACK_NAMESPACE}
    ...    timeout=5m

Run Command In Container
    [Documentation]    Executes a command in the notebook container using context variables
    [Arguments]    ${command}    ${container_name}=${EMPTY}
    ${pod_name}=    Get First Pod By Name    ${LLAMASTACK_NAMESPACE}    ${NOTEBOOK_CR_NAME}
    Should Not Be Empty    ${pod_name}    msg=No pods found for notebook ${NOTEBOOK_CR_NAME}
    IF    "${container_name}" == "${EMPTY}"
        ${rc}    ${output}=    Run And Return Rc And Output    oc exec -n ${LLAMASTACK_NAMESPACE} ${pod_name} -- ${command}    #robocop: disable: line-too-long
    ELSE
        ${rc}    ${output}=    Run And Return Rc And Output    oc exec -n ${LLAMASTACK_NAMESPACE} ${pod_name} -c ${container_name} -- ${command}    #robocop: disable: line-too-long
    END
    Should Be Equal As Integers    ${rc}    0    msg=Failed to run command in container: ${output}
    Log    Successfully ran command in container: ${output}
    RETURN    ${output}

Copy File To Container
    [Documentation]    Copies a file to the notebook container
    [Arguments]    ${source_file}    ${destination_path}
    ${pod_name}=    Get First Pod By Name    ${LLAMASTACK_NAMESPACE}    ${NOTEBOOK_CR_NAME}
    Should Not Be Empty    ${pod_name}    msg=No pods found for notebook ${NOTEBOOK_CR_NAME}
    ${rc}    ${output}=    Run And Return Rc And Output    oc cp ${source_file} ${LLAMASTACK_NAMESPACE}/${pod_name}:${destination_path} -c llamastack-notebook        #robocop: disable: line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to copy file to container: ${output}
    Log    Successfully copied file to container: ${output}

Teardown Test Environment
    [Documentation]    Cleans up the test environment by deleting resources
    ...    and reverting DSCI serviceMesh managementState and DSC components
    # Revert DSCI serviceMesh managementState back to Managed
    Set Service Mesh Management State    Managed    ${APPLICATIONS_NAMESPACE}

    # Revert DSC components to original state
    Revert DSC Components

    # Delete the LlamaStackDistribution CR
    Run And Return Rc    oc delete LlamaStackDistribution ${LLAMASTACK_CR_NAME} -n ${LLAMASTACK_NAMESPACE} --ignore-not-found        #robocop: disable: line-too-long  

    # Delete the serving runtime
    Run And Return Rc    oc delete servingruntime llama-32-3b-instruct -n ${LLAMASTACK_NAMESPACE} --ignore-not-found

    # Remove finalizers from inference service before deletion
    ${finalizer_patch_data}=    Set Variable    [{"op": "remove", "path": "/metadata/finalizers"}]        #robocop: disable: line-too-long  
    Run And Return Rc    oc patch inferenceservice -n ${LLAMASTACK_NAMESPACE} --all --type='json' -p='${finalizer_patch_data}' --ignore-not-found        #robocop: disable: line-too-long  

    # Delete the inference service
    Run And Return Rc    oc delete inferenceservice -n ${LLAMASTACK_NAMESPACE} --all --ignore-not-found

    # Delete the namespace
    Delete Namespace From Openshift    ${LLAMASTACK_NAMESPACE}
