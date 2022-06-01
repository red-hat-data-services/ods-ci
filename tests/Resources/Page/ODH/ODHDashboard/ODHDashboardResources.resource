*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource       ../../../Common.robot


*** Keywords ***
Open QuickStart Element in Resource Section By Name
    [Documentation]     It opens the element by enabling Quick Start filter in Resources Section of ODS Dashboard.
    [Arguments]     ${element}
    Select Checkbox     //input[@id="quickstart--check-box"]
    Wait Until Page Contains Element    //article[@id="${element}"]
    Click Link          //article[@id="${element}"]//a
    Wait Until Page Contains ELement    //div[@class="pf-c-drawer__panel-main"]     5

Star QuickStart Tour
    Click Button    //button[@data-test="Start button"]
    Wait Until Page Contains Element    //div[@class="pfext-quick-start-content"]

Get The Count Of QuickStart Steps
    [Documentation]     Gives the count of steps in a the quick start
    ${count}=   Get ELement Count   //div[@class="pfext-quick-start-content"]/ul/li
    [Return]    ${count}

Link Text On QuickStart Card Should Be
    [Arguments]     ${element}  ${exp_link_text}
    Element Text Should Be  //article[@id="${element}"]//a      ${exp_link_text}

QuickStart Status Should Be
    [Documentation]     Verifies the label on the item card which shows the progress and closes the sidebar.
    [Arguments]     ${element}  ${progress_string}
    IF  '${progress_string}'=='In Progress'
        Element Text Should Be      //article[@id="${element}"]//span[@class="pf-c-label pf-m-purple pf-m-outline"]     In Progress
    ELSE IF     '${progress_string}'=='Complete'
        Element Text Should Be      //article[@id="${element}"]//span[@class="pf-c-label pf-m-green pf-m-outline"]      Complete
    ELSE IF     '${progress_string}'=='Failed'
        Element Text Should Be      //article[@id="${element}"]//span[@class="pf-c-label pf-m-red pf-m-outline"]        Failed
    END

QuickStart Status Should Not Be Set
    [Arguments]     ${element}
    Page Should Not Contain   xpath=//article[@id="${element}"]//span[@class="pf-c-label pf-m-purple pf-m-outline"]
    Page Should Not Contain   xpath=//article[@id="${element}"]//span[@class="pf-c-label pf-m-green pf-m-outline"]
    Page Should Not Contain   xpath=//article[@id="${element}"]//span[@class="pf-c-label pf-m-red pf-m-outline"]

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

Page Should Contain QuickStart Sidebar
    Wait Until Page Contains Element    //div[@class="pf-c-drawer__panel-main"]     5

Close QuickStart From Button
    Click Button    //button[@data-testid="qs-drawer-close"]

Mark Step Check As Yes
    Wait Until Page Contains Element    //input[@data-testid="qs-drawer-check-yes"]
    Click Button    //input[@data-testid="qs-drawer-check-yes"]

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
