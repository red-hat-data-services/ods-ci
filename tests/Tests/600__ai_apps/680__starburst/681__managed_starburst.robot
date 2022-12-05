*** Settings ***
Documentation    Suite to test Managed Starburst integration
Resource    ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource


*** Test Cases ***
Verify User Can Access Trino Web console
    [Documentation]    Checks Trino Web UI can be accessed
    [Tags]    MISV-86
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Trino Web UI    user=${TEST_USER_3.USERNAME}
    Check Trino Web UI Is Loaded

Verify User Can Access Managed Starburst Web console
    [Documentation]    Checks Starburst Web UI can be accessed
    [Tags]    MISV-85
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Managed Staburst Web UI    user=${TEST_USER_3.USERNAME}
    Check Managed Starburst Web UI Is Loaded
    Check Worksheet Tool Is Accessible
