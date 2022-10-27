*** Settings ***
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       ./Workspaces.resource

*** Variables ***
${DS_PROJECT_XP}=     //h1[text()="Data science projects"]
${TITLE_INPUT_XP}=    xpath=//input[@id="test"]
${DESCR_INPUT_XP}=    xpath=//textarea[@id="test"]
# ${TITLE_INPUT_XP}=    xpath=//input[@aria-label="Project name"]
# ${DESCR_INPUT_XP}=    xpath=//textarea[@aria-label="Project description"]
${GENERIC_CREATE_BTN_XP}=     xpath=//button[text()="Create"]
${GENERIC_CANCEL_BTN_XP}=     xpath=//button[text()="Cancel"]
${PROJECT_CREATE_BTN_XP}=     xpath=//button[text()="Create data science project"]
${ACTIONS_BTN_XP}=    xpath=//div/button[@aria-label="Actions"]
${DELETE_ACTION_BTN_XP}=  xpath=//div/ul/li/button[text()="Delete project"]
${EDIT_ACTION_BTN_XP}=    xpath=//div/ul/li/button[text()="Edit project"]


*** Keywords ***
Open Data Science Projects Home Page
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    Page Should Contain    Data Science Projects
    Click Link      Data Science Projects
    Wait Until Page Contains    View your existing projects or create new projects.    timeout=30
    Wait Until Page Contains Element    ${DS_PROJECT_XP}    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Is Data Science Projects Page Open
    Close Generic Modal If Present
    ${page_open}=   Run Keyword And Return Status   Page Should Contain     ${DS_PROJECT_XP}
    [Return]    ${page_open}

Open Data Science Project Details Page
    [Documentation]    Verifies submenu Settings > Cluster settings" is visible
    [Arguments]     ${project_title}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    Click Link    ${project_title}
    Wait Until Project Is Open    project_title=${project_title}
    Maybe Wait For Dashboard Loading Spinner Page

Delete Data Science Project
    [Arguments]     ${project_title}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    Project Should Be Listed    project_title=${project_title}
    Open Actions Menu Of Project    project_title=${project_title}
    Click Delete From Action Menu   project_title=${project_title}
    ${ns_name}=    Get Openshift Namespace From Data Science Project   project_title=${project_title}
    ${present}=     Run Keyword And Return Status   OpenshiftLibrary.Oc Get    kind=Project  name=${ns_name}
    IF    ${present} == ${TRUE}
        Fail   msg=The namespace for ${project_title} project was not deleted using UI actions..
    END

Open Actions Menu Of Project
    [Arguments]     ${project_title}
    Project Should Be Listed    project_title=${project_title}
    Click Element    ${ACTIONS_BTN_XP}

Click Delete From Action Menu
    [Arguments]     ${project_title}
    Wait Until Page Contains Element    ${DELETE_ACTION_BTN_XP}
    Click Element    ${DELETE_ACTION_BTN_XP}
    Click Button       Delete

Wait Until Project Is Open
    [Arguments]     ${project_title}
    Wait Until Page Contains Element    xpath=//h1[contains(text(),"${project_title}")]    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Project Should Be Listed
    [Arguments]     ${project_title}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td/a[text()="${project_title}"]

Project's Owner Should Be
    [Arguments]     ${project_title}    ${expected_username}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//td[a[text()="${project_title}"]]/small[text()="${expected_username}"]

