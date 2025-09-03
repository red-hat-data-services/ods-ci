*** Settings ***
Documentation    Create a LlamaStackDistribution CR following ODH docs step 3: https://github.com/opendatahub-io/llama-stack-k8s-operator/blob/odh/docs/odh/llama-stack-with-odh.md#3-create-llamastackdistribution-cr
Resource    ../../Resources/OCP.resource
Resource    ../../Resources/ODS.robot
Resource    ../../Resources/Common.robot


*** Variables ***
${LLAMASTACK_NAMESPACE}    llamastack-e2e
${LLAMASTACK_CR_NAME}      example-llamastack-distribution
${LLAMASTACK_CR_FILE}      ${TEMPDIR}/llamastackdistribution.yaml


*** Test Cases ***
Create LlamaStackDistribution CR
    [Documentation]    Creates a LlamaStackDistribution CR and verifies basic readiness of resources per ODH guide.
    [Tags]    llamastack    Integration
    [Teardown]    Delete LlamaStackDistribution And Namespace
    ${rand}=    Generate Random String    6    [LOWER]
    ${ns}=    Catenate    SEPARATOR=-    ${LLAMASTACK_NAMESPACE}    ${rand}
    ${name}=    Catenate    SEPARATOR=-    ${LLAMASTACK_CR_NAME}    ${rand}
    Set Test Variable    ${LLAMASTACK_NAMESPACE}    ${ns}
    Set Test Variable    ${LLAMASTACK_CR_NAME}    ${name}

    # Ensure the CRD is present
    Wait Until CRD Exists    llamastackdistributions.llama-stack.io

    # Create namespace for the distribution
    Create Namespace In Openshift    ${LLAMASTACK_NAMESPACE}
    Wait For Namespace To Be Active  ${LLAMASTACK_NAMESPACE}

    # Write the CR manifest to a temp file (block-style YAML matching v1alpha1 schema)
    ${yaml}=    Catenate    SEPARATOR=\n
    ...    apiVersion: llama-stack.io/v1alpha1
    ...    kind: LlamaStackDistribution
    ...    metadata:
    ...      name: ${LLAMASTACK_CR_NAME}
    ...      namespace: ${LLAMASTACK_NAMESPACE}
    ...    spec:
    ...      replicas: 1
    ...      server:
    ...        distribution:
    ...          name: meta-reference
    ...          image: quay.io/opendatahub-io/llama-stack-server:latest
    ...      storage:
    ...        size: 10Gi
    Create File    ${LLAMASTACK_CR_FILE}    ${yaml}

    # Apply CR
    Run And Verify Command    oc apply -f ${LLAMASTACK_CR_FILE} -n ${LLAMASTACK_NAMESPACE}

    # Verify CR exists
    Pods Should Exist In Namespace    ${LLAMASTACK_NAMESPACE}


*** Keywords ***
Pods Should Exist In Namespace
    [Arguments]    ${namespace}
    Wait Until Keyword Succeeds    24x    5s    Check Pod Name Exists In Namespace    ${namespace}

Check Pod Name Exists In Namespace
    [Arguments]    ${namespace}
    ${rc}    ${name}=    Run And Return Rc And Output    oc get pods -n ${namespace} -o jsonpath="{.items[0].metadata.name}"
    Should Be Equal As Integers    ${rc}    0
    Should Not Be Empty    ${name}

Delete LlamaStackDistribution And Namespace
    [Documentation]    Deletes the CR and the namespace created by this test
    Run And Return Rc    oc delete LlamaStackDistribution ${LLAMASTACK_CR_NAME} -n ${LLAMASTACK_NAMESPACE} --ignore-not-found
    Delete Namespace From Openshift    ${LLAMASTACK_NAMESPACE}


