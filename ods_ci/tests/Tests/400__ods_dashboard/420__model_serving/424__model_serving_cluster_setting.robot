*** Settings ***
Documentation    Test cases that verify High Availability for ModelServing CLuster Setting
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource         ../../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup      Model Serving Cluster Setting Suite Setup
Suite Teardown   Model Serving Cluster Setting Suite Teardown
Test Setup       Model Serving Cluster Setting Test Setup
Test Tags        modelservingsetting  ODS-2574  Tier1  Sanity

*** Variables ***
${project_title}=  BLANKPROJ

*** Test Cases ***
Verify Correct Value in DS Project after Enabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after enabling both model serving platforms
    [Tags]  ODS-2574
    Select CheckBox Multi Model Serving Platforms
    Select CheckBox Single Model Serving Platforms
    Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_title}
    Click Element     //a[@href="#model-server"]
    Wait Until Page Contains Element    //*[@id="single-serving-platform-card"]
    Wait Until Page Contains Element    //*[@id="multi-serving-platform-card"]

Verify Correct Value in DS Project after Enabling Multi Model Serving Platforms Only
    [Documentation]    Verifies that correct values are present in the DS project after enabling Multi Model serving platforms only
    [Tags]  ODS-2574
    Select CheckBox Multi Model Serving Platforms
    Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_title}
    Click Element     //a[@href="#model-server"]
    Wait Until Page Contains Element    //*[contains(text(), "Multi-model serving enabled")]
    Wait Until Page Contains Element     //button[contains(text(), 'Add model server')]
    Page Should Not Contain Element    //button[contains(text(), 'Deploy model')]

Verify Correct Value in DS Project after Enabling Single Model Serving Platforms Only
    [Documentation]    Verifies that correct values are present in the DS project after enabling Single Model model serving platforms only
    [Tags]  ODS-2574
    Select CheckBox Single Model Serving Platforms
    Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${project_title}
    Click Element     //a[@href="#model-server"]
    Wait Until Page Contains Element    //button[contains(text(), 'Deploy model')]
    Wait Until Page Contains Element    //*[contains(text(), "Single-model serving enabled")]
    Page Should Not Contain Element     /button[contains(text(), 'Add model server')]

Verify Correct Value in DS Project after Disabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after disabling both model serving platforms
    [Tags]  ODS-2574
    Open Data Science Project Details Page      ${project_title}
    Click Element     //a[@href="#model-server"]
    Wait Until Page Contains Element    //*[contains(text(), "No model serving platform selected")]
    Page Should Not Contain Element     /button[contains(text(), 'Add model server')]
    Page Should Not Contain Element    //button[contains(text(), 'Deploy model')]

*** Keywords ***
Model Serving Cluster Setting Suite Setup
    [Documentation]    Opens the Dashboard Settings and Create DS project
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ...    expected_page=${NONE}    wait_for_cards=${FALSE}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${project_title}    description=test project

Model Serving Cluster Setting Test Setup
    [Documentation]    Opens the Dashboard Settings Deselect all the model serving.
    Open Dashboard Settings    settings_page=Cluster settings
    Wait Until Element Is Visible    ${SINGLE_MODE_SERVING_CHECK_BOX}  timeout=300s
    ${status_single_model}=  Get Checkbox State Of Single Modelserving platforms
    IF  "${status_single_model}"=="True"
        Unselect Checkbox   ${SINGLE_MODE_SERVING_CHECK_BOX}
    END

    ${status_multi_model}=  Get Checkbox State Of Multi Modelserving platforms
    IF  "${status_multi_model}"=="True"
        Unselect Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}
    END
    Capture Page Screenshot
    ${status} =   Evaluate    '${status_single_model}' == 'True' or '${status_multi_model}' == 'True'
    Run Keyword If    '${status}' == 'True'    Save Changes In Cluster Settings
    Reload Page
    Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]  timeout=20


Model Serving Cluster Setting Suite Teardown
    [Documentation]    Delete DS project and select both model serving options
    Delete Data Science Project                 ${project_title}
    Wait Until Data Science Project Is Deleted  ${project_title}
    Open Dashboard Settings    settings_page=Cluster settings
    Wait Until Page Contains Element    //*[contains(text(), "Model serving platforms")]  timeout=20
    Select Both Model Serving Platforms
    Save Changes In Cluster Settings
    Close Browser
