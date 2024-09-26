*** Settings ***
Documentation     Codeflare-sdk E2E tests - https://github.com/project-codeflare/codeflare-sdk/tree/main/tests/e2e
Suite Setup       Prepare Codeflare-sdk E2E Test Suite
Suite Teardown    Teardown Codeflare-sdk E2E Test Suite
Library           OperatingSystem
Library           Process
Resource          ../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource          ../../../Resources/RHOSi.resource
Resource          ../../../../tests/Resources/Page/DistributedWorkloads/DistributedWorkloads.resource


*** Test Cases ***
Run TestRayClusterSDKOauth test
    [Documentation]    Run Python E2E test: TestRayClusterSDKOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    mnist_raycluster_sdk_oauth_test.py

Run TestRayLocalInteractiveOauth test
    [Documentation]    Run Python E2E test: TestRayLocalInteractiveOauth
    [Tags]
    ...     Tier1
    ...     DistributedWorkloads
    ...     WorkloadsOrchestration
    ...     Codeflare-sdk
    Run Codeflare-SDK Test    e2e    local_interactive_sdk_oauth_test.py

*** Keywords ***
Prepare Codeflare-sdk E2E Test Suite
    [Documentation]    Prepare codeflare-sdk E2E Test Suite
    Log To Console    "Restarting kueue"
    Restart Kueue
    Prepare Codeflare-SDK Test Setup
    RHOSi Setup

Teardown Codeflare-sdk E2E Test Suite
    [Documentation]    Teardown codeflare-sdk E2E Test Suite
    Cleanup Codeflare-SDK Setup
    RHOSi Teardown
