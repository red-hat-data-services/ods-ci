*** Settings ***
Library          OpenShiftLibrary
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource         ../../Resources/Page/LoginPage.robot
Resource         ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource         ../../Resources/Page/ODH/ODHDashboard/ResourcesPage.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Suite Setup      Custom Doc Suite Setup
Suite Teardown   Custom Doc Suite Taerdown


*** Variables ***
${QS_YAML}=                     ods_ci/tests/Resources/Files/custom_quickstart.yaml
${APP_YAML}=                    ods_ci/tests/Resources/Files/custom_app.yaml
${HOWTO_YAML}=                  ods_ci/tests/Resources/Files/custom_doc_howto.yaml
${TUTORIAL_YAML}=               ods_ci/tests/Resources/Files/custom_doc_tutorial.yaml
&{EXPECTED_ITEMS_TITLES}=       quickstart=TEST - Custom Quick Start
...                             application=TEST - Custom ODS-CI Application
...                             howto=TEST - Custom How-To Documentation
...                             tutorial=TEST - Custom Tutorial Documentation
@{EXPECTED_QUICKSTART_IDS}=     custom-quick-start-test
${CUSTOM_APP_DICT_PATH}=        ods_ci/tests/Resources/Files/CustomAppInfoDictionary.json


*** Test Cases ***
Verify Documentation Items Can Be Added Using Odh CRDs
    [Documentation]     Verified it is possible to create QuickStarts,Tutorials,How-to and Application
    ...                 by using Dashboard CRDs: OdhQuickStart, OdhDocument (for both how-to and tutorial)
    ...                 and OdhApplication.
    [Tags]    Sanity
    ...       ODS-697    ODS-1768    ODS-1769    ODS-1770
    Create Custom QuickStart
    Create Custom Application
    Create Custom How-To
    Create Custom Tutorial
    Check Custom QuickStart Item Has Been Successfully Created
    Check Custom How-To Item Has Been Successfully Created
    Check Custom Tutorial Item Has Been Successfully Created
    Check Custom Application Item Has Been Successfully Created
    [Teardown]     Run Keywords     Delete Custom Quick Start
    ...                             Delete Custom Application
    ...                             Delete Custom How-To And Tutorial


*** Keywords ***
Custom Doc Suite Setup
    [Documentation]     Open RHODS Dashboard page and load expected data for custom application
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    ${dashboard_explore_exp_data}=   Load Expected Test Data
    Set Suite Variable      ${DASH_EXPLORE_EXP_DATA}   ${dashboard_explore_exp_data}

Custom Doc Suite Taerdown
    [Documentation]     Closes all the browsers instances and run RHOSi Teardown
    Close All Browsers
    RHOSi Teardown

Create Custom QuickStart
    [Documentation]     Creates a CRD instance of OdhQuickStarts using a custom yaml
    Oc Apply    kind=OdhQuickStart    src=${QS_YAML}     namespace=${APPLICATIONS_NAMESPACE}
    Oc Get      kind=OdhQuickStart    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}

Delete Custom Quick Start
    [Documentation]     Deletes the previously created CRD instance for custom Quickstart resource
    Oc Delete   kind=OdhQuickStart    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}
    Close All Browsers

Create Custom How-To
    [Documentation]     Creates a CRD instance of OdhDocument with type "how-to" using a custom yaml
    Oc Apply    kind=OdhDocument    src=${HOWTO_YAML}     namespace=${APPLICATIONS_NAMESPACE}
    Oc Get      kind=OdhDocument    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}

Create Custom Tutorial
    [Documentation]     Creates a CRD instance of OdhDocument with type "how-to" using a custom yaml
    Oc Apply    kind=OdhDocument    src=${TUTORIAL_YAML}     namespace=${APPLICATIONS_NAMESPACE}
    Oc Get      kind=OdhDocument    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}

Delete Custom How-To And Tutorial
    [Documentation]     Deletes the previously created CRD instance for custom How To and Tutorial resources
    Oc Delete   kind=OdhDocument    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}
    Close All Browsers

Create Custom Application
    [Documentation]     Creates a CRD instance of OdhApplication using a custom yaml
    Oc Apply    kind=OdhApplication    src=${APP_YAML}     namespace=${APPLICATIONS_NAMESPACE}
    Oc Get      kind=OdhApplication    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}

Delete Custom Application
    [Documentation]     Deletes the previously created OdhApplication CRD instance for custom Applciation resource
    Oc Delete   kind=OdhApplication    label_selector=app=custom-odsci-app  namespace=${APPLICATIONS_NAMESPACE}
    Close All Browsers

