*** Settings ***
Documentation      Suite to test Data Science Pipeline Operator feature using RHODS UI
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/DataConnections.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Pipelines.resource
Resource            ../../../Resources/Page/ODH/ODHDashboard/ODHDataSciencePipelines.resource
Resource            ../../../Resources/Page/Operators/OpenShiftPipelines.resource
Resource            ../../../Resources/Page/Operators/ISVs.resource
Resource           ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Test Tags          DataSciencePipelines
Suite Setup        Pipelines Suite Setup
Suite Teardown     Pipelines Suite Teardown


*** Variables ***


*** Test Cases ***
Verify Dashboard Disables Pipelines When OpenShift Pipelines Operator Is Not Installed
        [Documentation]    Dashboard verifies OpenShift Pipelines operator disables Pipelines if not installed
        [Tags]    Smoke    Tier1
        ...       ODS-2274
        ${pipelines_op_installed}=     Check If Operator Is Installed Via CLI     operator_name=openshift-pipelines-operator-rh
        Launch Data Science Project Main Page    username=${TEST_USER.USERNAME}  password=${TEST_USER.PASSWORD}
        IF    ${pipelines_op_installed}
            Verify Pipelines Are Enabled
        ELSE
            Verify Pipelines Are Disabled
        END

*** Keywords ***
Pipelines Suite Setup
    [Documentation]    Suite setup steps for testing operator availability. It creates some test variables
    ...                and runs RHOSi setup
    RHOSi Setup
    Set Library Search Order    SeleniumLibrary

Pipelines Suite Teardown
    [Documentation]    Suite setup steps for testing operator availability. It teardown the RHOSi setup
    RHOSi Teardown


