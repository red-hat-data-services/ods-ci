*** Settings ***
Resource       ../../../Page/Components/Components.resource
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
    [Arguments]     ${project_displayed_name}
    Click Link    ${project_displayed_name}

Delete Data Science Project
    [Arguments]     ${project_displayed_name}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Page
    END
    Project Should Be Listed    project_displayed_name=${project_displayed_name}
    Open Actions Menu Of Project    project_displayed_name=${project_displayed_name}
    Click Delete From Action Menu   project_displayed_name=${project_displayed_name}
    # check NS deleted

Open Actions Menu Of Project
    [Arguments]     ${project_displayed_name}
    Project Should Be Listed    project_displayed_name=${project_displayed_name}
    Click Element    ${ACTIONS_BTN_XP}

Click Delete From Action Menu
    [Arguments]     ${project_displayed_name}
    Wait Until Page Contains Element    ${DELETE_ACTION_BTN_XP}
    Click Element    ${DELETE_ACTION_BTN_XP}
    # Add confirmation click

Wait Until Project Is Open
    [Arguments]     ${project_displayed_name}
    Wait Until Page Contains Element    xpath=//h1[contains(text(),"${project_displayed_name}")]    timeout=30

Project Should Be Listed
    [Arguments]     ${project_displayed_name}
    Page Should Contain Element    xpath=//td/a[text()="${project_displayed_name}"]

Project's Owner Should Be
    [Arguments]     ${project_displayed_name}    ${expected_username}
    Page Should Contain Element    xpath=//td[a[text()="${project_displayed_name}"]]
    Page Should Contain Element    xpath=//td[a[text()="${project_displayed_name}"]]/small[text()="${expected_username}"]

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

Get Openshift Namespace From Data Science Project
    [Arguments]     ${project_displayed_name}
    ${project_link}=    Get Element Attribute    xpath=//td/a[text()="${project_displayed_name}"]    href
    ${ns_name}=     Split String From Right     separator=/     max_split=1     string=${project_link}
    [Return]    ${ns_name[1]}

