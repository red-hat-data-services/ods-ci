*** Settings ***
Documentation       Test Cases related to the DSP Operator

Library             Collections
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/RHOSi.resource

Suite Setup         Suite Setup
Suite Teardown      Suite Teardown


*** Variables ***
${OLM_DIR}                                  olm
${OPERATOR_NS}                              ${OPERATOR_NAMESPACE}
${DSC_NAME}                                 default-dsc
${DSC_CRD}                                  datascienceclusters.datasciencecluster.opendatahub.io
${MWC_LABEL}                                olm.webhook-description-generate-name=mutate.operator.opendatahub.io


*** Test Cases ***
Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Documentation]    Detect Pre-existing Install Of Argo Workflows And Block RHOAI Install
    [Tags]                  Operator                ODS-2651                Tier3
    Fetch Image Url And Update Channel
    Check Whether DSC Exists And Save Component Statuses
    Fetch Cluster Type By Domain
    IF    "${CLUSTER_TYPE}" == "selfmanaged"
        Uninstall RHODS In Self Managed Cluster
        Create Argo Workflow From Template
        Install RHODS In Self Managed Cluster Using CLI     ${CLUSTER_TYPE}     ${IMAGE_URL}

    ELSE IF    "${CLUSTER_TYPE}" == "managed"
        Uninstall RHODS In OSD
        Create Argo Workflow From Template
        Install RHODS In Managed Cluster Using CLI      ${CLUSTER_TYPE}     ${IMAGE_URL}
    END
    Restore Datasciencecluster If Existed
    Wait For Failed Conditions
    ${return_code}          ${output}               Run And Return Rc And Output
    ...                     oc delete DataScienceCluster default-dsc
    Log To Console          ${output}
    Should Be Equal As Integers
    ...                     ${return_code}
    ...                     0
    ...                     msg=Error deleting DataScienceCluster CR
    [Teardown]      Teardown Detect Pre-existing Install Of Argo Workflows


*** Keywords ***
Suite Setup
    [Documentation]    Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Check And Delete Argo Workflow Crd

Suite Teardown
    [Documentation]    Suite Teardown
    Close All Browsers
    RHOSi Teardown

Check And Delete Argo Workflow Crd
    [Documentation]    Check whether Argo Workflow CRD exists, and in that case clean it up.
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc get CustomResourceDefinition workflows.argoproj.io
    Log To Console    ${output}
    IF  ${return_code} == 0
        ${rc}    ${output}    Run And Return Rc And Output
        ...    oc delete crd workflows.argoproj.io
        Log To Console    ${output}
    END

Create Argo Workflow From Template
    [Documentation]     Create an Argo Workflow from a template
    ${file_path}        Set Variable    ./tasks/Resources/Files/
    ${return_code}      Run And Return Rc    oc apply -f ${file_path}argo/crd.workflows.yaml
    Should Be Equal As Integers    ${return_code}    0

Fetch Cluster Type By Domain
    [Documentation]    This Keyword outputs the kind of cluster depending on the console URL domain
    ${matches}=    Get Regexp Matches    ${OCP_CONSOLE_URL}    rh-ods
    ${domain}=    Get From List    ${matches}    0
    IF    "${domain}" == "rh-ods"
        Set Global Variable    ${CLUSTER_TYPE}    selfmanaged
    ELSE
        Set Global Variable    ${CLUSTER_TYPE}    managed
    END

Check Whether DSC Exists And Save Component Statuses
    [Documentation]     Check Whether DSC Exists And Save Component Statuses
    ${rc}=    Run And Return Rc
    ...    oc get datasciencecluster ${DSC_NAME}
    IF  ${rc} == 0
        Set Global Variable    ${DSC_EXISTS}    True
        &{custom_cmp} =       Create Dictionary
        ${rc}    ${out}=    Run And Return Rc And Output
        ...    oc get datasciencecluster ${DSC_NAME} -o jsonpath='{.spec.components}'
        ${custom_cmp}=    Load Json String    ${out}
        Set Test Variable    ${custom_cmp}    ${custom_cmp}
    ELSE
        Set Global Variable    ${DSC_EXISTS}    False
    END

