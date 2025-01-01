*** Settings ***
Documentation       Applies RHOSi settings to run the test suites

Library             RPA.RobotLogListener
Resource            Page/ODH/Monitoring/Monitoring.resource
Resource            Page/OCPDashboard/InstalledOperators/InstalledOperators.robot
Resource            Page/OCPLogin/OCPLogin.resource
Resource            Common.robot
Resource            OCP.resource


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
...                         Create Secret With Pipelines Object Storage Information
${ODH_RELEASE_NAME}=     Open Data Hub
${RHOAI_SELFMANAGED_RELEASE_NAME}=      OpenShift AI Self-Managed
${RHOAI_MANAGED_RELEASE_NAME}=      OpenShift AI Cloud Service
${RELEASE_NAME_ATTRIBUTE_PATH}=      .status.release.name
${RELEASE_VERSION_ATTRIBUTE_PATH}=      .status.release.version


*** Keywords ***
RHOSi Setup
    [Documentation]    Applies RHOSi Settings and stores availability metrics
    ...                The suggested usage of this keyword is to call it inside all the Suite Setup keywords.
    ...                Do Not extend this keyword for high-level setup, e.g., don't open browser
    Protect Sensitive Variables In Keywords
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
    Fetch Cluster Type By Domain
    Assign Vars According To Product
    ${RHODS_VERSION}=    Get RHODS Version    ${force_fetch}
    Set Global Variable   ${RHODS_VERSION}
    Set Prometheus Variables
    Set Global Variable    ${DASHBOARD_APP_NAME}    ${PRODUCT.lower()}-dashboard
    Set Global Variable    ${RHODS_PACKAGE_NAME}    rhods-operator

Required Global Variables Should Exist
    [Documentation]   Fails if new required global variables are not set
    Variable Should Exist    ${PRODUCT}
    Variable Should Exist    ${APPLICATIONS_NAMESPACE}
    Variable Should Exist    ${MONITORING_NAMESPACE}
    Variable Should Exist    ${OPERATOR_NAMESPACE}
    Variable Should Exist    ${NOTEBOOKS_NAMESPACE}

Fetch Cluster Type By Domain
    [Documentation]    This Keyword outputs the kind of cluster depending on the console URL domain
    ${matches}=    Get Regexp Matches    ${OCP_CONSOLE_URL}    rh-ods
    ${matches_len}=     Get Length      ${matches}
    IF  '${matches_len}' == '0'
        Set Global Variable    ${CLUSTER_TYPE}    managed
    ELSE
        Set Global Variable    ${CLUSTER_TYPE}    selfmanaged
    END

Assign Vars According To Product
    [Documentation]    Assign vars related to product
    IF    "${PRODUCT}" == "RHODS"
        Set Suite Variable    ${OPERATOR_APPNAME}     "Red Hat OpenShift AI"
        Set Suite Variable    ${OPERATOR_DEPLOYMENT_NAME}    rhods-operator
        Set Suite Variable    ${OPERATOR_POD_CONTAINER_NAME}  rhods-operator
        Set Suite Variable    ${OPERATOR_LABEL_SELECTOR}    name=rhods-operator
        Set Suite Variable    ${OPERATOR_SUBSCRIPTION_LABEL}     operators.coreos.com/rhods-operator.redhat-ods-operator
        Set Suite Variable    ${AUTHORINO_CR_NS}    redhat-ods-applications-auth-provider
        Set Suite Variable    ${DASHBOARD_DEPLOYMENT_NAME}    rhods-dashboard
        Set Suite Variable    ${DASHBOARD_LABEL_SELECTOR}     app.kubernetes.io/part-of=rhods-dashboard
        Set Suite Variable    ${APPLICATIONS_NAMESPACE}    redhat-ods-applications
        IF  "${CLUSTER_TYPE}" == "managed"
            Set Suite Variable    ${OPERATOR_SUBSCRIPTION_NAME}     addon-managed-odh
        ELSE
            Set Suite Variable    ${OPERATOR_SUBSCRIPTION_NAME}     rhoai-operator-dev
        END
        Set Suite Variable  ${MODEL_REGISTRY_NAMESPACE}    rhoai-model-registries
    ELSE IF    "${PRODUCT}" == "ODH"
        Set Suite Variable    ${OPERATOR_APPNAME}  "Open Data Hub Operator"
        Set Suite Variable    ${OPERATOR_DEPLOYMENT_NAME}    opendatahub-operator-controller-manager
        Set Suite Variable    ${OPERATOR_POD_CONTAINER_NAME}  manager
        Set Suite Variable    ${OPERATOR_LABEL_SELECTOR}    control-plane=controller-manager
        Set Suite Variable    ${OPERATOR_SUBSCRIPTION_LABEL}     operators.coreos.com/rhods-operator.opendatahub-operators
        Set Suite Variable    ${AUTHORINO_CR_NS}    opendatahub-auth-provider
        Set Suite Variable    ${DASHBOARD_DEPLOYMENT_NAME}    odh-dashboard
        Set Suite Variable    ${DASHBOARD_LABEL_SELECTOR}     app.kubernetes.io/part-of=dashboard
        Set Suite Variable    ${APPLICATIONS_NAMESPACE}    opendatahub
        Set Suite Variable    ${OPERATOR_SUBSCRIPTION_NAME}     rhoai-operator-dev
        Set Suite Variable   ${MODEL_REGISTRY_NAMESPACE}    odh-model-registries
    END

Gather Release Attributes From DSC And DSCI
    [Documentation]    Gathers the release.name and release.value attributes from the dsc and dsci
    ${DSC_RELEASE_NAME}=     Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                      DataScienceCluster       ${DSC_NAME}        ${RELEASE_NAME_ATTRIBUTE_PATH}
    ${DSCI_RELEASE_NAME}=     Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                      DSCInitialization      ${DSCI_NAME}        ${RELEASE_NAME_ATTRIBUTE_PATH}
    ${DSC_RELEASE_VERSION}=     Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                         DataScienceCluster       ${DSC_NAME}        ${RELEASE_VERSION_ATTRIBUTE_PATH}
    ${DSCI_RELEASE_VERSION}=    Get Resource Attribute      ${OPERATOR_NAMESPACE}
    ...                         DSCInitialization      ${DSCI_NAME}        ${RELEASE_VERSION_ATTRIBUTE_PATH}

    Set Suite Variable    ${DSC_RELEASE_NAME}
    Set Suite Variable    ${DSCI_RELEASE_NAME}
    Set Suite Variable    ${DSC_RELEASE_VERSION}
    Set Suite Variable    ${DSCI_RELEASE_VERSION}

Set Expected Value For Release Name
    [Documentation]    Sets the expected value for release.name attribute from the DSC and DSCI.
    ...                ODH: Open Data Hub
    ...                RHOAI managed: OpenShift AI Cloud Service
    ...                RHOAI selfmanaged: OpenShift AI Self-Managed

    IF    "${PRODUCT}" == "RHODS"
        IF     ${IS_SELF_MANAGED}
             ${expected_release_name}=    Set Variable     ${RHOAI_SELFMANAGED_RELEASE_NAME}
        ELSE
             ${expected_release_name}=    Set Variable     ${RHOAI_MANAGED_RELEASE_NAME}
        END
    ELSE IF    "${PRODUCT}" == "ODH"
        ${expected_release_name}=    Set Variable     ${ODH_RELEASE_NAME}
    END

    Set Suite Variable    ${expected_release_name}
