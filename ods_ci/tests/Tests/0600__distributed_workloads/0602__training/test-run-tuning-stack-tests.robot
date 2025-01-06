*** Settings ***
Documentation     Training Operator FMS E2E tests - https://github.com/opendatahub-io/distributed-workloads/tree/main/tests/fms
Suite Setup       Prepare Training Operator FMS E2E Test Suite
Suite Teardown    Teardown Training Operator FMS E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run Training operator FMS test base finetuning use case
    [Documentation]    Run Go FMS tests for Training operator base finetuning use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator FMS Test    TestPytorchjobWithSFTtrainerFinetuning

Run Training operator FMS test base LoRA use case
    [Documentation]    Run Go FMS tests for Training operator base LoRA use case
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator FMS Test    TestPytorchjobWithSFTtrainerLoRa

## Note : This test is disabled because the required model supported for QLoRA test is not available
# Run Training operator ODH test base QLoRA use case
#     [Documentation]    Run Go ODH tests for Training operator base QLoRA use case
#     [Tags]  RHOAIENG-13142
#     ...     Resources-GPU    NVIDIA-GPUs
#     ...     Tier1
#     ...     DistributedWorkloads
#     ...     Training
#     ...     TrainingOperator
#     Run Training Operator ODH Core Test    TestPytorchjobWithSFTtrainerQLoRa

Run Training operator FMS test with Kueue quota
    [Documentation]    Run Go FMS tests for Training operator with Kueue quota
    [Tags]  RHOAIENG-6965
    ...     Tier1
    ...     DistributedWorkloads
    ...     Training
    ...     TrainingOperator
    Run Training Operator FMS Test    TestPytorchjobUsingKueueQuota
