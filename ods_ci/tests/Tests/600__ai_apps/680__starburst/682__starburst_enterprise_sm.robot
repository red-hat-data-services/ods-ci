*** Settings ***
Library             SeleniumLibrary
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/Page/Operators/ISVs.resource
Resource            ../../../Resources/Page/ODH/AiApps/ManagedStarburst.resource
Suite Setup          Starburst Enterprise Suite Setup
Suite Teardown       Starburst Enterprise Suite Teardown


*** Variables ***
${OPERATOR_NAME}=     starburst-enterprise-helm-operator-rhmp
${SUBSCRIPTION_NAME}=    starburst-enterprise-helm-operator-rhmp-odsci
${NAMESPACE}=    ods-ci-starburst
${CHANNEL}=    alpha
${CATALOG_SOURCE_NAME}=    redhat-marketplace
${CATALOG_SOURCE_NAMESPACE}=    openshift-marketplace
${STARBURST_ROUTE_NAME}=    web-ui


*** Test Cases ***
Verify Starburst Enterprise Operator Can Be Installed
    [Documentation]    Installs Starburst enterprise operator and check if
    ...                its tile/card appears in RHODS Enabled page
    [Tags]    ODS-2247    Tier2
    #Create Starburst Route If Not Exists    name=${STARBURST_ROUTE_NAME}
    Log    message=Operator is installed as part of Suite Setup
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}
    ...    browser_options=${BROWSER.OPTIONS}
    Verify Service Is Enabled         starburstenterprise


*** Keywords ***
Starburst Enterprise Suite Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${rc}    ${out}=    Run And Return Rc And Output    oc new-project ${NAMESPACE}
    Install ISV Operator From OperatorHub Via CLI    operator_name=${OPERATOR_NAME}
    ...    subscription_name=${SUBSCRIPTION_NAME}    namespace=${NAMESPACE}
    ...    channel=${CHANNEL}    catalog_source_name=${CATALOG_SOURCE_NAME}
    ...    cs_namespace=${CATALOG_SOURCE_NAMESPACE}    operator_group_target_ns=${NAMESPACE}
    Wait Until Operator Subscription Last Condition Is
    ...    type=CatalogSourcesUnhealthy    status=False
    ...    reason=AllCatalogSourcesHealthy    subcription_name=${SUBSCRIPTION_NAME}
    ...    namespace=${NAMESPACE}
    Controller Manager Pod Should Be Running    namespace=${NAMESPACE}
    ...    prefix=starburst-enterprise-helm-operator

Starburst Enterprise Suite Teardown
    Close All Browsers
    # to do - uninstall starburst
