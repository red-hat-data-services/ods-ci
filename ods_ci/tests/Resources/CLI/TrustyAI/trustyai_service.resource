*** Settings ***
Documentation     Collection of keywords to interact with TrustyAI service via CLI
Resource          ../../../Resources/OCP.resource


*** Variables ***
${TRUSTYAI_RESOURCEPATH}=            tests/Resources/Files/TrustyAI
${TRUSTYAI_CR_FILEPATH}=             ${TRUSTYAI_RESOURCEPATH}/trustyai_cr.yaml
${MODELMESH_SERVING_LABEL}=          modelmesh-service=modelmesh-serving


*** Keywords ***
Install And Verify TrustyAI Service
    [Documentation]    Install TrustyAI service CRD and verify that TrustyAI resources have spun up
    [Arguments]        ${namespace}
    ${return_code}    ${output}=    Run And Return Rc And Output    oc apply -f ${TRUSTYAI_CR_FILEPATH} -n ${namespace}
    Wait For Pods To Be Ready    label_selector=app=trustyai-service
    ...    namespace=${namespace}
    ${return_code}    ${output}    Run And Return Rc And Output   oc get route trustyai-service -n ${namespace} --template={{.spec.host}}
    Should Be Equal As Integers    ${return_code}	 0
    RETURN       https://${output}

Verify Model Is Registered With TrustyAI Service
    [Documentation]    Verify the deployed model is registered with TrustyAI Service by verifying MM_PAYLOAD_PROCESSORS
    ...                value is the TrustyAI service route
    [Arguments]        ${namespace}=${PRJ_TITLE}
    IF  "${PRODUCT}" == "ODH"
        ${MM_PAYLOAD_PROCESSORS_Expected}=    Set Variable    https://trustyai-service.${namespace}.svc.cluster.local/consumer/kserve/v2
    ELSE
        ${MM_PAYLOAD_PROCESSORS_Expected}=    Set Variable    https://trustyai-service.${namespace}.svc/consumer/kserve/v2
    END
    Sleep  60s  msg=Time For pods to be registered with TrustyAI Service
    Wait Until Keyword Succeeds  3 min  20 sec  Verify Model Serving Pod Exists   ${namespace}
    ...    label_selector=modelmesh-service=modelmesh-serving
    ${podname}=    Get Pod Name   ${namespace}    label_selector=${MODELMESH_SERVING_LABEL}
    Log    Serving Runtime Podname: ${podname}
    Wait For Pods To Be Ready    label_selector=${MODELMESH_SERVING_LABEL}
    ...     namespace=${namespace}
    ${MM_PAYLOAD_PROCESSORS_Actual}=  Run  oc get pod ${podname} -n ${namespace} -o json | jq '.spec.containers[0].env[] | select(.name=="MM_PAYLOAD_PROCESSORS") | .value'      #robocop:disable
    ${MM_PAYLOAD_PROCESSORS_Actual}=    Strip String    ${MM_PAYLOAD_PROCESSORS_Actual}    characters="
    Should Be Equal  ${MM_PAYLOAD_PROCESSORS_Actual.strip()}  ${MM_PAYLOAD_PROCESSORS_Expected.strip()}

Verify Model Serving Pod Exists
    [Documentation]    Verifies that serving runtime pods have been stabilized and pods exists
    [Arguments]    ${PRJ_TITLE}     ${label_selector}
    ${return_code}    ${pod_number}    Run And Return Rc And Output   oc get pod -n ${PRJ_TITLE} -l ${label_selector} | tail -n +2 | wc -l       # robocop: disable
    ${pod_numbers}    Split String     ${pod_number}
    Should Be Equal    ${pod_numbers}[0]   1
