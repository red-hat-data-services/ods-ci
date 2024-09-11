*** Settings ***
Documentation    Test cases that verify High Availability for ModelServing CLuster Setting
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource         ../../Resources/Page/ODH/ODHDashboard/ODHModelServing.resource
Suite Setup      Model Serving Cluster Setting Suite Setup
Suite Teardown   Model Serving Cluster Setting Suite Teardown
Test Setup       Model Serving Cluster Setting Test Setup
Test Tags        modelservingsetting    ODS-2574    Sanity


*** Variables ***
${PROJECT_TITLE}=  BLANKPROJ
${MODELS_TAB}=  //button[@role="tab" and @aria-controls="model-server"]


*** Test Cases ***
Verify Correct Value in DS Project after Enabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after enabling
    ...    both model serving platforms
    Select CheckBox Multi Model Serving Platforms
    Select CheckBox Single Model Serving Platforms
    SeleniumLibrary.Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${PROJECT_TITLE}    tab_id=model-server
    SeleniumLibrary.Click Button     xpath:${MODELS_TAB}
    SeleniumLibrary.Wait Until Page Contains Element    //*[@data-testid="single-serving-platform-card"]
    SeleniumLibrary.Wait Until Page Contains Element    //*[@data-testid="multi-serving-platform-card"]

Verify Correct Value in DS Project after Enabling Multi Model Serving Platforms Only
    [Documentation]    Verifies that correct values are present in the DS project after enabling
    ...    Multi Model serving platforms only
    Select CheckBox Multi Model Serving Platforms
    SeleniumLibrary.Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${PROJECT_TITLE}    tab_id=model-server
    SeleniumLibrary.Click Button     xpath:${MODELS_TAB}
    SeleniumLibrary.Wait Until Page Contains Element    //*[contains(text(), "Multi-model serving enabled")]
    SeleniumLibrary.Wait Until Page Contains Element     //button[contains(text(), 'Add model server')]
    SeleniumLibrary.Page Should Not Contain Element    //button[contains(text(), 'Deploy model')]

Verify Correct Value in DS Project after Enabling Single Model Serving Platforms Only
    [Documentation]    Verifies that correct values are present in the DS project after enabling
    ...    Single Model model serving platforms only
    Select CheckBox Single Model Serving Platforms
    SeleniumLibrary.Capture Page Screenshot
    Save Changes In Cluster Settings
    Open Data Science Project Details Page      ${PROJECT_TITLE}    tab_id=model-server
    SeleniumLibrary.Click Button     xpath:${MODELS_TAB}
    SeleniumLibrary.Wait Until Page Contains Element    //button[contains(text(), 'Deploy model')]
    SeleniumLibrary.Wait Until Page Contains Element    //*[contains(text(), "Single-model serving enabled")]
    SeleniumLibrary.Page Should Not Contain Element     /button[contains(text(), 'Add model server')]

Verify Correct Value in DS Project after Disabling Both Model Serving Platforms
    [Documentation]    Verifies that correct values are present in the DS project after disabling
    ...    both model serving platforms
    Open Data Science Project Details Page      ${PROJECT_TITLE}    tab_id=model-server
    SeleniumLibrary.Click Button     xpath:${MODELS_TAB}
    SeleniumLibrary.Wait Until Page Contains Element    //*[contains(text(), "No model serving platform selected")]
    SeleniumLibrary.Page Should Not Contain Element     /button[contains(text(), 'Add model server')]
    SeleniumLibrary.Page Should Not Contain Element    //button[contains(text(), 'Deploy model')]


*** Keywords ***
Model Serving Cluster Setting Suite Setup
    [Documentation]    Opens the Dashboard Settings and Create DS project
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard   ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}
    ...    expected_page=${NONE}    wait_for_cards=${FALSE}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PROJECT_TITLE}    description=test project

Model Serving Cluster Setting Test Setup    # robocop: off=too-many-calls-in-keyword
    [Documentation]    Opens the Dashboard Settings Deselect all the model serving.
    Open Dashboard Settings    settings_page=Cluster settings
    SeleniumLibrary.Wait Until Element Is Visible    ${SINGLE_MODE_SERVING_CHECK_BOX}  timeout=300s
    ${status_single_model}=  Get Checkbox State Of Single Modelserving platforms    # robocop: off=wrong-case-in-keyword-name,line-too-long
    IF  "${status_single_model}"=="True"
        SeleniumLibrary.Unselect Checkbox   ${SINGLE_MODE_SERVING_CHECK_BOX}
    END

    ${status_multi_model}=  Get Checkbox State Of Multi Modelserving platforms    # robocop: off=wrong-case-in-keyword-name,line-too-long
    IF  "${status_multi_model}"=="True"
        SeleniumLibrary.Unselect Checkbox   ${MULTI_MODEL_SERVING_CHECK_BOX}
    END
    SeleniumLibrary.Capture Page Screenshot
    ${status}=   Evaluate    '${status_single_model}' == 'True' or '${status_multi_model}' == 'True'
    IF    '${status}' == 'True'    Save Changes In Cluster Settings
    SeleniumLibrary.Reload Page
    SeleniumLibrary.Wait Until Page Contains Element    //input[@id="multi-model-serving-platform-enabled-checkbox"]
    ...    timeout=20

Model Serving Cluster Setting Suite Teardown
    [Documentation]    Delete DS project and select both model serving options
    Delete Project Via CLI By Display Name                 ${PROJECT_TITLE}
    Wait Until Data Science Project Is Deleted  ${PROJECT_TITLE}
    Open Dashboard Settings    settings_page=Cluster settings
    SeleniumLibrary.Wait Until Page Contains Element    //*[contains(text(), "Model serving platforms")]  timeout=20
    Select Both Model Serving Platforms
    Save Changes In Cluster Settings
    SeleniumLibrary.Close Browser
