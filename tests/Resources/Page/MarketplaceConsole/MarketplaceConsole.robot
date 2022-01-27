*** Settings ***
Library         Collections

*** Keywords ***
Is SSO Login Page Visible
    Wait Until Element is Visible            //a[contains(@aria-label,"Log in")]
    Click Element     //a[contains(@aria-label,"Log in")]
    sleep   5
    ${login_prompt_visible} =  Run Keyword and Return Status  Page Should Contain    Enter your email to log in
    [Return]  ${login_prompt_visible}

Get the OC commands For Cluster registration
    Launch Cluster Tab from Marketplace
    sleep    5
    Wait until Element is Visible          //span[contains(text(),'Generate Secret')]        timeout=20
    Click Button    Generate Secret
    Wait Until Keyword Succeeds    30  1   Element Should Be Visible     //button[contains(@class, 'disabled')]/span[contains(text(),'Generate Secret')]
    sleep  5
    ${elem} =   Get WebElements      xpath://div[@role='textbox']//pre
    &{oc_command_dict}   	Create Dictionary
    @{itemname}   Create List     Create namespace         Red Hat Marketplace Subscription          Red Hat Marketplace Kubernetes Secret    Red Hat Marketplace global pull secret
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{elem}   start=0

        Set To Dictionary       ${oc_command_dict}      ${itemname[${idx}]}    ${ext_link.text}

    END
    [Return]    ${oc_command_dict}

Wait For Marketplace Page To Load
    Wait Until Page Contains Element    xpath://a[contains(text(), 'Workspace')]   timeout=15
    Page Should Contain      Red Hat Marketplace

Login to Marketplace
    [Arguments]  ${username}  ${password}
    ${login-required} =  Is SSO Login Page Visible
    IF    ${login-required} == True
      Wait Until Element is Visible  xpath://input[@id="email"]  timeout=5
      Input Text  id=email  ${username}
      Click Button    Next
      Wait Until Element is Visible  xpath://button[contains(text(),"Next")]  timeout=10
      Click Button    Next
      Wait Until Element is Visible  xpath://input[@id="password"]  timeout=5
      Input Text  id=password  ${password}
      Click Button    Log in
    END
    Run Keyword And Continue On Failure    Wait For Marketplace Page To Load

Launch Component from Header Dropdown
    [Arguments]  ${topic}  ${subtopic}
    Wait until Element is Visible       xpath://a[contains(text(), '${topic}')]    timeout=10
    Click Element           xpath://a[contains(text(), '${topic}')]
    Wait until Element is Visible  xpath://a[contains(@aria-label, '${subtopic}')]    timeout=20
    Click Element           xpath://a[contains(@aria-label, '${subtopic}')]
    sleep  5

Launch Cluster Tab from Marketplace
    Launch Component from Header Dropdown       Workspace        Clusters
    Wait until Element is Visible       xpath://*[contains(text(),"Add cluster")]    timeout=20
    Click Button       Add cluster
    Wait Until Page Contains                     Register cluster           timeout=120
    ${status}   Run Keyword and Return Status  Page Should Contain    Register cluster
    [Return]  ${status}