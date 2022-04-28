*** Settings ***
Library         SeleniumLibrary
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Suite Setup     OCM Test Setup
Suite Teardown  OCM Test Teardown

*** Test Cases ***
Verify User Can Access RHODS Documentation
    [Tags]  ODS-1303
    Click Button        //button[@data-ouia-component-id="Add-ons"]
    Click Element       //img[@alt="Red Hat OpenShift Data Science"]
    Wait Until Page Contains Element    //div[@class="pf-c-drawer__panel ocm-c-addons__drawer--panel-content"]
    Page Should Contain Element     //a[@href="https://access.redhat.com/documentation/en-us/red_hat_openshift_data_science"]
    Verify Documentation Is Accessible

*** Keywords ***
Verify Documentation Is Accessible
    ${status}=    Check HTTP Status Code    https://access.redhat.com/documentation/en-us/red_hat_openshift_data_science
    Run Keyword IF  ${status}!=200      FAIL
    ...     Documentation Is Not Accessible

OCM Test Setup
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Click Button        //button[@class="pf-c-app-launcher__toggle"]
    Wait Until Page Contains Element    (//a[@class="pf-m-external pf-c-app-launcher__menu-item"])[2]
    Click Link          (//a[@class="pf-m-external pf-c-app-launcher__menu-item"])[2]
    Switch Window    NEW
    Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
    Wait Until Page Contains Element    //div[@id="cl-details-top"]

OCM Test Teardown
    Close All Browsers
