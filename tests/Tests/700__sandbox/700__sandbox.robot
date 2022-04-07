*** Settings ***
Documentation    Test Suite for Sandbox Test cases
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Library         String
Library         SeleniumLibrary
Suite Setup     Begin Web Test
Suite Teardown  End Web Test


*** Variables ***
${SANDBOX_AUTH_TYPE}   *******
${SANDBOX_USERNAME}    *******
${SANDBOX_PASSWORD}    *******
${SANDBOX_OCP_URL}     *******


*** Test Cases ***
Verify Application Switcher Have Only Opneshift Console Link
    [Documentation]    Application switcher should have only
    ...    openshift conosle link
    [Tags]     ODS-309
    ...        Sandbox
    Check Openshift Console

Verify ISV integration enablement IS Disabled
    [Documentation]    All the isv integration
    ...   component should be diabled
    [Tags]     ODS-530
    ...        Sandbox
    Click Link    Explore
    Capture Page Screenshot   explor.png
    Wait Until Cards Are Loaded
    Sleep    5s
    ${link_elements}  Get WebElements    //article[@class="pf-c-card odh-card m-disabled"]
    ${length}      Get Length    ${link_elements}
    Run Keyword If  ${length} != ${11}    Fail     '${length}' tiles in Explore section is disabled

Verify Support Link Doesn't Exist
    [Documentation]   Only documentaion link is present
    [Tags]    ODS-526
    ...       Sandbox
    Click Element    xpath=//*[@id="toggle-id"]
    ${links_avialble}   Get WebElements
    ...    //a[@class="odh-dashboard__external-link pf-c-dropdown__menu-item" and not(starts-with(@href, '#'))]
    FOR  ${link}  IN  @{links_avialble}
         ${href}    Get Element Attribute    ${link}    href
         Run Keyword And Continue On Failure   Should Not Contain   ${href}   support   ignore_case=True
    END

Verify only small size is available for sandbox enviroinment
    [Documentation]    Only Default and Small size is present
    ...    on spawner
    [Tags]     ODS-528
    ...        Sandbox
    Navigate To Page    Applications    Enabled
    Launch JupyterHub Spawner From Dashboard
    Match Small And Default Container Size

Verify that idle Jupyterhub servers are culled
    [Documentation]   Jupyterhub should be culled
    ...    after 24 hours
    [Tags]     ODS-547
    Spawn Notebook With Arguments
    ${jl_title}     Get Title
    Switch Window    title=Red Hat OpenShift Data Science Dashboard
    Sleep    24h
    Switch Window     title=${jl_title}
    Wait Until Keyword Succeeds    120    2
    ...    Page Should Contain    Server unavailable or unreachable


*** Keywords ***
Get RHODS URL From OCP
    [Documentation]    Capture and return rhods url from
    ...     OCP console
    Switch To Administrator Perspective
    Click Element     //button[@aria-label="Application launcher"]
    Wait Until Element Is Visible    //a[@data-test="application-launcher-item"]
    ${link_elements}  Get WebElements
    ...     //a[@data-test="application-launcher-item" and starts-with(@href,'https://rhods')]
    ${href}  Get Element Attribute    ${link_elements}    href
    [Return]   ${href}

Check Openshift Console
     [Documentation]  capture and check if only OSD link is present
     Click Element     //button[@aria-label="Application launcher"]
     Wait Until Element Is Visible        //a[@class="pf-m-external pf-c-app-launcher__menu-item"]
     ${link_elements}  Get WebElements    //a[@class='pf-m-external pf-c-app-launcher__menu-item']
     ${length}         Get Length    ${link_elements}
     ${href}   Get Element Attribute    ${link_elements}    href
     ${length}         Get Length    ${link_elements}
     IF    ${length} == ${1}
           Should Contain      ${href}    console-openshift   ignore_case=True
     ELSE
           Run Keyword And Continue On Failure    Fail    More than one link is present
     END

Match Small And Default Container Size
    [Documentation]  Capture the avialble size and compare
    ...   the value
    Wait Until Page Contains    Container size    timeout=30
    ...    error=Container size selector is not present in JupyterHub Spawner
    ${size}    Create List
    Click Element  xpath://div[contains(concat(' ',normalize-space(@class),' '),' jsp-spawner__size_options__select ')]\[1]
    ${link_elements}   Get WebElements  xpath://*[@class="pf-c-select__menu-item-main"]
    FOR  ${idx}  ${ext_link}  IN ENUMERATE  @{link_elements}  start=1
          ${text}      Get Text    ${ext_link}
          Append To List    ${size}     ${text}
    END
    Run Keywords     List Should Contain Value    ${size}    Default
    ...    AND
    ...    List Should Contain Value    ${size}    Small
    ...    AND
    ...    List Should Not Contain Value    ${size}    Medium
