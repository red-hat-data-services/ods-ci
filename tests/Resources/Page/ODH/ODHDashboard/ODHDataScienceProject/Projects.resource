*** Settings ***
Documentation    Collection of keywords to interact with Data Science Projects
Resource       ../../../../Page/Components/Components.resource
Resource       ../../../../Common.robot
Resource       ./Workbenches.resource


*** Variables ***
${DS_PROJECT_XP}=     xpath=//h1[text()="Data science projects"]
${TITLE_INPUT_XP}=    xpath=//input[@id="manage-project-modal-name"]
${DESCR_INPUT_XP}=    xpath=//textarea[@id="manage-project-modal-description"]
${RESOURCE_INPUT_XP}=    xpath=//input[@id="resource-manage-project-modal-name"]
${GENERIC_CREATE_BTN_XP}=     xpath=//button[text()="Create"]
${GENERIC_CANCEL_BTN_XP}=     xpath=//button[text()="Cancel"]
${PROJECT_CREATE_BTN_XP}=     xpath=//button[text()="Create data science project"]
${ACTIONS_BTN_XP}=    xpath=//div/button[@aria-label="Actions"]
${DELETE_ACTION_BTN_XP}=  xpath=//div/ul/li/button[text()="Delete project"]
${EDIT_ACTION_BTN_XP}=    xpath=//div/ul/li/button[text()="Edit project"]
${SPAWNER_LINK}=        xpath=//a[text()="Launch Jupyter"]


*** Keywords ***
Open Data Science Projects Home Page
    [Documentation]    Verifies submenu Settings > "Data Science Projects" is visible
    Page Should Contain    Data Science Projects
    Click Link      Data Science Projects
    Wait Until Page Contains    View your existing projects or create new projects.    timeout=30
    Wait Until Page Contains Element    ${DS_PROJECT_XP}    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Is Data Science Projects Page Open
    [Documentation]    Checks if Data Science Projects home page is open. Returns TRUE or FALSE
    Close Generic Modal If Present
    ${page_open}=   Run Keyword And Return Status   Page Should Contain Element     ${DS_PROJECT_XP}
    [Return]    ${page_open}

Open Data Science Project Details Page
    [Documentation]    Verifies submenu Settings > "Data Science Projects" is visible
    [Arguments]     ${project_title}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    Click Link    ${project_title}
    Wait Until Project Is Open    project_title=${project_title}
    Maybe Wait For Dashboard Loading Spinner Page

Delete Data Science Project
    [Documentation]    Deletes a given DS project. It allows cancelling the operation
    ...                by setting the ${press_cancel} argument
    [Arguments]     ${project_title}    ${press_cancel}=${FALSE}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    Project Should Be Listed    project_title=${project_title}
    Click Action From Actions Menu    item_title=${project_title}    item_type=project   action=Delete
    Handle Deletion Confirmation Modal    item_title=${project_title}    item_type=project
    ...                                   press_cancel=${press_cancel}
    ...   additional_msg=It will destroy all workbenches, storages, data connections and other resources in ${project_title}

Wait Until Project Is Open
    [Documentation]    Waits until a DS Project Details page is laoded
    [Arguments]     ${project_title}
    Wait Until Page Contains Element    xpath=//h1[contains(text(),"${project_title}")]    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page

Project Should Be Listed
    [Documentation]    Checks a Project is available in DS Project home page
    [Arguments]     ${project_title}
    Run Keyword And Continue On Failure     Page Should Contain Element    xpath=//td/div/a[text()="${project_title}"]

Project Should Not Be Listed
    [Documentation]    Checks a Project is not available in DS Project home page
    [Arguments]     ${project_title}
    Run Keyword And Continue On Failure     Page Should Not Contain Element    xpath=//td/div/a[text()="${project_title}"]

Project's Owner Should Be
    [Documentation]    Checks if the owner of a DS project is displayed and corresponds to the expected one
    [Arguments]     ${project_title}    ${expected_username}
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element    xpath=//td[div/a[text()="${project_title}"]]/small[text()="${expected_username}"]

Create Data Science Project
    [Documentation]    Creates a DS Project with the given ${title}, ${description} and ${resource_name}
    [Arguments]    ${title}    ${description}    ${resource_name}=${NONE}
    Click Button    ${PROJECT_CREATE_BTN_XP}
    Wait Until Page Contains Element    ${TITLE_INPUT_XP}
    Run Keyword And Warn On Failure     Element Should Be Disabled    ${GENERIC_CREATE_BTN_XP}
    Input Text    ${TITLE_INPUT_XP}    ${title}
    Input Text    ${DESCR_INPUT_XP}    ${description}
    Run Keyword And Continue On Failure    Validate Generated Resource Name    project_title=${title}
    IF    "${resource_name}" != "${NONE}"
        Clear Element Text    ${RESOURCE_INPUT_XP}
        Input Text    ${RESOURCE_INPUT_XP}    ${resource_name}
    END
    Wait Until Element Is Enabled    ${GENERIC_CREATE_BTN_XP}
    Click Button    ${GENERIC_CREATE_BTN_XP}
    Wait Until Generic Modal Disappears
    Wait Until Project Is Open    project_title=${title}

