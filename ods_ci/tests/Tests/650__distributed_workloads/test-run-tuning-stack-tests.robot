*** Settings ***
Documentation     Training operator E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator E2E Core Test Suite
Suite Teardown    Teardown Training Operator E2E Core Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run Training operator ODH test base use case
    [Documentation]    Run Go ODH tests for Training operator base use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobWithSFTtrainer

Run Training operator ODH test with Kueue quota
    [Documentation]    Run Go ODH tests for Training operator with Kueue quota
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobUsingKueueQuota
