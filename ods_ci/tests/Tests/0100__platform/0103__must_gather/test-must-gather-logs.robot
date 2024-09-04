# robocop: off=wrong-case-in-keyword-name,unnecessary-string-conversion,hyphen-in-variable-name
*** Settings ***
Documentation    Tests the must-gather image for ODH/RHOAI
Library          Process
Library          OperatingSystem
Resource         ../../../Resources/Common.robot
Resource         ../../../Resources/CLI/MustGather/MustGather.resource


*** Test Cases ***
Verify that the must-gather image provides RHODS logs and info
    [Documentation]   Tests the must-gather image for ODH/RHOAI
    [Tags]   Smoke
    ...      Tier1
    ...      ODS-505
    ...      Operator
    ...      MustGather
    ...      ExcludeOnODH
    Get must-gather Logs
    Verify logs for ${APPLICATIONS_NAMESPACE}
    IF  "${PRODUCT}" == "RHODS"
        Verify Logs For ${OPERATOR_NAMESPACE}
        Run Keyword If RHODS Is Managed    Verify logs for ${MONITORING_NAMESPACE}
    END
    [Teardown]  Cleanup must-gather Logs