Load Expected Test Data
    [Documentation]     Loads the json with expected data in Explore page and extend it
    ...                 with expected information of the custom Application
    ${custom_app_dict}=  Load Json File  ${CUSTOM_APP_DICT_PATH}
    ${exp_data_dict}=    Load Expected Data Of RHODS Explore Section
    Set To Dictionary   ${exp_data_dict}    custom-odsci-app=${custom_app_dict["custom-odsci-app"]}
    RETURN  ${exp_data_dict}

Check Items Have Been Displayed In Resources Page
    [Documentation]     Launches Dashboard and waits until the custom doc item appears in Resources page
    [Arguments]        ${resource_filter}   ${expected_titles}  ${timeout}=120s     ${retry_interval}=5s
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...                ocp_user_auth_type=${TEST_USER.AUTH_TYPE}   dashboard_url=${ODH_DASHBOARD_URL}
    ...                browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Click Link      Resources
    Run Keyword And Continue On Failure
    ...               Wait Until Keyword Succeeds    ${timeout}    ${retry_interval}
    ...               Resource Page Should Contain   filter=${resource_filter}
    ...                                              search_term=${expected_titles[0]}
    ...                                              expected_items=${expected_titles}
    Capture Page Screenshot     ${expected_titles[0]}.png

External Link Should Be
    [Documentation]     Checks that the link displayed by the documentation item in Resources page
    ...                 corresponds to the expected one
    [Arguments]     ${expected_url}     ${item_type}
    IF  "${item_type}" == "documentation"
        ${href}=    Get Element Attribute    //a[text()="View documentation"]    href
    ELSE IF   "${item_type}" == "howto"
        ${href}=    Get Element Attribute    //a[text()="Read how-to article"]    href
    ELSE IF     "${item_type}" == "tutorial"
        ${href}=    Get Element Attribute    //a[text()="Access tutorial"]    href
    ELSE IF     "${item_type}" == "quickstart"
        ${href}=    Get Element Attribute    //a[text()="Open"]    href
    ELSE
        Log     "${item_type}" not recognized. Trying getting the footer link...    level=WARN
    END
    Run Keyword And Continue On Failure   Should Be Equal     ${expected_url}      ${href}

Check Custom QuickStart Item Has Been Successfully Created
    [Documentation]     Checks if RHODS Dashboard > Resources shows the custom QuickStart item
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["quickstart"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=QuickStart
    ...                                                   expected_titles=${exp_titles}
    Run Keyword And Continue On Failure
    ...    Verify Quick Starts Work As Expected When All Steps Are Marked As Yes   ${EXPECTED_QUICKSTART_IDS}

Check Custom Application Item Has Been Successfully Created
    [Documentation]     Checks if RHODS Dashboard shows the custom Application item.
    ...                 Explore page should report a tile for the custom application;
    ...                 the Resources page should display a "Documentation" item
    ...                 for the corresponding custom application
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["application"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=Documentation
    ...                                                     expected_titles=${exp_titles}
    Run Keyword And Continue On Failure     External Link Should Be     expected_url=${DASH_EXPLORE_EXP_DATA["custom-odsci-app"]["sidebar_links"]["0"]["url"]}
    ...                         item_type=documentation
    Click Link      Explore
    Wait For RHODS Dashboard To Load    expected_page=Explore
    Check Number Of Displayed Cards Is Correct    expected_data=${DASH_EXPLORE_EXP_DATA}
    Check Cards Details Are Correct    expected_data=${DASH_EXPLORE_EXP_DATA}

Check Custom How-To Item Has Been Successfully Created
    [Documentation]     Checks if RHODS Dashboard > Resources  shows the custom QuickStart item
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["howto"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=HowTo
    ...                                                   expected_titles=${exp_titles}
    Run Keyword And Continue On Failure     External Link Should Be     expected_url=${DASH_EXPLORE_EXP_DATA["custom-odsci-app"]["sidebar_links"]["0"]["url"]}
    ...                         item_type=howto

Check Custom Tutorial Item Has Been Successfully Created
    [Documentation]     Checks if RHODS Dashboard > Resources  shows the custom QuickStart item
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["tutorial"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=Tutorial
    ...                                                   expected_titles=${exp_titles}
    Run Keyword And Continue On Failure     External Link Should Be     expected_url=${DASH_EXPLORE_EXP_DATA["custom-odsci-app"]["sidebar_links"]["0"]["url"]}
    ...                         item_type=tutorial
