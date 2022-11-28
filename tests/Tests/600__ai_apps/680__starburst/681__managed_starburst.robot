*** Settings ***
Resource    ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource


*** Test Cases ***
Verify User Can Access Trino Web console
    [Tags]    MISV-86
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Trino Web UI    user=${TEST_USER_3.USERNAME}
    Page Should Contain     Cluster Overview
    Page Should Contain     Active workers
    Page Should Contain Element     xpath=//a[text()="Log Out"]

Verify User Can Access Managed Starburst Web console
    [Tags]    MISV-85
    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    Open Managed Staburst Web UI    user=${TEST_USER_3.USERNAME}




        

    