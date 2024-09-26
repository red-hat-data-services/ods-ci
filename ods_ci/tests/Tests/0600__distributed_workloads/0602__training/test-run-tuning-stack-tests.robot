*** Settings ***
Documentation     Training operator E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/kfto
Suite Setup       Prepare Training Operator E2E Core Test Suite
Suite Teardown    Teardown Training Operator E2E Core Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run Training operator ODH test base finetuning use case
    [Documentation]    Run Go ODH tests for Training operator base finetuning use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobWithSFTtrainerFinetuning

Run Training operator ODH test base LoRA use case
    [Documentation]    Run Go ODH tests for Training operator base LoRA use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobWithSFTtrainerLoRa

Run Training operator ODH test base QLoRA use case
    [Documentation]    Run Go ODH tests for Training operator base QLoRA use case
    [Tags]  RHOAIENG-13142
    ...     Resources-GPU
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobWithSFTtrainerQLoRa

Run Training operator ODH test with Kueue quota
    [Documentation]    Run Go ODH tests for Training operator with Kueue quota
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator ODH Core Test    TestPytorchjobUsingKueueQuota
