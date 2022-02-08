*** Settings ***
Resource   ../../Components/Components.resource
Resource   ../../LoginPage.robot
Library    JupyterLibrary

*** Keywords ***
Open OperatorHub
    Open OCP Console
    LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
    Navigate to OperatorHub
    Select All Projects
    OperatorHub Should Be Open

Install ODH Operator
    Install Operator    opendatahub

Open OCP Console
    Open Page    ${OCP_CONSOLE_URL}

Navigate to OperatorHub
    Menu.Navigate To Page   Operators  OperatorHub

OperatorHub Should Be Open
    Page Should Be Open    ${OCP_CONSOLE_URL}/operatorhub/all-namespaces

ODH Operator Should Be Installed
    Operator Should Be Installed    Open Data Hub Operator

