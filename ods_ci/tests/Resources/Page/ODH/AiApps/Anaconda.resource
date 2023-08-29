*** Settings ***
Documentation       Keyword suites to interact with Anaconda Professional

Resource            ../../../Page/LoginPage.robot
Library             SeleniumLibrary
Library             JupyterLibrary


*** Variables ***
${ANACONDA_APPNAME}=            anaconda-ce
${ANACONDA_DISPLAYED_NAME}=     Anaconda Commercial Edition
${ANACONDA_DISPLAYED_NAME_LATEST}=    Anaconda Professional
${ANACONDA_KEY_IN}=             Anaconda CE Key
${INVALID_KEY}=                 abcdef-invalidkey
${ERROR_MSG}=                   error\nValidation failed\nError attempting to validate. Please check your entries.
${VAL_SUCCESS_MSG}=             Validation result: 200
${TOKEN_VAL_SUCCESS_MSG}=       Success! Your token was validated and Conda has been configured.
${PKG_INSTALL_ERROR_MSG}=   Collecting package metadata (current_repodata.json): failed
...  UnavailableInvalidChannel: HTTP 403 FORBIDDEN for channel repo/main <https://repo.anaconda.cloud/repo/main>
...  The channel is not accessible or is invalid.
...  You will need to adjust your conda configuration to proceed.
...  Use `conda config --show channels` to view your configuration's current state,
...  and use `conda config --show-sources` to view config file locations.
${CONDARC_CAT_RESULT}=  restore_free_channel: false
...  default_channels:
...  - https://repo.anaconda.cloud/repo/main
...  - https://repo.anaconda.cloud/repo/msys2
...  - https://repo.anaconda.cloud/repo/r


*** Keywords ***
Enable Anaconda
    [Documentation]    Performs Anaconda activation
    [Arguments]    ${license_key}    ${license_validity}=${TRUE}
    Menu.Navigate To Page    Applications    Explore
    Verify Page Contain Anaconda Based On Version
    ${status}=    Open Get Started Sidebar And Return Status    card_locator=//*[@id='${ANACONDA_APPNAME}']
    Run Keyword And Continue On Failure    Should Be Equal    ${status}    ${TRUE}
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
        Wait Until Keyword Succeeds    90    1    Page Should Not Contain Element
        ...    xpath://*/div[contains(@class, "bullseye")]
    ELSE IF    ${license_validity} == ${FALSE}
        Wait Until Keyword Succeeds    40    2    Check Connect Button Status    false
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
    RETURN    ${button_status}

Check Anaconda CE Image Build Status
    [Documentation]    Checks the ACE's image build status
    [Arguments]    ${target_status}
    ${ace_build_status}=    Get Build Status    namespace=${APPLICATIONS_NAMESPACE}
    ...    build_search_term=minimal-notebook-anaconda
    IF    "${ace_build_status}" == "Failed"
    ...    Fail    the Anaconda image build has failed
    ...    ELSE
    ...    Should Be Equal    ${ace_build_status}    ${target_status}

Remove Anaconda Component
    [Documentation]    Teardown for ACE test suite
    Remove Anaconda Components For Validation
    Delete BuildConfig Using Name    ${APPLICATIONS_NAMESPACE}    s2i-minimal-notebook-anaconda
    Delete ImageStream Using Name    ${APPLICATIONS_NAMESPACE}    s2i-minimal-notebook-anaconda
    Launch Dashboard    ocp_user_name=${TEST_USER.USERNAME}    ocp_user_pw=${TEST_USER.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Remove Disabled Application From Enabled Page    app_id=anaconda-ce

Remove Anaconda Components For Validation
    [Documentation]    Teardown for ACE test suite
    Delete ConfigMap Using Name    ${APPLICATIONS_NAMESPACE}    anaconda-ce-validation-result
    Delete Pods Using Label Selector    ${APPLICATIONS_NAMESPACE}    component.opendatahub.io/name=anaconda-ce
    Delete Data From Secrets Using Name    ${APPLICATIONS_NAMESPACE}    anaconda-ce-access    {"data":null}


Anaconda Activation Should Have Failed
    [Documentation]    Checks if the anaconda activation has failed
    Capture Page Screenshot    anaconda_failed_activation.png
    ${text}=    Get Text    xpath://*[@class="pf-c-form__alert"]
    Should Be Equal    ${text}    ${ERROR_MSG}

Verify Anaconda Element Present Based On Version
  [Documentation]   Checks Anaconda input element present based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Wait Until Page Contains Element  xpath://input[@name='Anaconda Commercial Edition']  timeout=15
  ELSE
    Wait Until Page Contains Element  xpath://input[@name='Anaconda Professional']    timeout=15
  END

Verify Anaconda Element Enabled Based On Version
  [Documentation]   Checks Anaconda element is enabled based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Wait Until Element Is Enabled    xpath://input[@name="Anaconda Commercial Edition"]   timeout=10
  ELSE
    Wait Until Element Is Enabled    xpath://input[@name="Anaconda Professional"]   timeout=10
  END

Verify Anaconda Card Present Based On Version
  [Documentation]   Checks Anaconda card is present based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]
  ELSE
    Page Should Contain Element  xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Professional"]
  END

Verify Anaconda Card Not Present Based On Version
  [Documentation]    Checks Anaconda card is not present based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Page Should Not Contain Element     xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Commercial Edition"]
  ELSE
    Page Should Not Contain Element     xpath://div[@class="pf-c-card__title"]/span[.="Anaconda Professional"]
  END

Verify Service Is Available In The Explore Page Based On Version
  [Documentation]   Checks service is available in explore page based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Verify Service Is Available In The Explore Page    Anaconda Commercial Edition
  ELSE
    Verify Service Is Available In The Explore Page    Anaconda Professional
  END

Verify Service Provides "Get Started" Button In The Explore Page Based On Version
  [Documentation]    Checks service provides "get started" button in explore based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Commercial Edition
  ELSE
    Verify Service Provides "Get Started" Button In The Explore Page    Anaconda Professional
  END

Verify Service Provides "Enable" Button In The Explore Page Based On Version
  [Documentation]   Checks service provides "enable" button in explore page based on version
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Verify Service Provides "Enable" Button In The Explore Page     Anaconda Commercial Edition
  ELSE
    Verify Service Provides "Enable" Button In The Explore Page     Anaconda Professional
  END

Verify Anaconda Service Is Enabled Based On Version
  [Documentation]   Checks service is enabled based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Verify Service Is Enabled   Anaconda Commercial Edition
  ELSE
    Verify Service Is Enabled   Anaconda Professional
  END

Verify Page Contain Anaconda Based On Version
  [Documentation]    Checks page contain Anaconda text or not based on version.
  ${version-check}=  Is RHODS Version Greater Or Equal Than  1.11.0
  IF  ${version-check}==False
    Wait Until Page Contains    Anaconda Commercial Edition     timeout=30
  ELSE
    Wait Until Page Contains    Anaconda Professional           timeout=30
  END
