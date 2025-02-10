*** Settings ***
Documentation     KFTO SDK tests - https://github.com/opendatahub-io/distributed-workloads/blob/main/tests/kfto/kfto_mnist_sdk_test.go
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup       Prepare Training Operator SDK Test Suite
Suite Teardown    Teardown Training Operator SDK Test Suite

*** Test Cases ***
Run TestMnistSDK KFTO SDK test
    [Documentation]    Run Go KFTO SDK test: TestMnistSDK
    [Tags]  Tier1
    ...     KFTOSDK
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    Run Training Operator KFTO SDK Test    TestMnistSDK
