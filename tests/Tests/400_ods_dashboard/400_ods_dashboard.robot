*** Settings ***
Resource         ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Test Setup      Dashboard Test Setup
Test Teardown   Dashboard Test Teardown


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

Verify Documentation Link Https status code
    [Tags]  Sanity
    ...     ODS-327  ODS-492
    Click Link    Resources
    Sleep  2
    #get the documentation link
    ${href_view_the_doc}=  Get Element Attribute    xpath=//*[@id="root"]/div/div[2]/div/div/div[1]/div/main/div[1]/div/div/div/section/div/p/a    href
    ${status_for_view_the_doc}=  Get HTTP Status Code    ${href_view_the_doc}
    Log To Console  ${href_view_the_doc} gets status code ${status_for_view_the_doc}
    #Click on question mark
    Click Element    xpath=//*[@id="toggle-id"]
    ${link_elements}=  Get WebElements    //a[@class="odh-dashboard__external-link pf-c-dropdown__menu-item" and not(starts-with(@href, '#'))]
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
        ${href}=  Get Element Attribute    ${ext_link}    href
        ${status}=  Check HTTP Status Code   link_to_check=${href}
        Log To Console  ${idx}.${href} gets status code ${status}
    END


*** Keywords ***
Dashboard Test Setup
  Set Library Search Order  SeleniumLibrary
  Open Browser  ${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  options=${BROWSER.OPTIONS}
  Login To RHODS Dashboard  ${TEST_USER.USERNAME}  ${TEST_USER.PASSWORD}  ${TEST_USER.AUTH_TYPE}
  Wait for RHODS Dashboard to Load

Dashboard Test Teardown
  Close All Browsers