Create Data Science Project
    [Arguments]    ${title}    ${description}
    Click Button    ${PROJECT_CREATE_BTN_XP}
    # Click Button    Create data science project
    Wait Until Page Contains Element    ${TITLE_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${TITLE_INPUT_XP}    ${title}
    Input Text    ${DESCR_INPUT_XP}    ${description}
    Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
    Click Button    ${GENERIC_CREATE_BTN_XP}
    Wait Until Modal Disappears
    Wait Until Project Is Open    project_title=${title}


Get Openshift Namespace From Data Science Project
    [Arguments]     ${project_title}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    ${project_link}=    Get Element Attribute    xpath=//td/a[text()="${project_title}"]    href
    ${ns_name}=     Split String From Right     separator=/     max_split=1     string=${project_link}
    [Return]    ${ns_name[1]}

Delete Data Science Projects From CLI
    [Documentation]     Deletets the Openshift Projects using OpenshiftLibrary
    [Arguments]     ${ocp_projects}
    FOR   ${project}    IN  @{ocp_projects}
        ${present}=     Run Keyword And Return Status   OpenshiftLibrary.Oc Get    kind=Project  name=${project}
        IF    ${present} == ${FALSE}
            Continue For Loop
        ELSE
            OpenshiftLibrary.Oc Delete    kind=Project   name=${project}
        END
    END

Delete All Data Science Projects From CLI
    [Documentation]    Deletes all the Openshift Projects which have been created
    ...                via DataScienceProjects feature, using OpenshiftLibrary
    ${res}  ${projects}=     Run Keyword And Ignore Error     Oc Get    kind=Project  label_selector=opendatahub.io/user=htpasswd-2dcluster-2dadmin-2duser
    IF    "${res}" == "FAIL"
        Log    msg=There are probably no DS Projects to delete in teardown.
    ELSE
        @{to_delete}=   Create List
        FOR    ${project}    IN    @{projects}
            Log    ${project['metadata']['name']}
            Append To List    ${to_delete}     ${project['metadata']['name']}
        END
        Delete Data Science Projects From CLI   ocp_projects=${to_delete}
    END

Workspace Status Should Be From Projects Home Page
    [Arguments]     ${workbench_title}      ${status}    ${project_title}
    ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${_}  ${workbench_cr_name}=       Get Openshift Notebook CR From Workspace    workbench_title=${workbench_title}    namespace=${namespace}
    Run keyword And Continue On Failure     Page Should Contain Element    xpath=//tr[td/a[text()="${project_title}"]]/td//label[@for="${workbench_cr_name}"]/span[text()="${status}"]

Start Workspace From Projects Home Page
    [Documentation]    Trigger the workbench "start" process from DS Projects home page.
    ...                It needs ${workbench_title} and ${project_title} at least. If ${namespace} and/or
    ...                ${workbench_cr_name} are given too, the kw spares one or two calls to openshift API server
    [Arguments]     ${workbench_title}    ${project_title}   ${namespace}=${EMPTY}    ${workbench_cr_name}=${EMPTY}
    ${is_stopped}=      Run Keyword And Return Status   Workspace Status Should Be From Projects Home Page      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}    project_title=${project_title}
    IF    ${is_stopped} == ${TRUE}
        IF    "${workbench_cr_name}" == "${EMPTY}"
            IF    "${namespace}" == "${EMPTY}"
                ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
            END
                ${_}    ${workbench_cr_name}=       Get Openshift Notebook CR From Workspace    workbench_title=${workbench_title}    namespace=${namespace}
        END
        Click Element       xpath=//tr[td/a[text()="${project_title}"]]/td//label[@for="${workbench_cr_name}"]/span[@class="pf-c-switch__toggle"]
    ELSE
        Fail     msg=Cannot start ${workbench_title} workbench because it is not stopped.
    END
    Wait Until Workspace Is Started From Projects Home Page     workbench_title=${workbench_title}   project_title=${project_title}

Stop Workspace From Projects Home Page
    [Documentation]    Trigger the workbench "stop" process from DS Projects home page.
    ...                It needs ${workbench_title} and ${project_title} at least. If ${namespace} and/or
    ...                ${workbench_cr_name} are given too, the kw spares one or two calls to openshift API server
    [Arguments]     ${workbench_title}    ${project_title}   ${namespace}=${EMPTY}    ${workbench_cr_name}=${EMPTY}
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be From Projects Home Page      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}    project_title=${project_title}
    IF    ${is_started} == ${TRUE}
        IF    "${workbench_cr_name}" == "${EMPTY}"
            IF    "${namespace}" == "${EMPTY}"
                ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
            END
                ${_}    ${workbench_cr_name}=       Get Openshift Notebook CR From Workspace    workbench_title=${workbench_title}    namespace=${namespace}
        END
        Click Element       xpath=//tr[td/a[text()="${project_title}"]]/td//label[@for="${workbench_cr_name}"]/span[@class="pf-c-switch__toggle"]
    ELSE
        Fail     msg=Cannot stop ${workbench_title} workbench because it is not running.
    END
    Wait Until Workspace Is Stopped From Projects Home Page     workbench_title=${workbench_title}   project_title=${project_title}

Wait Until Workspace Is Started From Projects Home Page
    [Arguments]     ${workbench_title}   ${project_title}   ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workspace Status Should Be From Projects Home Page      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}   project_title=${project_title}

Wait Until Workspace Is Stopped From Projects Home Page
    [Arguments]     ${workbench_title}   ${project_title}   ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workspace Status Should Be From Projects Home Page      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}   project_title=${project_title}

Launch Workspace From Projects Home Page
    [Arguments]     ${workbench_title}    ${project_title}
    # Open Data Science Projects Home Page
    ${is_started}=      Run Keyword And Return Status   Workspace Status Should Be From Projects Home Page      workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}    project_title=${project_title}
    IF    ${is_started} == ${TRUE}
        Click Element       xpath=//tr[td/a[text()="${project_title}"]]/td//a[text()="${workbench_title}"]
        Access To Workspace
    ELSE
        Fail   msg=Cannot launch workbench ${workbench_title} because it is not running...
    END

Workbench Launch Link Should Be Disabled
    [Arguments]     ${workbench_title}    ${project_title}
    Element Should Be Disabled       xpath=//tr[td/a[text()="${project_title}"]]/td//a[text()="${workbench_title}"]
