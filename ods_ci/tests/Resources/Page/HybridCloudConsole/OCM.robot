*** Settings ***
Resource        ../../Common.robot

Library         SeleniumLibrary


*** Keywords ***
Wait Until OCM Cluster Page Is Loaded
    [Documentation]     wait until the OCM page loads for ${cluster_name}
    [Arguments]    ${cluster_name}
    Wait OCM Splash Page
    Element Should Contain    //div[@class="pf-l-split__item"]/h1    ${cluster_name}

Login To OCM
    [Documentation]    Login to the OpenShift Cluster Manager
    Input Text    //div[@class="pf-c-form__group"]/input    ${SSO.USERNAME}
    Click Button   //*[@id="login-show-step2"]
    Sleep   1s
    Input Text    //*[@id="password"]    ${SSO.PASSWORD}
    Click Button    //*[@id="rh-password-verification-submit-button"]

Wait OCM Splash Page
   [Documentation]  Waits until the splash page (spinner, loading symbol) finishes to run
   Wait Until Page Contains Element    xpath://*[contains(@class, 'spinner')]   timeout=60
   Wait Until Page Does Not Contain Element    xpath://*[contains(@class, 'spinner')]   timeout=60
   Sleep    3
