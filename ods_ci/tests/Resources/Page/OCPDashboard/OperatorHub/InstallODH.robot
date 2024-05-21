*** Settings ***
Resource   ../../Components/Components.resource
Resource   ../../LoginPage.robot
Library    JupyterLibrary


*** Variables ***
${OCP_LOADING_ANIMATION_XPATH}=    //div[contains(@class, "cos-status-box--loading")]


*** Keywords ***
Open OperatorHub
    Open OCP Console
    LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}
    Navigate to OperatorHub
    Select All Projects
    OperatorHub Should Be Open

Install ODH Operator
    Install Operator    ${OPERATOR_DEPLOYMENT_NAME}

Open OCP Console
    Open Page    ${OCP_CONSOLE_URL}
    Wait Until Page Contains Element    xpath:${OCP_LOADING_ANIMATION_XPATH}    timeout=5s
    Wait Until Page Does Not Contain Element    xpath:${OCP_LOADING_ANIMATION_XPATH}    timeout=10s

Navigate to OperatorHub
    Menu.Navigate To Page   Operators  OperatorHub

OperatorHub Should Be Open
    Page Should Be Open    ${OCP_CONSOLE_URL}/operatorhub/all-namespaces

ODH Operator Should Be Installed
    Operator Should Be Installed    Open Data Hub Operator
