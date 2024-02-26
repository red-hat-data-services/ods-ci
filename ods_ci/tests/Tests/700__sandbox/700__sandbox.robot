*** Settings ***
Documentation    Test Suite for Sandbox Test cases
Resource        ../../Resources/Common.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/JupyterHub/ODHJupyterhub.resource
Library         String
Library         SeleniumLibrary
Suite Setup     Begin Web Test
Suite Teardown  End Web Test


*** Test Cases ***
Verify Application Switcher Have Only OpenShift Console Link
    [Documentation]    Application switcher should have only
    ...    openshift conosle link
    [Tags]     ODS-309
    ...        Sandbox
    Check Only OpenShift Link Is Present In Application Launcher

Verify ISV Integration Enablement Is Disabled
    [Documentation]    Verifies that all the ISV integration
    ...   components are disabled in the Dashboard
    [Tags]     ODS-530
    ...        Sandbox
    Click Link    Explore
    Capture Page Screenshot   explor.png
    Wait Until Cards Are Loaded
    Sleep    5s
    Verify None Of The Card Are Enabled

Verify RHODS "Support" Link Hidden In ODH Dashboard
    [Documentation]   Verify support link disabled/hidden
    ...   as in sandbox they should have only the documentation link
    [Tags]    ODS-526
    ...       Sandbox
    Verify Support Link Is Not Present in RHODS Dashbaord

Verify JupyterHub Spawner Only Allows Small Server Size In Sandbox Environment
    [Documentation]    Only Default and Small size is present
    ...    on spawner
    [Tags]     ODS-528
    ...        Sandbox
    Navigate To Page    Applications    Enabled
    Launch JupyterHub Spawner From Dashboard
    Available Container Sizes Should Be

Verify That Idle JupyterLab Servers Are Culled In Sandbox Environment After 24h
    [Documentation]   Jupyterlab Servershould be culled
    ...    after 24 hours
    [Tags]     ODS-547
    ...        Sandbox
    ...        Execution-Time-Over-1d
    Spawn Notebook With Arguments
    ${jl_title}     Get Title
    Switch Window    title=Red Hat OpenShift AI
    Sleep    24h
    Switch Window     title=${jl_title}
    Wait Until Keyword Succeeds    120    2
    ...    Page Should Contain    Server unavailable or unreachable


*** Keywords ***
Check Only OpenShift Link Is Present In Application Launcher
     [Documentation]  Capture and check if only Openshift link is present
     Click Element     //button[@aria-label="Application launcher"]
     Wait Until Element Is Visible        //a[@class="pf-m-external pf-v5-c-app-launcher__menu-item"]
     ${link_elements}  Get WebElements    //a[@class='pf-m-external pf-v5-c-app-launcher__menu-item']
     ${length}         Get Length    ${link_elements}
     ${href}   Get Element Attribute    ${link_elements}    href
     ${length}         Get Length    ${link_elements}
     IF    ${length} == ${1}
           Should Contain      ${href}    console-openshift   ignore_case=True
     ELSE
           Run Keyword And Continue On Failure    Fail    More than one link is present
     END

Available Container Sizes Should Be
    [Documentation]  Capture the avialble size and compare
    ...   the value
    ${size}    Get List Of All Available Container Size
    Run Keywords     List Should Contain Value    ${size}    Default
    ...    AND
    ...    List Should Contain Value    ${size}    Small
    ...    AND
    ...    List Should Not Contain Value    ${size}    Medium

Verify None Of The Card Are Enabled
    [Documentation]    Verify none of the cards available in explore section is enabled
    ${link_elements}  Get WebElements    //div[@class="pf-v5-c-card pf-m-selectable odh-card"]
    ${length}      Get Length    ${link_elements}
    IF  ${length} != ${0}    Fail     '${length}' tiles in Explore section is Enabled

Verify Support Link Is Not Present in RHODS Dashbaord
    [Documentation]   Check suppurt url is not present in the sandbox RHODS dashabord
    Click Element    xpath=//*[@id="toggle-id"]
    ${links_available}   Get WebElements
    ...    //a[@class="odh-dashboard__external-link pf-v5-c-dropdown__menu-item" and not(starts-with(@href, '#'))]
    FOR  ${link}  IN  @{links_available}
         ${href}    Get Element Attribute    ${link}    href
         Run Keyword And Continue On Failure   Should Not Contain   ${href}   support   ignore_case=True
    END
