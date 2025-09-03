*** Settings ***
Documentation       Deploying LlamaStack following ODH docs: https://github.com/opendatahub-io/llama-stack-k8s-operator/blob/odh/docs/odh/llama-stack-with-odh.md

Resource            ../../Resources/OCP.resource
Resource            ../../Resources/ODS.robot
Resource            ../../Resources/Common.robot
Resource            ../../Resources/ServiceMesh.resource


*** Variables ***
${LLAMASTACK_NAMESPACE}         llamastack
${LLAMASTACK_CR_FILE}           ./tests/Resources/Files/llamastack/llamastackdistribution.yaml
${CONNECTION_CR_FILE}           ./tests/Resources/Files/llamastack/connection.yaml
${INFERENCE_SERVICE_CR_FILE}    ./tests/Resources/Files/llamastack/inferenceservice.yaml
${SERVING_RUNTIME_CR_FILE}      ./tests/Resources/Files/llamastack/servingruntime.yaml
${LLAMASTACK_CR_NAME}           llamastack-custom-distribution


*** Test Cases ***
Running LlamaStack Operator with ODH
    [Documentation]    Runs the LlamaStack operator with ODH and verifies basic readiness of resources per ODH guide.
    # ODS-CI RobotFramework Style Guide:
    # https://docs.google.com/document/d/11ZJOPI1uq-0Wl6a2V8fkAv_TQhfzp9t_IjXAheaJxmQ/edit?tab=t.0#heading=h.s819p3c5ud7p
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

    # Ensure the CRD is present first
    Wait Until CRD Exists    llamastackdistributions.llamastack.io

    # Set DSCI serviceMesh managementState to Removed
    Set Service Mesh Management State    Removed    ${APPLICATIONS_NAMESPACE}

    # Configure DSC components
    Configure DSC Components

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
    [Documentation]    Generic keyword to check a specific pod condition
    [Arguments]    ${pod}    ${condition_type}
    ${jp}=    Set Variable    {.status.conditions[?(@.type=="${condition_type}")].status}
    ${rc}    ${status}=    Run And Return Rc And Output    oc get ${pod} -n ${LLAMASTACK_NAMESPACE} -o jsonpath='${jp}'        #robocop: disable:line-too-long
    Should Be Equal As Integers    ${rc}    0    msg=Failed to get ${condition_type} status for ${pod}: ${status}
    Should Be Equal As Strings    ${status}    True    msg=${condition_type} is not True for ${pod}: ${status}

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

Teardown Test Environment
    [Documentation]    Cleans up the test environment by deleting the CR and namespace,
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
