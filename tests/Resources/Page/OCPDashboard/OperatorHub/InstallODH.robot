*** Settings ***
Library   SeleniumLibrary

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
    Menu.Navigate To Page   Operators  OperatorHub

OperatorHub Should Be Open
    Page Should Be Open    ${OCP_CONSOLE_URL}operatorhub/all-namespaces

ODH Operator Should Be Installed
    Operator Should Be Installed    Open Data Hub Operator
