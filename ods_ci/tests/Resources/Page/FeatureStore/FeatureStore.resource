*** Settings ***
Documentation    This is a resource file for Distributed Workloads.
Library          OperatingSystem
Library          Process
Resource         ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot


*** Variables ***
${FEATURE-STORE-RELEASE-TAG}             adjustment-release-v0.49.0
${FEATURE-STORE_DIR}                     feature-store
${FEATURE-STORE_REPO_URL}                %{FEATURE-STORE_REPO_URL=https://github.com/opendatahub-io/feast.git}
${NOTEBOOK_IMAGE}                        quay.io/modh/odh-workbench-jupyter-datascience-cpu-py311-ubi9@sha256:48c2be818e8d2a5005a69e2c76f9a2d40ddeb1d03376e04516ca6da13418c887
${FEAST_VERSION}                         0.48.1


*** Keywords ***
Prepare Feature Store Test Suite
    [Documentation]   Prepare Feature store setup by enabling component
    RHOSi Setup
    Enable Component    feastoperator
    Wait Component Ready    feastoperator

Cleanup Feature Store Setup
    [Documentation]   cleanup Feature store setup by Disabling component
    Disable Component    feastoperator
    RHOSi Teardown

Prepare Feast E2E Test Suite
    [Documentation]    Prepare Feast E2E Test Suite
    Log To Console    Preparing Feast E2E Test Suite
    Log To Console    "Cloning Git reposiotory ${FEATURE-STORE_REPO_URL}"
    Common.Clone Git Repository    ${FEATURE-STORE_REPO_URL}    ${FEATURE-STORE-RELEASE-TAG}    ${FEATURE-STORE_DIR}
    Prepare Feature Store Test Suite
    Skip If Component Is Not Enabled     feastoperator

Teardown Feast E2E Test Suite
    [Documentation]   Cleanup directory and Feast E2E Test Suite
    Log To Console     "Removing directory ${FEATURE-STORE_DIR}"
    Remove Directory        ${FEATURE-STORE_DIR}    recursive=True
    Cleanup Feature Store Setup

Run Feast Operator E2E Test
    [Documentation]   Run feast operator e2e test
    [Arguments]   ${TEST_NAME}    ${TEST_TYPE}
    Log To Console    "Running feature-store operator e2e test: ${TEST_NAME}"
    ${command}=    Set Variable    cd ${FEATURE-STORE_DIR}/infra/feast-operator && git fetch origin && git checkout ${FEATURE-STORE-RELEASE-TAG} && git branch && go test -timeout 10m ./test/${TEST_TYPE}/ -v -ginkgo.focus=${TEST_NAME}
    ${result}=    Run Process    ${command}
    ...    shell=true
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Run Feast Notebook Test
    [Documentation]    Run feast Notebook test
    [Arguments]   ${TEST_NAME}
    Log To Console    "Running feature-store Notebook test: ${TEST_NAME}"
    ${command}=    Set Variable    cd ${FEATURE-STORE_DIR}/infra/feast-operator && git fetch origin && git checkout ${FEATURE-STORE-RELEASE-TAG} && git branch && go test -timeout 10m ./test/e2e_rhoai/ -v -ginkgo.focus=${TEST_NAME}
    ${result}=    Run Process    ${command}
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:RUN_ON_OPENSHIFT_CI=true
    ...    env:NOTEBOOK_IMAGE=${NOTEBOOK_IMAGE}
    ...    env:FEAST_VERSION=${FEAST_VERSION}
    ...    env:APPLICATIONS_NAMESPACE=${APPLICATIONS_NAMESPACE}
    ...    env:OPENAI_API_KEY=${OPENAI_API_KEY}
    ...    env:PIP_INDEX_URL=${PIP_INDEX_URL}
    ...    env:PIP_TRUSTED_HOST=${PIP_TRUSTED_HOST}
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Running test ${TEST_NAME} failed
    END

Create Feast Instance
    [Documentation]    Create Simple Feature store instance
    [Arguments]   ${namespace}    ${feast_instance_name}    ${feast_cr_file}
    Log To Console    Creating Feast Instance ${feast_instance_name}
    ${rc}=    Run And Return Rc    sed -e "s/\\$NAMESPACE/${namespace}/g" -e "s/\\$FEAST_PROJECT_NAME/${feast_instance_name}/g" ${feast_cr_file} | oc apply -f -
    IF    ${rc} != 0
        FAIL    Creating Feast instance failed
    ELSE
        Set Global Variable    ${FEAST_INSTANCES_CREATED}   True
    END

Delete Feast Instance And Project
    [Documentation]    Create Simple Feature store instance
    [Arguments]   ${namespace}    ${feast_instance_name}
    Log To Console    Delete Feast Instance and Project
    IF    ${FEAST_INSTANCES_CREATED} == True    Run Keywords
    ...    Log To Console    Deleting Feast Instance : ${feast_instance_name}    AND
    ...    Run    oc delete FeatureStore ${feast_instance_name} -n ${namespace}
    Run    oc delete project ${namespace}

Get Feature Server Image Reference
    [Documentation]    Get Feature server image reference
    Log To Console    Fetching Feature Server Image reference
    ${rc}   ${featureServerImage}=    Run And Return Rc And Output
    ...    oc get csv ${OPERATOR_NAME}.${RHODS_VERSION} -n ${OPERATOR_NAMESPACE} -o jsonpath="{.spec.relatedImages[?(@.name=='odh_feature_server_image')].image}"
    Should Be Equal As Integers    ${rc}    0    msg=${featureServerImage}
    ${featureServerImage}=    Split String    ${featureServerImage}    ${SPACE}
    ${featureServerImageStr}=    Catenate    SEPARATOR=    @{featureServerImage}
    RETURN    ${featureServerImageStr}

Check Feast Instance Pod Images Pull Path Is Correct
    [Documentation]    Check Feast Instance Pod Images Pull Path Is Correct
    [Arguments]   ${namespace}    ${deployment_name}    ${image_pull_path}
    ${featureServerImage}=    Get Feature Server Image Reference

    ${rc}   ${images}=    Run And Return Rc And Output
    ...    oc get deployment/${deployment_name} -n ${namespace} -o jsonpath="{..image}"
    Should Be Equal As Integers    ${rc}    0    msg=${images}
    ${images}=    Split String    ${images}    ${SPACE}

    FOR  ${image}    IN    @{images}
        Log To Console    Check deployment ${deployment_name} pull path for image ${featureServerImage}
        Run Keyword And Continue On Failure
        ...    Should Start With    ${image}   ${image_pull_path}    msg=Deployment image pull path ${image} does not start with ${image_pull_path}
        Run Keyword And Continue On Failure
        ...    Should Be Equal As Strings    ${featureServerImage}    ${image}
    END
