*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource       ../../../Common.robot


*** Variables ***
@{INVALID_LINKS}=   http://s2i-python-service.my-project.svc.cluster.local:8080.
...                 http://example.apps.organization.abc3.p4.openshiftapps.com/prediction
...                 https://my-project-s2i-python-service-openapi-3scale-api.cluster.com/?user_key=USER_KEY
...                 https://user-dev-rhoam-quarkus-openapi-3scale-api.cluster.com/?user_key=<API_KEY_GOES_HERE>
...                 https://user-dev-rhoam-quarkus-openapi-3scale-api.cluster.com/status/?user_key=.
...                 https://console-openshift-console.apps.test-cluster.example.com
...                 console-openshift-console.apps.test-cluster.example.com


*** Keywords ***
Open QuickStart Element in Resource Section By Name
    [Documentation]     It opens the element by enabling Quick Start filter in Resources Section of ODS Dashboard.
    [Arguments]     ${element}
    Select Checkbox     //input[@id="quickstart--check-box"]
    Wait Until Page Contains Element    ${RES_CARDS_XP}\[@id="${element}"]
    Click Link          ${RES_CARDS_XP}\[@id="${element}"]//a
    Wait Until Page Contains ELement    //div[@class="pf-c-drawer__panel-main"]     5

Star QuickStart Tour
    Click Button    //button[@data-test="Start button"]
    Wait Until Page Contains Element    //div[@class="pfext-quick-start-content"]

Get The Count Of QuickStart Steps
    [Documentation]     Gives the count of steps in a the quick start
    ${count}=   Get ELement Count   //div[@class="pfext-quick-start-content"]/ul/li
    RETURN    ${count}

Link Text On QuickStart Card Should Be
    [Arguments]     ${element}  ${exp_link_text}
    Element Text Should Be  ${RES_CARDS_XP}\[@id="${element}"]//a      ${exp_link_text}

