*** Settings ***
Documentation       Applies RHOSi settings to run the test suites

#Library             RPA.RobotLogListener
Resource            Page/ODH/Monitoring/Monitoring.resource
Resource            Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Resource            Page/OCPLogin/OCPLogin.resource
Resource            Common.robot


*** Variables ***
@{PROTECTED_KEYWORDS}=      Login To RHODS Dashboard
...                         Launch Dashboard
...                         Login to HCC
...                         Login to OCP
...                         Login to Openshift
...                         Login to Jupyterhub
...                         Verify Username Displayed On RHODS Dashboard
...                         Create Pachyderm AWS-Secret
...                         Push Changes To Remote
...                         Commit Changes
...                         Push Some Changes To Repo
...                         Decide OCM URL And Open Link
...                         Get Bearer Token
...                         Log In As RHODS Admin
...                         Log In As RHODS Basic User
...                         Perform Dashboard API Endpoint GET Call
...                         Perform Dashboard API Endpoint PUT Call
...                         Perform Dashboard API Endpoint PATCH Call
...                         Perform Dashboard API Endpoint POST Call
...                         Perform Dashboard API Endpoint DELETE Call
...                         Create RedHat Marketplace Secret
...                         Create S3 Data Connection
...                         Create Starburst Enteprise License Secret
...                         Get Data Connection Form Values
...                         Fill Data Connection Form
...                         Create Secret For S3-Like Buckets
...                         Login To OCP Using API
...                         Generate Thanos Token
...                         Set Thanos Credentials Variables
...                         Generate Minio Random Credentials
...                         Get Minio Credentials
...                         Create Inference Access Token


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings and stores availability metrics
    ...                The suggested usage of this keyword is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't open browser
#    Protect Sensitive Variables In Keywords
    Required Global Variables Should Exist
    Initialize Global Variables
    Run Keyword If RHODS Is Managed
    ...    Suite Availability Setup    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}
    # TO DO: oc login

RHOSi Teardown
    [Documentation]    Gets current availability metrics and compares them with the ones
    ...                stored at RHOSi setup
    ...                The suggested usage of this keyword is to call it inside all the Suite Teardown keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't close browser
    Run Keyword If RHODS Is Managed
    ...    Suite Availability Teardown    ${RHODS_PROMETHEUS_URL}    ${RHODS_PROMETHEUS_TOKEN}

Protect Sensitive Variables In Keywords
    [Documentation]    Register keywords which use sensitive data as "Protected"
    ...                to turn their log level to NONE using RobotLogListener by Robocorp
    Register Protected Keywords    names=@{PROTECTED_KEYWORDS}

Initialize Global Variables
    [Documentation]   Sets global variables
    [Arguments]    ${force_fetch}=False
    Assign Vars According To Product
    ${RHODS_VERSION}=    Get RHODS Version    ${force_fetch}
    Set Global Variable   ${RHODS_VERSION}
    Set Prometheus Variables
    Set Global Variable    ${DASHBOARD_APP_NAME}    ${PRODUCT.lower()}-dashboard

Required Global Variables Should Exist
    [Documentation]   Fails if new required global variables are not set
    Variable Should Exist    ${PRODUCT}
    Variable Should Exist    ${APPLICATIONS_NAMESPACE}
    Variable Should Exist    ${MONITORING_NAMESPACE}
    Variable Should Exist    ${OPERATOR_NAMESPACE}
    Variable Should Exist    ${NOTEBOOKS_NAMESPACE}

Assign Vars According To Product
    [Documentation]    Assign vars related to product
    IF    "${PRODUCT}" == "RHODS"
        Set Suite Variable    ${OPERATOR_APPNAME}     Red Hat OpenShift AI
        Set Suite Variable    ${OPERATOR_NAME}    Red Hat OpenShift AI
        Set Suite Variable    ${OPERATOR_DEPLOYMENT_NAME}    rhods-operator
        Set Suite Variable    ${OPERATOR_LABEL_SELECTOR}    name=rhods-operator
        Set Suite Variable    ${AUTHORINO_CR_NS}    redhat-ods-applications-auth-provider
    ELSE IF    "${PRODUCT}" == "ODH"
        Set Suite Variable    ${OPERATOR_APPNAME}  Open Data Hub Operator
        Set Suite Variable    ${OPERATOR_NAME}    Open Data Hub Operator
        Set Suite Variable    ${OPERATOR_DEPLOYMENT_NAME}    opendatahub-operator-controller-manager
        Set Suite Variable    ${OPERATOR_LABEL_SELECTOR}    control-plane=controller-manager
        Set Suite Variable    ${AUTHORINO_CR_NS}    opendatahub-auth-provider
    END
