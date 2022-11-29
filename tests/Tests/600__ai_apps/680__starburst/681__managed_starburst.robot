*** Settings ***
Resource    ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource


*** Test Cases ***
Verify User Can Access Trino Web console
    [Tags]    MISV-86
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Trino Web UI    user=${TEST_USER_3.USERNAME}
    Check Trino Web UI Is Loaded

Verify User Can Access Managed Starburst Web console
    [Tags]    MISV-85
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Managed Staburst Web UI    user=${TEST_USER_3.USERNAME}
    Check Managed Starburst Web UI Is Loaded
    Check Worksheet Tool Is Accessible
    






        

    