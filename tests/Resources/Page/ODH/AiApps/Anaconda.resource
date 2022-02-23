*** Settings ***
Documentation       Keyword suites to interact with Anaconda Commercial Edition

Resource            ../../../Page/LoginPage.robot
Library             SeleniumLibrary
Library             JupyterLibrary


*** Variables ***
${ANACONDA_APPNAME}=            anaconda-ce
${ANACONDA_DISPLAYED_NAME}=     Anaconda Commercial Edition
${ANACONDA_KEY_IN}=             Anaconda CE Key
${INVALID_KEY}=                 abcdef-invalidkey
${ERROR_MSG}=                   error\nValidation failed\nError attempting to validate. Please check your entries.
${VAL_SUCCESS_MSG}=             Validation result: 200
${TOKEN_VAL_SUCCESS_MSG}=       Success! Your token was validated and Conda has been configured.


*** Keywords ***
Enable Anaconda
    [Documentation]    Performs Anaconda activation
    [Arguments]    ${license_key}    ${license_validity}=${TRUE}
    Menu.Navigate To Page    Applications    Explore
    Wait Until Page Contains    Anaconda Commercial Edition    timeout=30
    Click Element    xpath://*[@id='${ANACONDA_APPNAME}']
    Wait Until Page Contains Element    ${ODH_DASHBOARD_SIDEBAR_HEADER_TITLE}    timeout=10
    ...    error=${ANACONDA_APPNAME} does not have sidebar with information in the Explore page of ODS Dashboard
    Page Should Contain Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    ...    message=${ANACONDA_APPNAME} does not have a "Enable" button in ODS Dashboard
    Click Button    ${ODH_DASHBOARD_SIDEBAR_HEADER_ENABLE_BUTTON}
    Insert Anaconda License Key    license_key=${license_key}
    Validate Anaconda License Key    license_validity=${license_validity}

Insert Anaconda License Key
    [Documentation]    Inserts the anaconda license key inside the modal
    [Arguments]    ${license_key}
    Wait Until Page Contains Element    xpath://*[@id='${ANACONDA_KEY_IN}']
    Input Text    xpath://*[@id='${ANACONDA_KEY_IN}']    ${license_key}

Validate Anaconda License Key
    [Documentation]    Run the validation process via the modal and wait until it finishes
    [Arguments]    ${license_validity}=${TRUE}
    Click Button    Connect
    IF    ${license_validity} == ${TRUE}
        Wait Until Keyword Succeeds    50    1    Page Should Not Contain Element
        ...    xpath://*/div[contains(@class, "bullseye")]
    ELSE IF    ${license_validity} == ${FALSE}
        Wait Until Keyword Succeeds    30    1    Check Connect Button Status    false
    END
    Capture Page Screenshot    after_validation.png

Check Connect Button Status
    [Documentation]    Checks the "Connect" button status of ACE's card in Explore page.
    ...    This check says the progress of activation process
    [Arguments]    ${target_status}    # true/false
    ${status}=    Get Connect Button Status
    Should Be Equal    ${status}    ${target_status}

Get Connect Button Status
    [Documentation]    Get the "Connect" button status of ACE's card in Explore page.
    ${button_status}=    Get Element Attribute    xpath://*/footer/*[.='Connect']    aria-disabled
    [Return]    ${button_status}

Check Anaconda CE Image Build Status
    [Documentation]    Checks the ACE's image build status
    [Arguments]    ${target_status}
    ${ace_build_status}=    Get Build Status    namespace=redhat-ods-applications
    ...    build_search_term=minimal-notebook-anaconda
    Run Keyword If    "${ace_build_status}" == "Failed"
    ...    Fail    the Anaconda image build has failed
    ...    ELSE
    ...    Should Be Equal    ${ace_build_status}    ${target_status}

Remove Anaconda Commercial Edition Component
    [Documentation]    Teardown for ACE test suite
    Close All Browsers
    Delete ConfigMap Using Name    redhat-ods-applications    anaconda-ce-validation-result
    Delete Pods Using Label Selector    redhat-ods-applications    component.opendatahub.io/name=anaconda-ce
    Delete BuildConfig Using Name    redhat-ods-applications    s2i-minimal-notebook-anaconda
    Delete ImageStream Using Name    redhat-ods-applications    s2i-minimal-notebook-anaconda
    Delete Data From Secrets Using Name    redhat-ods-applications    anaconda-ce-access    {"data":null}
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=anaconda-ce
    Close All Browsers

Anaconda Activation Should Have Failed
    [Documentation]    Checks if the anaconda activation has failed
    Capture Page Screenshot    anaconda_failed_activation.png
    ${text}=    Get Text    xpath://*[@class="pf-c-form__alert"]
    Should Be Equal    ${text}    ${ERROR_MSG}
