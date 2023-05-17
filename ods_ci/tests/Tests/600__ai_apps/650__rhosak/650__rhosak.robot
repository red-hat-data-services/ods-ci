*** Settings ***
Documentation       Test integration with RHOSAK isv

Library             SeleniumLibrary
Resource            ../../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource            ../../../Resources/RHOSi.resource

Suite Setup         Kafka Suite Setup
Suite Teardown      Kafka Suite Teardown
Test Setup          Kafka Test Setup


*** Variables ***
${RHOSAK_REAL_APPNAME}=         rhosak
${RHOSAK_DISPLAYED_APPNAME}=    OpenShift Streams for Apache Kafka


*** Test Cases ***
Verify RHOSAK Is Available In RHODS Dashboard Explore Page
    [Documentation]    Checks RHOSAK card is present in RHODS Dashboard > Explore Page
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-258
    Verify Service Is Available In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}
    ...    split_last=${TRUE}
    Verify Service Provides "Get Started" Button In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}
    ...    app_id=rhosak
    Verify Service Provides "Enable" Button In The Explore Page    ${RHOSAK_DISPLAYED_APPNAME}
    ...    app_id=rhosak

Verify User Can Enable RHOSAK from Dashboard Explore Page
    [Documentation]    Checks it is possible to enable RHOSAK from RHODS Dashboard > Explore Page
    [Tags]    Tier2
    ...       ODS-392
    [Teardown]  Remove RHOSAK From Dashboard
    Enable RHOSAK
    Capture Page Screenshot  kafka_enable_msg.png
    Verify Service Is Enabled  ${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot    kafka_enable_tab.png
    Launch OpenShift Streams for Apache Kafka From RHODS Dashboard Link    # robocop: disable
    Login To HCC  ${SSO.USERNAME}  ${SSO.PASSWORD}
    Maybe Skip RHOSAK Tour
    Wait Until Page Contains    Kafka Instances


*** Keywords ***
Kafka Suite Setup
    [Documentation]    Setup for RHOSAK Test Suite
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup

Kafka Suite Teardown
    [Documentation]    Teardown for Test Suite
    Close All Browsers

Kafka Test Setup
    [Documentation]    Setup for RHOSAK Test Cases
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
