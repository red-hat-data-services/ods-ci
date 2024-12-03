*** Settings ***
Resource        ../../Common.robot
Resource        ./HCCLogin.robot

Library         SeleniumLibrary


*** Keywords ***
Wait Until OCM Cluster Page Is Loaded
    [Documentation]     wait until the OCM page includes ClusterID ${cluster_id}
    [Arguments]    ${cluster_id}
    Wait OCM Splash Page
    Wait Until Page Contains Element    xpath=//*[@data-testid="clusterID" and text()="${cluster_id}"]    timeout=30s

Login To OCM
    [Documentation]    Login to the OpenShift Cluster Manager
    Maybe Accept Cookie Policy
    Input Text    //div[@class="pf-c-form__group"]/input    ${SSO.USERNAME}  # This is OCM page, so not PatternFly 5
    Click Button   //*[@id="login-show-step2"]
    Sleep   1s
    Input Text    //*[@id="password"]    ${SSO.PASSWORD}
    Click Button    //*[@id="rh-password-verification-submit-button"]

Wait OCM Splash Page
   [Documentation]  Waits until the splash page (spinner, loading symbol) finishes to run
   Wait Until Page Contains Element    xpath://*[contains(@class, 'spinner')]   timeout=60
   Wait Until Page Does Not Contain Element    xpath://*[contains(@class, 'spinner')]   timeout=60
   Sleep    3