Fetch Image Url And Update Channel
    [Documentation]    Fetch url for image and Update Channel
    # Fetch subscription first
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.source}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${CS_NAME}    ${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} -n ${OPERATOR_NAMESPACE} -o jsonpath='{.spec.sourceNamespace}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${CS_NAMESPACE}    ${out}
    # Get CatalogSource
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get catalogsource ${CS_NAME} --namespace ${CS_NAMESPACE} -o jsonpath='{.spec.image}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${IMAGE_URL}    ${out}
    ${rc}    ${out}=    Run And Return Rc And Output
    ...    oc get subscription ${OPERATOR_SUBSCRIPTION_NAME} --namespace ${OPERATOR_NS} -o jsonpath='{.spec.channel}'
    Should Be Equal As Integers    ${rc}    0
    Set Global Variable    ${UPDATE_CHANNEL}    ${out}

Operator Deployment Should Be Ready
    [Documentation]    Loop until the Operator deployment is ready
    ${rc}=    Set Variable    1
    TRY
        WHILE    ${rc} != 0    limit=10m
            Sleep    5s
            ${rc}    ${output}=    Run And Return Rc And Output
            ...    oc wait --for condition=available -n ${OPERATOR_NAMESPACE} deploy/${OPERATOR_DEPLOYMENT_NAME}
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=Operator deployment did not get ready
    END

Restore Datasciencecluster If Existed
    [Documentation]     Restore Datasciencecluster If Existed as it was in case it existed previously
    IF      ${DSC_EXISTS} == True
        Wait For Datasciencecluster Crd To Be Available
        Wait For Mutatingwebhook To Be Available
        Apply DataScienceCluster CustomResource     ${DSC_NAME}     True    ${custom_cmp}
    END

Cleanup Olm Install Dir
    [Documentation]    Clean up olm install repo
    ${return_code}=    Run and Watch Command    rm -vRf ${EXECDIR}/${OLM_DIR}    timeout=10 min
    Should Be Equal As Integers    ${return_code}    0    msg=Error while cleaning up olminstall directory

Teardown Detect Pre-existing Install Of Argo Workflows
    [Documentation]     Teardown Detect Pre-existing Install Of Argo Workflows
    Check And Delete Argo Workflow Crd
    Cleanup Olm Install Dir
    Restore Datasciencecluster If Existed
    Operator Deployment Should Be Ready
    Wait For DSC Conditions Reconciled    ${OPERATOR_NS}     ${DSC_NAME}

Wait For Failed Conditions
    [Documentation]     Wait until conditions get failed
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     30s
    ...                     Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     CapabilityDSPv2Argo
    ...                     "False"
    Wait Until Keyword Succeeds
    ...                     5 min
    ...                     30s
    ...                     Resource Status Should Be
    ...                     oc get DataScienceCluster default-dsc -o json | jq '.status.conditions[] | select(.type=="data-science-pipelines-operatorReady") | .status'
    ...                     data-science-pipelines-operatorReady
    ...                     "False"

Wait For Datasciencecluster Crd To Be Available
    [Documentation]    Loop until the DSC CRD is available
    ${rc}=    Set Variable    1
    TRY
        WHILE    ${rc} != 0    limit=2m
            Sleep    5s
            ${rc}    ${output}=    Run And Return Rc And Output
            ...    oc get CustomResourceDefinition ${DSC_CRD}
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=DataScienceCluster ${DSC_CRD} CRD did not get available
    END

Wait For Mutatingwebhook To Be Available
    [Documentation]    Loop until the MutatingWebhookConfiguration is available
    ${rc}=    Set Variable    1
    TRY
        WHILE    ${rc} != 0    limit=2m
            Sleep    5s
            ${rc}    ${output}=    Run And Return Rc And Output
            ...    oc get mutatingwebhookconfiguration -l ${MWC_LABEL}
        END
    EXCEPT    WHILE loop was aborted    type=start
        Fail    msg=MutatingWebhookConfiguration ${MWC_LABEL} did not get available
    END
