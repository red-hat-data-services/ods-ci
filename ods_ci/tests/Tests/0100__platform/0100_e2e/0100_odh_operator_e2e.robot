*** Settings ***
Documentation     TODO
Suite Setup       E2e Setup
Suite Teardown    E2e Teardown
Library           OperatingSystem
Library           Process
Resource          ../../../Resources/RHOSi.resource

*** Variables ***
${OPERATOR_GIT_REPO}       %{OPERATOR_GIT_REPO=https://github.com/red-hat-data-services/rhods-operator}  # TODO: configurable for odh
${OPERATOR_GIT_DIR}        ${OUTPUT DIR}/rhods-operator

*** Test Cases ***
Run Operator e2e tests
    [Documentation]    Run operator e2e tests
    [Tags]
    ...     Tier1
    ...     e2e
    Log To Console  Running operator e2e tests
    # ${e2e_test_name}=  Set Variable    ^TestOdhOperator   # sub-tests can be selected as e.g. ^TestOdhOperator/components/trainingoperator , but that does not work very well
    # the following only works on 2.21 and later, previous versions have different test flags
    ${result}=    Run Process  cd ${OPERATOR_GIT_DIR} && $(go env GOPATH)/bin/gotestsum -f standard-verbose --debug --junitfile-project-name rhods-operator-e2e --junitfile ${OUTPUT_DIR}/operator-e2e-junit.xml -- ./tests/e2e/ -run ^TestOdhOperator -v -timeout\=50m --operator-namespace\=$E2E_TEST_OPERATOR_NAMESPACE --test-components\=false --test-services\=false
    ...    shell=true
    ...    stderr=STDOUT
    ...    env:E2E_TEST_OPERATOR_NAMESPACE=redhat-ods-operator  # TODO: configurable for odh
    # any extra env vars we might need in the e2e tests can go here ^
    Log To Console    ${result.stdout}
    IF  ${result.rc}!=0  Fail    e2e tests failed


*** Keywords ***
E2e Setup
    RHOSi Setup
    #   cannot use 'Gather Release Attributes From DSC And DSCI' because DSC might not be present
    ${rc}  ${output}  Run And Return Rc And Output    oc get subscription -n ${OPERATOR_NAMESPACE} -l ${OPERATOR_SUBSCRIPTION_LABEL} -o jsonpath='{.items[0].status.currentCSV}'
    ${operator_branch} =  Remove String Using Regexp  ${output}  \\.[0-9]+\$
    ${operator_branch} =  Remove String    ${operator_branch}  rhods-operator.  # TODO configurable for odh
    Common.Clone Git Repository  ${OPERATOR_GIT_REPO}  rhoai-${operator_branch}  ${OPERATOR_GIT_DIR}
    ${rc}=  Run And Return Rc    command -v gotestsum
    IF  ${rc}!=0
        Log To Console    gotestsum not found, installing
        Run  go install gotest.tools/gotestsum@latest  # TODO: pre-install on jenkins agents
    END


E2e Teardown
    Remove Directory  ${OPERATOR_GIT_DIR}  recursive=True