QuickStart Status Should Be
    [Documentation]     Verifies the label on the item card which shows the progress and closes the sidebar.
    [Arguments]     ${element}  ${progress_string}
    IF  '${progress_string}'=='In Progress'
        Element Text Should Be      ${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-purple pf-m-outline"]
        ...    In Progress
    ELSE IF     '${progress_string}'=='Complete'
        Element Text Should Be      ${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-green pf-m-outline"]
        ...    Complete
    ELSE IF     '${progress_string}'=='Failed'
        Element Text Should Be      ${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-red pf-m-outline"]
        ...    Failed
    END

QuickStart Status Should Not Be Set
    [Arguments]     ${element}
    Page Should Not Contain
    ...    xpath=${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-purple pf-m-outline"]
    Page Should Not Contain
    ...    xpath=${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-green pf-m-outline"]
    Page Should Not Contain
    ...    xpath=${RES_CARDS_XP}\[@id="${element}"]//span[@class="pf-c-label pf-m-red pf-m-outline"]

Close QuickStart From Top
    [Arguments]     ${decision}=leave
    Wait Until Page Contains ELement    //div[@class="pf-c-drawer__panel-main"]     5
    Page Should Contain Element     //div[@data-testid="qs-drawer-close"]/button
    Click Button        //div[@data-testid="qs-drawer-close"]/button
    IF    $decision == "leave"
        Click Button    xpath=//button[@data-test="leave button"]
    ELSE IF     $decision == "cancel"
        Click Button    xpath=//button[@data-test="cancel button"]
    END

Page Should Not Contain QuickStart Sidebar
    Wait Until Page Does Not Contain ELement    //div[@class="pf-c-drawer__panel-main"]     5

Close QuickStart From Button
    Click Button    //button[@data-testid="qs-drawer-close"]

Mark Step Check As Yes
    Wait Until Page Contains Element    //input[@data-testid="qs-drawer-check-yes"]
    Click Button    //input[@data-testid="qs-drawer-check-yes"]
    Wait Until Page Contains Element    //div[contains(@class, "pf-m-success")]


Mark Step Check As No
    Wait Until Page Contains Element    //input[@data-testid="qs-drawer-check-no"]
    Click Button    //input[@data-testid="qs-drawer-check-no"]

Go To Next QuickStart Step
    Click Button    //button[@data-testid="qs-drawer-next"]

Continue QuickStart
    Click Button    //button[@data-testid="qs-drawer-continue"]

Go Back And Check Previouse Step Is Selected
    [Arguments]     ${n_steps}   ${exp_step}
    Click Button    //button[@data-testid="qs-drawer-back"]
    Current Step In QuickStart Should Be    n_steps=${n_steps}  exp_step=${exp_step}

Current Step In QuickStart Should Be
    [Arguments]     ${n_steps}  ${exp_step}
    ${current_step_text}=    Get Text    xpath=//span[@data-test-id="quick-start-task-subtitle"]
    Should Be Equal     ${current_step_text}    ${exp_step} of ${n_steps}
    # IF  ${n_steps} == 1
    #     Element Text Should Be      //span[@class="pfext-quick-start-task-header__subtitle"]    1 of 1
    # ELSE
    #     Element Text Should Be      //span[@class="pfext-quick-start-task-header__subtitle"]    ${n_steps-1} of ${n_steps}
    # END

Wait for QuickStart to Load
    [Documentation]   Waiting for quick start to visbible
    Wait Until Element Is Visible       xpath=//a[contains(@class,'odh-card__footer__link') and contains(@href,'#')]
    Select Checkbox                         xpath=//*[@id="quickstart--check-box"]
    ${quickStartElements}=   Get WebElements    xpath=//a[contains(@class,'odh-card__footer__link') and contains(@href,'#')]
    RETURN    ${quickStartElements}

Wait Until Resource Page Is Loaded
    Wait Until Page Contains Element    xpath://div[contains(@class,'odh-learning-paths__gallery')]

Get Link Web Elements From Resource Page
    [Documentation]    Returns the link web elements from Resources page which redirects users to
    ...                external websites. It excludes Quick Starts items
    ${link_elements}=    Get WebElements    //a[@class="odh-card__footer__link" and not(starts-with(@href, '#'))]
    ${len}=    Get Length    ${link_elements}
    Log To Console    ${len} Links found\n
    RETURN    ${link_elements}

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
            Run Keyword And Continue On Failure
            ...    URLs HTTP Status Code Should Be Equal To    ${element_list}
            ${doc_text}=     Get Text  //*[@class="pf-c-drawer__body pf-m-no-padding pfext-quick-start-panel-content__body"]    # robocop: disable
            ${doc_link}=    Extract URLs From Text    text=${doc_text}
            Validate Links Extracted From Text     ${doc_link}
    END

Verify Links Are Not Broken For Each QuickStart
    [Documentation]     Clicks on al the quick start and verify links
    [Arguments]    ${quickStartElements}
    ${quickStartCount}=   Get Length           ${quickStartElements}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.21.0
    IF  ${version_check}==True
        ${versioned_title_xp}=    Set Variable    //div[@class="pf-c-content"]
    ELSE
        ${versioned_title_xp}=    Set Variable    //div[@class="pf-c-card__title odh-card__doc-title"]
    END
    ${TitleElements}=     Get WebElements      ${versioned_title_xp}
    FOR    ${counter}    IN RANGE     ${quickStartCount}
        Log    \n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    console=yes
        ${Title}=   Get Text          ${TitleElements[${counter}]}
        ${Title}=   Split To Lines    ${Title}
        Log                ${Title[${0}]}    console=yes
        Click Element                 ${quickStartElements[${counter}]}
        Wait Until Element Is Visible  //button[@class='pf-c-wizard__nav-link']
        External URLs Should Not Be Broken
    END

Get QuickStart Items
    [Documentation]    Fetches and returns the web elements of RHODS Quick Starts
    Wait For RHODS Dashboard To Load    expected_page=Resources
    ${quickStartElements}=     Wait For QuickStart To Load
    RETURN    ${quickStartElements}

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
    [Documentation]    Checks the health status of the links which have been
    ...                extracted from the quick start texts.
    ...                It skips validation of textual links which are supposed to be
    ...                mere examples, hence invalid links. e.g.,
    ...                http://example.apps.organization.abc3.p4.openshiftapps.com/prediction
    [Arguments]    ${doc_links}
    FOR    ${doc_link}    IN    @{doc_links}
        Log   ${doc_link}
        ${status}=   Run Keyword And Return Status    List Should Contain Value    ${INVALID_LINKS}    ${doc_link}
        IF  ${status}
            Log  Skipped invalid link ${doc_link}
        ELSE
            IF  "${doc_link[${-1}]}" == '.'
                 ${doc_link}=    Set Variable    ${doc_link[:${-1}]}
            END
            ${status}=  Run Keyword And Continue On Failure
            ...    Check HTTP Status Code  ${doc_link}
        END
    END
