*** Settings ***
Resource    ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource


*** Test Cases ***
Verify User Can Access Trino Web console
    [Tags]    trino-ui
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Trino Web UI    user=${TEST_USER_3.USERNAME}
    Page Should Contain     CLUSTER OVERVIEW
    Page Should Contain     ACTIVE WORKERS
    Page Should Contain Element     xpath=//a[text=()="Log Out"]

Verify User Can Access Managed Starburst Web console
    [Tags]    sep-ui
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Managed Staburst Web UI    user=${TEST_USER_3.USERNAME}




        

    