*** Settings ***
Documentation     Data Science Pipelines Operator Integration Tests - https://github.com/opendatahub-io/data-science-pipelines-operator/tree/main/tests
Suite Setup       Prepare Data Science Pipelines Operator Integration Tests Suite
Suite Teardown    RHOSi Teardown
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../Resources/RHOSi.resource
Library           ../../../libs/DataSciencePipelinesAPI.py


*** Variables ***
# For the initial commit we are hardcoding those environment variables
${DSPO_SDK_DIR}                /tmp/data-science-pipelines-operator
${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL}           https://github.com/opendatahub-io/data-science-pipelines-operator.git
${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}        main
${KUBECONFIGPATH}                                         %{HOME}/.kube/config

#robocop: disable: line-too-long
*** Test Cases ***
Run Data Science Pipelines Operator Integration Tests
    [Documentation]    Run Data Science Pipelines Operator Integration Tests
    [Tags]
    ...     DataSciencePipelines-Backend
    ...     Tier1
    ...     ODS-2632
    ${openshift_api}    Get Openshift Server
    Log    ${openshift_api}
    ${return_code}    ${output}    Run And Return Rc And Output    cd ${DSPO_SDK_DIR} && GIT_WORKSPACE=${DSPO_SDK_DIR} sh .github/scripts/tests/tests.sh --rhoai --k8s-api-server-host ${openshift_api} --kube-config ${KUBECONFIGPATH} --dspa-path ${DSPO_SDK_DIR}/tests/resources/dspa.yaml --external-dspa-path ${DSPO_SDK_DIR}/tests/resources/dspa-external.yaml --clean-infra --endpoint-type route
    Log    ${output}
    Should Be Equal As Integers	   ${return_code}	 0  msg= Run Data Science Pipelines Operator Integration Tests failed

#robocop: disable: line-too-long
*** Keywords ***
Prepare Data Science Pipelines Operator Integration Tests Suite
    [Documentation]    Prepare Data Science Pipelines Operator Integration Tests Suite
    ${return_code}    ${output}     Run And Return Rc And Output    rm -fR ${DSPO_SDK_DIR}
    Log    ${output}
    ${return_code}    ${output}     Run And Return Rc And Output    git clone ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL} ${DSPO_SDK_DIR}
    Log    ${output}
    Should Be Equal As Integers	   ${return_code}	 0  msg=Unable to clone data-science-pipelines-operator repo ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL}:${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}:${DSPO_SDK_DIR}
    ${return_code}    ${output}     Run And Return Rc And Output    cd ${DSPO_SDK_DIR} && git checkout -b it_test origin/${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}
    Should Be Equal As Integers	   ${return_code}	 0  msg=Unable to checkout data-science-pipelines-operator
    RHOSi Setup
    # Store login information into dedicated config
    Login To OCP Using API And Kubeconfig    ${OCP_ADMIN_USER.USERNAME}    ${OCP_ADMIN_USER.PASSWORD}    ${KUBECONFIGPATH}