Validate Generated Resource Name
    [Documentation]    Checks if the generated resource name matches the expected validation regex
    [Arguments]    ${project_title}
    ${generated_res_name}=    Get Element Attribute    ${RESOURCE_INPUT_XP}    value
    ${lower}=    Convert To Lower Case    ${project_title}
    ${no_spec_chars}=    Replace String Using Regexp    ${lower}    [^A-Za-z0-9-\\s]+    ${EMPTY}
    ${expected}=    Replace String Using Regexp    ${no_spec_chars}    ${SPACE}    -
    Should Be Equal As Strings    ${generated_res_name}    ${expected}

Get Openshift Namespace From Data Science Project
    [Documentation]    Gets the resource name of a DS Project starting from the Displayed Name
    [Arguments]     ${project_title}
    ${version_check}=  Is RHODS Version Greater Or Equal Than  1.20.0
    IF  ${version_check}==True
        ${rc}   ${k8s_name}=     Run And Return Rc And Output     oc get projects -o json | jq '.items[] | select((.metadata.annotations."openshift.io/display-name" != null) and (.metadata.labels."opendatahub.io/dashboard"=="true") and (.metadata.annotations."openshift.io/display-name"=="${project_title}")) | .metadata.name'    # robocop: disable
        ${k8s_name}=    Replace String    ${k8s_name}    "    ${EMPTY}
    ELSE
        ${is_open}=    Is Data Science Projects Page Open
        IF    ${is_open} == ${FALSE}
            Open Data Science Projects Home Page
        END
        ${project_link}=    Get Element Attribute    xpath=//td/div/a[text()="${project_title}"]    href
        ${ns_name}=     Split String From Right     separator=/     max_split=1     string=${project_link}
        ${k8s_name}=    Set Variable    ${ns_name[1]}
    END
    [Return]    ${k8s_name}

Delete Data Science Projects From CLI
    [Documentation]     Deletes the Openshift Projects using OpenshiftLibrary.
    ...                 It expects to receive a list of project (i.e,${ocp_projects}) as argument
    [Arguments]     ${ocp_projects}
    FOR   ${displayed_name}    IN  @{ocp_projects}
        ${version_check}=  Is RHODS Version Greater Or Equal Than  1.20.0
        IF  ${version_check}==True
            ${project_k8s_name}=     Run     oc get projects -o json | jq '.items[] | select((.metadata.annotations."openshift.io/display-name" != null) and (.metadata.labels."opendatahub.io/dashboard"=="true") and (.metadata.annotations."openshift.io/display-name"=="${displayed_name}")) | .metadata.name'    # robocop: disable
        ELSE
            ${dp_with_suffix}=    Set Variable    ${displayed_name}\[DSP]
            ${project_k8s_name}=     Run     oc get projects -o json | jq '.items[] | select((.metadata.annotations."openshift.io/display-name" != null) and (.metadata.annotations."openshift.io/display-name"=="${dp_with_suffix}")) | .metadata.name'    # robocop: disable
        END
        ${project_k8s_name}=    Replace String    ${project_k8s_name}    "    ${EMPTY}
        IF    "${project_k8s_name}" == "${EMPTY}"
            Log    msg=There is probably no DS Projects with Diplay Name equal to ${displayed_name}
            Continue For Loop
        ELSE
            Oc Delete    kind=Project   name=${project_k8s_name}
        END
    END

Workbench Status Should Be From Projects Home Page
    [Documentation]    Checks the workbench status is the expected one, from the DS Project home page
    [Arguments]     ${workbench_title}      ${status}    ${project_title}
    ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
    ${_}  ${workbench_cr_name}=       Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}
    ...                                                                           namespace=${namespace}
    Run Keyword And Continue On Failure     Page Should Contain Element    xpath=//tr[td/div/a[text()="${project_title}"]]/td[@data-label="Status"]//div[div/label[contains(@for,"${workbench_cr_name}")]]/div//p[text()="${status}"]

Start Workbench From Projects Home Page
    [Documentation]    Triggers the workbench "start" process from DS Projects home page.
    ...                It needs ${workbench_title} and ${project_title} at least. If ${namespace} and/or
    ...                ${workbench_cr_name} are given too, the kw spares one or two calls to openshift API server
    [Arguments]     ${workbench_title}    ${project_title}   ${namespace}=${EMPTY}    ${workbench_cr_name}=${EMPTY}
    ${is_stopped}=      Run Keyword And Return Status
    ...                    Workbench Status Should Be From Projects Home Page      workbench_title=${workbench_title}
    ...                                                                            status=${WORKBENCH_STATUS_STOPPED}
    ...                                                                            project_title=${project_title}
    IF    ${is_stopped} == ${TRUE}
        IF    "${workbench_cr_name}" == "${EMPTY}"
            IF    "${namespace}" == "${EMPTY}"
                ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
            END
                ${_}    ${workbench_cr_name}=
                ...           Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}
                ...                                                        namespace=${namespace}
        END
        Click Element       xpath=//tr[td/div/a[text()="${project_title}"]]/td/div//label[contains(@for,"${workbench_cr_name}")]/span[@class="pf-c-switch__toggle"]    # robocop: disable
    ELSE
        Fail     msg=Cannot start ${workbench_title} workbench because it is not stopped.
    END
    Wait Until Workbench Is Started From Projects Home Page     workbench_title=${workbench_title}
    ...                                                         project_title=${project_title}

