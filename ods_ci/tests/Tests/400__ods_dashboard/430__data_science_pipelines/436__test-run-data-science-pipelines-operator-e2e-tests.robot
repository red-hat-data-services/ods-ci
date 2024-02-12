*** Settings ***
Documentation     Data Science Pipelines Operator E2E tests - https://github.com/opendatahub-io/data-science-pipelines-operator/tree/main/tests
Suite Setup       Prepare Data Science Pipelines Operator E2E Test Suite
Suite Teardown    Teardown Data Science Pipelines Operator E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/RHOSi.resource
Library             ../../../../libs/DataSciencePipelinesAPI.py


*** Variables ***
# For the initial commit we are hardcoding those environment variables
${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR}                /tmp/data-science-pipelines-operator
${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL}           https://github.com/opendatahub-io/data-science-pipelines-operator.git
${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}        c9e336df3e6cc8b8e03af2e951dfa54143790339
${DSPANAMESPACE}                                          dspa-e2e
${KUBECONFIGPATH}                                         %{HOME}/.kube/config

*** Test Cases ***
Run Data Science Pipelines Operator E2E Test
    [Documentation]    Run Data Science Pipelines Operator E2E Test
    [Tags]
    ...     Sanity
    ...     DataSciencePipelines
    ...     Tier1
    ${openshift_api}    Get Openshift Server
    Log    ${openshift_api}
    ${return_code}    ${output}    Run And Return Rc And Output    cd ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR} && make integrationtest K8SAPISERVERHOST=${openshift_api} DSPANAMESPACE=${DSPANAMESPACE} KUBECONFIGPATH=${KUBECONFIGPATH}
    Log    ${output}
    IF    ${return_code} != 0
        FAIL    Run Data Science Pipelines Operator E2E Test failed
    END


*** Keywords ***
Prepare Data Science Pipelines Operator E2E Test Suite
    [Documentation]    Prepare Data Science Pipelines Operator E2E Test Suite
    ${return_code}    ${output}     Run And Return Rc And Output    rm -fR ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR}
    Log    ${output}
    ${return_code}    ${output}     Run And Return Rc And Output    git clone ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL} ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR}
    Log    ${output}
    IF    ${return_code} != 0
        FAIL    Unable to clone data-science-pipelines-operator repo ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_URL}:${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}:${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR}
    END
    ${return_code}    ${output}     Run And Return Rc And Output    cd ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_DIR} && git checkout -b it_test ${DATA-SCIENCE-PIPELINES-OPERATOR-SDK_REPO_BRANCH}
    IF    ${return_code} != 0
        FAIL    Unable to checkout data-science-pipelines-operator
    END
    RHOSi Setup
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${DSPANAMESPACE}
    IF    ${rc} != 0
        FAIL    Cannot create a new project ${DSPANAMESPACE}
    END

Teardown Data Science Pipelines Operator E2E Test Suite
    Delete Data Science Project From CLI    displayed_name=${DSPANAMESPACE}
    RHOSi Teardown
