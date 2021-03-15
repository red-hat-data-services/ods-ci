*** Settings ***
Library   SeleniumLibrary

*** Variables ***
${DASHBOARD_URL} =    ${OCP_CONSOLE_URL}
${OPERATORHUB_URL} =    ${OCP_CONSOLE_URL}operatorhub/all-namespaces

*** Keywords ***
Open OperatorHub
    Open OCP Console 
    Login To Openshift
    Navigate to OperatorHub
    OperatorHub Should Be Open

Install ODH Operator
    Install Operator    opendatahub

Open OCP Console
    Open Page    ${OCP_CONSOLE_URL}

Navigate to OperatorHub
    Navigate To Page   Operators  OperatorHub

OperatorHub Should Be Open
    Page Should Be Open    ${OPERATORHUB_URL}

ODH Operator Should Be Installed
    Operator Should Be Installed    Open Data Hub Operator

Open Page
   [Arguments]   ${url}
   Open Browser    ${url}
   ...             browser=${BROWSER.NAME}    
   ...             options=${BROWSER.OPTIONS}
   Page Should be Open   ${url}

Page Should Be Open
   [Arguments]    ${url}
   Location Should Be    ${url}