Stop Workbench From Projects Home Page
    [Documentation]    Triggers the workbench "stop" process from DS Projects home page.
    ...                It needs ${workbench_title} and ${project_title} at least. If ${namespace} and/or
    ...                ${workbench_cr_name} are given too, the kw spares one or two calls to openshift API server
    [Arguments]     ${workbench_title}    ${project_title}   ${namespace}=${EMPTY}
    ...             ${workbench_cr_name}=${EMPTY}    ${press_cancel}=${FALSE}
    ${is_started}=      Run Keyword And Return Status
    ...                        Workbench Status Should Be From Projects Home Page      workbench_title=${workbench_title}
    ...                                                                                status=${WORKBENCH_STATUS_RUNNING}
    ...                                                                                project_title=${project_title}
    IF    ${is_started} == ${TRUE}
        IF    "${workbench_cr_name}" == "${EMPTY}"
            IF    "${namespace}" == "${EMPTY}"
                ${namespace}=        Get Openshift Namespace From Data Science Project    project_title=${project_title}
            END
                ${_}    ${workbench_cr_name}=       Get Openshift Notebook CR From Workbench    workbench_title=${workbench_title}    namespace=${namespace}
        END
        Click Element       xpath=//tr[td/div/a[text()="${project_title}"]]/td/div//label[contains(@for,"${workbench_cr_name}")]/span[@class="pf-c-switch__toggle"]    # robocop: disable
        Handle Stop Workbench Confirmation Modal    press_cancel=${press_cancel}
    ELSE
        Fail     msg=Cannot stop ${workbench_title} workbench because it is not running.
    END
    Wait Until Workbench Is Stopped From Projects Home Page     workbench_title=${workbench_title}
    ...                                                         project_title=${project_title}

Wait Until Workbench Is Started From Projects Home Page
    [Documentation]    Waits until the workbench status is "RUNNING", from the DS Project home page
    [Arguments]     ${workbench_title}   ${project_title}   ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workbench Status Should Be From Projects Home Page
    ...     workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}   project_title=${project_title}

Wait Until Workbench Is Stopped From Projects Home Page
    [Documentation]    Waits until the workbench status is "STOPPED", from the DS Project home page
    [Arguments]     ${workbench_title}   ${project_title}   ${timeout}=30s
    Wait Until Keyword Succeeds    ${timeout}    5s      Workbench Status Should Be From Projects Home Page
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_STOPPED}   project_title=${project_title}

Launch Workbench From Projects Home Page
    [Documentation]    Launches a running workbench from DS Projects home page.
    [Arguments]     ${workbench_title}    ${project_title}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be From Projects Home Page
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}    project_title=${project_title}
    IF    ${is_started} == ${TRUE}
        Click Element       xpath=//tr[td/div/a[text()="${project_title}"]]/td//a[text()="${workbench_title}"]
        Access To Workbench
    ELSE
        Fail   msg=Cannot launch workbench ${workbench_title} because it is not running...
    END

Workbench Launch Link Should Be Disabled
    [Documentation]    Checks the workbench launch link is disabled from DS Projects home page.
    [Arguments]     ${workbench_title}    ${project_title}
    ${link_status}=    Get Element Attribute
    ...    xpath=//tr[td/div/a[text()="${project_title}"]]/td//a[text()="${workbench_title}"]    aria-disabled
    Should Be Equal As Strings    ${link_status}    true
    ...    msg=Workbench launch link should be disabled for workbench ${workbench_title} in project ${project_title}

Get All Displayed Projects
    [Documentation]    Gets all the DS projects visible in the DS Projects home page
    ${projects_names}=    Create List
    ${elements}=    Get WebElements    xpath=//td[@data-label="Name"]/div/a
    FOR    ${element}    IN    @{elements}
        ${name}=    Get Text    ${element}
        Append To List    ${projects_names}    ${name}
    END
    [Return]   ${projects_names}

Number Of Displayed Projects Should Be
    [Documentation]    Checks the number the DS projects visible in the DS Projects home page is expected
    [Arguments]    ${expected_number}
    ${listed}=    Get All Displayed Projects
    ${n_listed}=    Get Length    ${listed}
    Run Keyword And Continue On Failure    Should Be Equal As Integers    ${n_listed}    ${expected_number}
