*** Settings ***
Documentation    Test cases that verify High Availability for ModelServing CLuster Setting

Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup      Sute Setup
Suite Teardown   Sute Tierdown
Test Setup       Tst Setup
Test Tags         modelservingsetting  ODS-2574  Tier1  Sanity

*** Variables ***
${project_tittel}=  blank_proj


*** Keywords ***
Sute Setup
    [Documentation]    Opens the Dashboard Settings and Create DS project
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ...    expected_page=${NONE}    wait_for_cards=${FALSE}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${project_tittel}    description=test project

Tst Setup
    [Documentation]    Opens the Dashboard Settings Deselect all the model serving.
    Open Dashboard Settings    settings_page=Cluster settings
    Reload Page
    Wait Until Element Is Visible    ${SINGLE_MODE_SERVING_CHECK_BOX}  timeout=300s
    ${status_single_mode}=  Get Checkbox State Of Single Modelserving platforms
    IF  "${status_single_mode}"=="True"
        Unselect Checkbox   ${SINGLE_MODE_SERVING_CHECK_BOX}
    END

    ${status_multi_mode}=  Get Checkbox State Of Multi Modelserving platforms
    IF  "${status_multi_mode}"=="True"
        Unselect Checkbox   ${MULTI_MODE_SERVING_CHECK_BOX}
    END
    Capture Page Screenshot
    ${status} =   Evaluate    '${status_single_mode}' == 'True' or '${status_multi_mode}' == 'True'
    Run Keyword If    '${status}' == 'True'    Save Changes In Cluster Settings


Sute Tierdown
    [Documentation]    Delete DS project and select both model serving options

    Delete Data Science Project                 ${project_tittel}
    Wait Until Data Science Project Is Deleted  ${project_tittel}
    Open Dashboard Settings    settings_page=Cluster settings
    Reload Page
    Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]  timeout=20
    Select Both Model Serving Platforms
    Close Browser


*** Test Cases ***
Verify Correct Value in DS Project after Enabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after enabling both model serving platforms
    #Case 1
    Open Dashboard Settings    settings_page=Cluster settings
    Reload Page
    Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]  timeout=20
    Select CheckBox Multi Model Serving Platforms
    Select CheckBox Single Model Serving Platforms
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_tittel}

    Click Element    //*[contains(@class, 'pf-v5-c-jump-links') and contains(@class, 'pf-v5-c-jump-links__link-text') and contains(., 'Models and model servers')]
    Wait Until Page Contains Element    //*[contains(text(), "Deploy model")]
    Wait Until Page Contains Element    //*[contains(text(), "Add model server")]

Verify Correct Value in DS Project after Enabling Multi Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after enabling both Multi Model serving platforms
    #Case 2
    Open Dashboard Settings    settings_page=Cluster settings
    Reload Page
    Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]  timeout=20
    Select CheckBox Multi Model Serving Platforms
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_tittel}

    Click Element    //*[contains(@class, 'pf-v5-c-jump-links') and contains(@class, 'pf-v5-c-jump-links__link-text') and contains(., 'Models and model servers')]
    Wait Until Page Contains Element     //button[contains(text(), 'Add model server')]

Verify Correct Value in DS Project after Enabling Single Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after enabling Single Model model serving platforms

    #Case 3
    Open Dashboard Settings    settings_page=Cluster settings
    Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]  timeout=20
    Select CheckBox Single Model Serving Platforms
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_tittel}

    Click Element    //*[contains(@class, 'pf-v5-c-jump-links') and contains(@class, 'pf-v5-c-jump-links__link-text') and contains(., 'Models and model servers')]
    Wait Until Page Contains Element    //button[contains(text(), 'Deploy model')]


Verify Correct Value in DS Project after Disabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after disabling both model serving platforms
    #Case 4
    Open Data Science Project Details Page      ${project_tittel}

    Click Element    //*[contains(@class, 'pf-v5-c-jump-links') and contains(@class, 'pf-v5-c-jump-links__link-text') and contains(., 'Models and model servers')]
    Wait Until Page Contains Element    //*[contains(text(), "No model serving platform selected")]
