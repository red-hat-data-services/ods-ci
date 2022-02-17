*** Settings ***
Resource         ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/AiApps/Rhosak.resource
Resource        ../../Resources/Page/ODH/AiApps/Anaconda.robot
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown


*** Variables ***
${RHOSAK_REAL_APPNAME}=         rhosak
${RHOSAK_DISPLAYED_APPNAME}=    OpenShift Streams for Apache Kafka


*** Test Cases ***
Verify Resource Link Http status code
    [Tags]  Sanity
    ...     ODS-531
    Click Link    Resources
    Sleep  5
    ${link_elements}=  Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=  Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
        ${href}=  Get Element Attribute    ${ext_link}    href
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log To Console    ${idx}. ${href} gets status code ${status}
    END

Verify Content In RHODS Explore Section
    [Documentation]  It verifies if the content present in Explore section of RHODS corresponds to expected one.
    ...              It compares the actual data with the one registered in a JSON file. The checks are about:
    ...              - Card's details (text, badges, images)
    ...              - Sidebar (titles, links text, links status)
    [Tags]  Sanity
    ...     ODS-488  ODS-993
    ${EXP_DATA_DICT}=   Load Expected Data Of RHODS Explore Section
    Click Link    Explore
    Wait Until Cards Are Loaded
    Check Number Of Displayed Cards Is Correct  expected_data=${EXP_DATA_DICT}
    Check Cards Details Are Correct   expected_data=${EXP_DATA_DICT}

Verify Disabled Cards Can Be Removed
    [Documentation]     Verifies it is possible to remove a disabled card from Enabled page.
    ...                 It uses RHOSAK as example to test the feature
    [Tags]    Sanity
    ...       ODS-1081    ODS-1092
    Enable RHOSAK
    OpenShiftCLI.Delete    kind=ConfigMap    name=rhosak-validation-result    namespace=redhat-ods-applications
    Close All Browsers
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}  ocp_user_auth_type=${TEST_USER.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=${RHOSAK_REAL_APPNAME}
    Verify Service Is Not Enabled     app_name=${RHOSAK_DISPLAYED_APPNAME}
    Capture Page Screenshot     after_removal.png
    Success Message Should Contain   ${RHOSAK_DISPLAYED_APPNAME}

Verify License Of Disabled Cards Can Be Re-validated
    [Documentation]   Verifies it is possible to re-validate the license of a disabled card
    ...               from Enabled page. it uses Anaconda CE as example to test the feature.
    [Tags]    Sanity
    ...       ODS-1097
    [Teardown]    Remove Anaconda Commercial Edition Component
    Enable Anaconda  license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Menu.Navigate To Page    Applications    Enabled
    Wait Until RHODS Dashboard JupyterHub Is Visible
    Verify Service Is Enabled    ${ANACONDA_DISPLAYED_NAME}
    Close All Browsers
    Delete ConfigMap Using Name    redhat-ods-applications   anaconda-ce-validation-result
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}
    ...               ocp_user_auth_type=${TEST_USER.AUTH_TYPE}  dashboard_url=${ODH_DASHBOARD_URL}
    ...               browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    Re-validate License For Disabled Application From Enabled Page     app_id=${ANACONDA_APPNAME}
    Insert Anaconda License Key   license_key=${ANACONDA_CE.ACTIVATION_KEY}
    Validate Anaconda License Key
    Success Message Should Contain   ${ANACONDA_DISPLAYED_NAME}
    Verify Service Is Enabled    ${ANACONDA_DISPLAYED_NAME}



*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers
