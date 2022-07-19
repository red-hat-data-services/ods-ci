*** Settings ***
Library         OpenShiftCLI
Resource        ../../Resources/ODS.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource        ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource        ../../Resources/Page/LoginPage.robot
Test Setup      Resources Test Setup
Test Teardown   Resources Test Teardown


*** Test Cases ***
Verify Quick Starts Work As Expected
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1166    ODS-1306
    ...     ODS-1307    ODS-1308
    ...     ODS-1402    ODS-1403
    Verify Quick Starts Work As Expected When All Steps Are Marked As Yes   create-jupyter-notebook-anaconda
    Verify Quick Starts Work As Expected When Restarting The Previous One   create-jupyter-notebook-anaconda
    Verify Quick Starts Work As Expected When All Steps Are Skipped         create-jupyter-notebook
    Verify Quick Starts Work As Expected When At Least One Step Is Skipped      deploy-python-model
    Verify Quick Starts Work As Expected When One Step Is Marked As No  openvino-inference-notebook

Verify External Links In Quick Starts Are Not Broken
        [Tags]  Sanity    
        ...     Tier1
        ...     ODS-1305
        [Documentation]    Verify external links in Quick Starts are not broken
        Click Link                 Resources
        ${quickStartElements}=     Get QuickStart Items
        Verify Links Are Not Broken For Each QuickStart      ${quickStartElements}

Verify Resource Link HTTP Status Code
    [Documentation]    Verifies the how-to, documentation and tutorial cards in Resource page
    ...                redirects users to working URLs (i.e., http status must be 200)
    [Tags]    Sanity
    ...       ODS-531    ODS-507
    Click Link    Resources
    Sleep    5
    ${link_elements}=     Get Link Web Elements From Resource Page
    URLs HTTP Status Code Should Be Equal To     link_elements=${link_elements}    expected_status=200

*** Keywords ***
Resources Test Setup
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Click Link      Resources
    Sleep   5

Resources Test Teardown
    Close All Browsers

Verify Quick Starts Work As Expected When All Steps Are Marked As Yes
    [Arguments]    ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        Run Keyword And Continue On Failure     Mark Step Check As Yes
        IF  ${index} != ${count-1}
            Go To Next QuickStart Step
        END
    END
    Run Keyword And Continue On Failure     Go Back And Check Previouse Step Is Selected     n_steps=${count}   exp_step=${count-1}
    Run Keyword And Continue On Failure         Mark Step Check As Yes
    Go To Next QuickStart Step
    Go To Next QuickStart Step
    Close QuickStart From Button
    Run Keyword And Continue On Failure     Page Should Not Contain QuickStart Sidebar
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}  Complete

Verify Quick Starts Work As Expected When Restarting The Previous One
    [Arguments]    ${element}
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Restart
    Run Keyword And Continue On Failure     QuickStart Status Should Not Be Set     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Close
    Continue QuickStart
    Run Keyword And Continue On Failure     Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=cancel
    Run Keyword And Continue On Failure     Current Step In QuickStart Should Be    n_steps=${count}  exp_step=1
    Close QuickStart From Top     decision=leave
    Run Keyword And Continue On Failure     Page Should Not Contain QuickStart Sidebar
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}  In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

Verify Quick Starts Work As Expected When One Step Is Marked As No
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        IF  ${index} != ${count-1}
            Run Keyword And Continue On Failure     Mark Step Check As Yes
        ELSE
            Run Keyword And Continue On Failure     Mark Step Check As No
        END
        Go To Next QuickStart Step
    END
    Close QuickStart From Button
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      Failed

Verify Quick Starts Work As Expected When All Steps Are Skipped
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        Go To Next QuickStart Step
    END
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

Verify Quick Starts Work As Expected When At Least One Step Is Skipped
    [Arguments]     ${element}
    Open QuickStart Element in Resource Section By Name     ${element}
    ${count}=   Get The Count Of QuickStart Steps
    Star QuickStart Tour
    FOR     ${index}    IN RANGE    ${count}
        IF  ${index} == ${0}
            Run Keyword And Continue On Failure     Mark Step Check As No
        END
        Go To Next QuickStart Step
    END
    Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}      In Progress
    Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}  exp_link_text=Continue

