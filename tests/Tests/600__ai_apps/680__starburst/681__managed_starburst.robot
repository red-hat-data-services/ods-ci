*** Settings ***
Resource    ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource

*** Variables ***
${STARBURST_ROUTE}=    starburst-ui

*** Test Cases ***
Verify User Can Access Trino Web console
    ${host}=    Create Starburst Route If Not Exists    name=${STARBURST_ROUTE}
    

        

    