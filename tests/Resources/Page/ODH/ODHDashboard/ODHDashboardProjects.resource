*** Settings ***
Resource      ../../../Page/Components/Components.resource
Resource       ../../../Common.robot


*** Variables ***
${DS_PROJECT_XP}=   //h1[text()="Data science projects"]
${TITLE_INPUT_XP}=  xpath=//input[@aria-label="Project name"]
${DESCR_INPUT_XP}=  xpath=//textarea[@aria-label="Project description"]
${CREATE_BTN_XP}=  xpath=//button[text()="Create"]
${ACTIONS_BTN_XP}=  xpath=//div/button[@aria-label="Actions"]
${DELETE_ACTION_BTN_XP}=  xpath=//div/ul/li/button[text()="Delete project"]
${EDIT_ACTION_BTN_XP}=  xpath=//div/ul/li/button[text()="Edit project"]


*** Keywords ***
Open Data Science Projects Page
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    Page Should Contain    Data Science Projects
    Click Link      Data Science Projects
    Wait Until Page Contains    View your existing projects or create new projects.    timeout=30
    Wait Until Page Contains Element    ${DS_PROJECT_XP}    timeout=30
    Wait Until Page Contains Element    xpath=//span[@class="pf-c-spinner__tail-ball"]    timeout=10
    Wait Until Page Does Not Contain Element    xpath=//span[@class="pf-c-spinner__tail-ball"]    timeout=10

Is Data Science Projects Page Open
    Close Generic Modal If Present
    ${page_open}=   Run Keyword And Return Status   Page Should Contain     ${DS_PROJECT_XP}
    [Return]    ${page_open}

Open Data Science Project
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    [Arguments]     ${project_title}
    Click Link    ${project_title}

Delete Data Science Project
    [Arguments]     ${project_title}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Page
    END
    Project Should Be Listed    project_title=${project_title}
    Open Actions Menu Of Project    project_title=${project_title}
    Click Delete From Action Menu   project_title=${project_title}

Open Actions Menu Of Project
    [Arguments]     ${project_title}
    Project Should Be Listed    project_title=${project_title}
    Click Element    ${ACTIONS_BTN_XP}

Click Delete From Action Menu
    [Arguments]     ${project_title}
    Wait Until Page Contains Element    ${DELETE_ACTION_BTN_XP}
    Click Element    ${DELETE_ACTION_BTN_XP}

Wait Until Project Is Open
    [Arguments]     ${project_title}
    Wait Until Page Contains Element    xpath=//h1[text()=${project_title}]    timeout=30

Project Should Be Listed
    [Arguments]     ${project_title}
    Page Should Contain Element    xpath=//td/a[text()=${project_title}]

Project's Owner Should Be
    [Arguments]     ${project_title}    ${expected_username}
    Page Should Contain Element    xpath=//td[a[text()=${project_title}]]/small[text()=${expected_username}]

Create Data Science Project
    [Arguments]    ${title}    ${description}
    Click Button    Create data science project
    Wait Until Page Contains Element    ${TITLE_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${CREATE_BTN_XP}
    Input Text    ${TITLE_INPUT_XP}    ${title}
    Input Text    ${DESCR_INPUT_XP}    ${description}
    Wait Until Element Is Enabled    ${CREATE_BTN_XP}
    Click Button    ${CREATE_BTN_XP}
    Wait Until Modal Disappear


