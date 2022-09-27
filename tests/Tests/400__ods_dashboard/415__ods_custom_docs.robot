*** Settings ***
Library         OpenShiftLibrary
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/LoginPage.robot
Resource        ../../Resources/Page/OCPLogin/OCPLogin.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ResourcesPage.resource
Suite Setup      Custom Doc Test Setup
# Suite Teardown   Resources Page Suite Teardown


*** Variables ***
${QS_YAML}=    tests/Resources/Files/custom_quickstart.yaml
${APP_YAML}=    tests/Resources/Files/custom_app.yaml
${HOWTO_YAML}=    tests/Resources/Files/custom_doc_howto.yaml
${TUTORIAL_YAML}=    tests/Resources/Files/custom_doc_tutorial.yaml
&{EXPECTED_ITEMS_TITLES}=    quickstart=TEST - Custom Quick Start
...                          application=TEST - Custom ODS-CI Application
...                          howto=TEST - Custom How-To Documentation
...                          tutorial=TEST - Custom Tutorial Documentation
${CUSTOM_APP_DICT_PATH}=   tests/Resources/Files/CustomAppInfoDictionary.json


*** Test Cases ***
Install Custom QuickStart
    [Documentation]     Tests if it is possible to create custom quick start resource item in Dashboard.
    ...                 It works by  creating the corresponding CustomResource in the cluster
    [Tags]  Sanity    Tier2
    ...     ODS-697
    Create Custom QuickStart
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["quickstart"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=QuickStart
    ...                                                     expected_titles=${exp_titles}
    [Teardown]     Delete Custom Quick Start

Install Custom Application
    [Documentation]     Tests if it is possible to create custom application resource item in Dashboard.
    ...                 It works by  creating the corresponding CustomResource in the cluster
    [Tags]  Sanity    Tier2
    ...     ODS-XYZ
    Create Custom Application
    ${exp_titles}=      Create List    ${EXPECTED_ITEMS_TITLES["application"]}
    Check Items Have Been Displayed In Resources Page     resource_filter=Documentation
    ...                                                     expected_titles=${exp_titles}
    Click Link      Explore
    Wait Until Cards Are Loaded
    Check Number Of Displayed Cards Is Correct    expected_data=${DASH_EXPLORE_EXP_DATA}
    Check Cards Details Are Correct    expected_data=${DASH_EXPLORE_EXP_DATA}
    [Teardown]     Delete Custom Application


*** Keywords ***
Custom Doc Test Setup
    [Documentation]     Open RHODS Dashboard page and move to Resources page
    Set Library Search Order    SeleniumLibrary
    # RHOSi Setup
    ${dashboard_explore_exp_data}=   Load Expected Test Data
    Set Suite Variable      ${DASH_EXPLORE_EXP_DATA}   ${dashboard_explore_exp_data}

Resources Page Suite Teardown
    Close All Browsers
    # RHOSi Teardown

Create Custom QuickStart
    [Documentation]     Creates a CRD instance of OdhQuickStarts using a custom yaml
    Oc Apply    kind=OdhQuickStart    src=${QS_YAML}     namespace=redhat-ods-applications
    Oc Get      kind=OdhQuickStart    label_selector=app=ods-ci  namespace=redhat-ods-applications

Delete Custom Quick Start
    [Documentation]     Deletes the previously created CRD instance
    Oc Delete   kind=OdhQuickStart    label_selector=app=ods-ci  namespace=redhat-ods-applications
    Close All Browsers

Create Custom Application
    [Documentation]     Creates a CRD instance of OdhQuickStarts using a custom yaml
    Oc Apply    kind=OdhApplication    src=${APP_YAML}     namespace=redhat-ods-applications
    Oc Get      kind=OdhApplication    label_selector=app=ods-ci  namespace=redhat-ods-applications

Delete Custom Application
    [Documentation]     Deletes the previously created OdhApplication CRD instance
    Oc Delete   kind=OdhApplication    label_selector=app=ods-ci  namespace=redhat-ods-applications
    Close All Browsers

Load Expected Test Data
    ${custom_app_dict}=  Load Json File  ${CUSTOM_APP_DICT_PATH}
    ${exp_data_dict}=    Load Expected Data Of RHODS Explore Section
    Set To Dictionary   ${exp_data_dict}    ods-ci=${custom_app_dict["ods-ci"]}
    [Return]  ${exp_data_dict}

Check Items Have Been Displayed In Resources Page
    [Documentation]     Launches Dashboard and waits until the custom doc item appears in Resources page
    [Arguments]        ${resource_filter}   ${expected_titles}  ${timeout}=120s     ${retry_interval}=5s
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...                ocp_user_auth_type=${TEST_USER.AUTH_TYPE}   dashboard_url=${ODH_DASHBOARD_URL}
    ...                browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Click Link      Resources
    Wait Until Keyword Succeeds    ${timeout}    ${retry_interval}
    ...                            Resource Page Should Contain     filter=${resource_filter}
    ...                                                             search_term=${expected_titles[0]}
    ...                                                             expected_items=${expected_titles}