External URLs Should Not Be Broken
    [Documentation]     Go through a QuickStart and checks the status of all the external links
    ${quick_start_steps}=   Get WebElements   //button[@class='pf-c-wizard__nav-link']
    ${element_list}=    Get WebElements    xpath=//div[@Class="pf-c-drawer__panel-main"]//a[@href]
    URLs HTTP Status Code Should Be Equal To    ${element_list}

    FOR    ${quick_start_step}    IN     @{quick_start_steps}
            Open QuickStart Step  ${quick_start_step}
            ${element_list}=    Get WebElements    xpath=//div[@Class="pf-c-drawer__panel-main"]//a[@href]
            URLs HTTP Status Code Should Be Equal To    ${element_list}
            ${Doc_Text}     Get Text  //*[@class="pf-c-drawer__body pf-m-no-padding pfext-quick-start-panel-content__body"]
            ${Doc_links}     Get Regexp Matches   ${Doc_Text}   (?:(?:(?:ftp|http)[s]*:\/\/|www\.)[^\.]+\.[^ \n]+)
            IF  ${Doc_links}
                Validate Links Extracted From Text     ${Doc_links}
            END
    END

Verify Links Are Not Broken For Each QuickStart
    [Documentation]     Clicks on al the quick start and verify links
    [Arguments]    ${quickStartElements}
    ${quickStartCount}=   Get Length           ${quickStartElements}
    ${TitleElements}=     Get WebElements      //div[@class="pf-c-card__title odh-card__doc-title"]
    FOR    ${counter}    IN RANGE     ${quickStartCount}
        Log To Console    \n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        ${Title}=   Get Text          ${TitleElements[${counter}]}
        ${Title}=   Split To Lines    ${Title}
        Log To Console                ${Title[${0}]}
        Click Element                 ${quickStartElements[${counter}]}
        Wait Until Element Is Visible  //button[@class='pf-c-wizard__nav-link']
        External URLs Should Not Be Broken
    END

Get QuickStart Items
        Wait Until Resource Page Is Loaded
        ${quickStartElements}=     Wait for QuickStart to Load
        [Return]    ${quickStartElements}


Open QuickStart Step
    [Documentation]   Click next if next not found cick tab to find buttion
    [Arguments]  ${quick_start_step}
    ${status}   Run Keyword And Return Status   Click Element  ${quick_start_step}
    IF  ${status} == False
        Click Button    Next
    END

    FOR    ${counter}    IN RANGE    5
        Press Keys    NONE    TAB
    END


Validate Links Extracted From Text
    [Arguments]    ${doc_links}
    @{valiadte_urls}  Create List
    @{invalidLinks}   Create List
    Append To List  ${invalidLinks}   http://s2i-python-service.my-project.svc.cluster.local:8080.  http://example.apps.organization.abc3.p4.openshiftapps.com/predictions  https://my-project-s2i-python-service-openapi-3scale-api.cluster.com/?user_key=USER_KEY     https://user-dev-rhoam-quarkus-openapi-3scale-api.cluster.com/?user_key=<API_KEY_GOES_HERE>     https://user-dev-rhoam-quarkus-openapi-3scale-api.cluster.com/status/?user_key=.

    FOR    ${doc_link}    IN    @{doc_links}
        Log To Console   ${doc_link}
        ${status}=   Run Keyword And Return Status    List Should Contain Value    ${invalidLinks}    ${doc_link}
        IF  ${status}
            Log To Console  Skipped invalid link   ${doc_link}
        ELSE
            IF  "${doc_link[${-1}]}" != '.'
                ${status}=  Check HTTP Status Code  ${doc_link}
                Log To Console  ${doc_link}
            ELSE IF  "${doc_link[${-1}]}" == '.'
                ${status}=  Check HTTP Status Code   ${doc_link[:${-1}]}
                 Log To Console   ${doc_link[:${-1}]}
            END
        END
    END

