*** Settings ***
Documentation    Collection of keywords to interact with Data Science Projects
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
${SPAWNER_LINK}=        xpath=//*[text()="Launch Jupyter"]

*** Keywords ***
Open Data Science Projects Home Page
    [Documentation]    Verifies submenu Settings > "Data Science Projects" is visible
    Wait Until Page Contains    Data Science Projects
    Click Link      Data Science Projects
    Wait for RHODS Dashboard to Load    wait_for_cards=${FALSE}    expected_page=Data science projects
    Wait Until Page Contains    View your existing projects or create new projects.    timeout=30
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

Delete Data Science Project
    [Documentation]    Deletes a given DS project. It allows cancelling the operation
    ...                by setting the ${press_cancel} argument
    [Arguments]     ${project_title}    ${press_cancel}=${FALSE}
    ${is_open}=    Is Data Science Projects Page Open
    IF    ${is_open} == ${FALSE}
        Open Data Science Projects Home Page
    END
    Project Should Be Listed    project_title=${project_title}
    Workbenches.Click Action From Actions Menu    item_title=${project_title}    item_type=project   action=Delete
    Handle Deletion Confirmation Modal    item_title=${project_title}    item_type=project
    ...                                   press_cancel=${press_cancel}
    ...   additional_msg=It will destroy all workbenches, storages, data connections and other resources in ${project_title}
    Wait Until Data Science Project Is Deleted    project_title=${project_title}

Wait Until Data Science Project Is Deleted
    [Documentation]    Checks if when a DS Project is deleted its Openshift namespace gets deleted too
    [Arguments]    ${project_title}
    Wait Until Keyword Succeeds    15 times    2s
    ...    Project Should Not Exist In Openshift    project_title=${project_title}

Project Should Not Exist In Openshift
    [Documentation]    Checks a given Project is not present in openshift
    [Arguments]    ${project_title}
    ${k8s_name} =     Get Openshift Namespace From Data Science Project   project_title=${project_title}
    IF    "${k8s_name}" != "${EMPTY}"
        Fail   msg=The project ${project_title} exists!
    END

Wait Until Project Is Open
    [Documentation]    Waits until a DS Project Details page is laoded
    [Arguments]     ${project_title}    ${timeout-pre-spinner}=3s    ${timeout-spinner}=5s
    Wait Until Page Contains Element    xpath=//h1[contains(text(),"${project_title}")]    timeout=30
    Maybe Wait For Dashboard Loading Spinner Page
    ...    timeout-pre=${timeout-pre-spinner}    timeout=${timeout-spinner}

Project Should Be Listed
    [Documentation]    Checks a Project is available in DS Project home page
    [Arguments]     ${project_title}
    Run Keyword And Continue On Failure     Page Should Contain Element    xpath=//td/div/a[text()="${project_title}"]

Wait Until Project Is Listed
    [Documentation]    Waits until the DS projects appears in the list in DS project Home Page
    [Arguments]     ${project_title}    ${timeout}=30s
    Wait Until Page Contains Element    xpath=//td/div/a[text()="${project_title}"]
    ...    timeout=${timeout}

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
    Wait Until Page Contains Element    ${PROJECT_CREATE_BTN_XP}
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
    ${open}=    Run Keyword And Return Status    Wait Until Project Is Open    project_title=${title}
    IF    ${open} == ${FALSE}
        ${is_home_open}=    Is Data Science Projects Page Open
        IF    ${is_home_open} == ${TRUE}
            Log    message=After DS Project ${title} creation, user did not get redirected to details page...(RHODS-8477)
            ...    level=WARN
            Fail
        END
    END

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
    ${rc}   ${k8s_name}=     Run And Return Rc And Output     oc get projects -o json | jq '.items[] | select((.metadata.annotations."openshift.io/display-name" != null) and (.metadata.labels."opendatahub.io/dashboard"=="true") and (.metadata.annotations."openshift.io/display-name"=="${project_title}")) | .metadata.name'    # robocop: disable
    ${k8s_name}=    Replace String    ${k8s_name}    "    ${EMPTY}
    [Return]    ${k8s_name}

Delete Data Science Projects From CLI
    [Documentation]     Deletes the Openshift Projects using OpenshiftLibrary.
    ...                 It expects to receive a list of project (i.e,${ocp_projects}) as argument
    [Arguments]     ${ocp_projects}
    FOR   ${displayed_name}    IN  @{ocp_projects}
        ${project_k8s_name}=     Run     oc get projects -o json | jq '.items[] | select((.metadata.annotations."openshift.io/display-name" != null) and (.metadata.labels."opendatahub.io/dashboard"=="true") and (.metadata.annotations."openshift.io/display-name"=="${displayed_name}")) | .metadata.name'    # robocop: disable
        ${project_k8s_name}=    Replace String    ${project_k8s_name}    "    ${EMPTY}
        IF    "${project_k8s_name}" == "${EMPTY}"
            Log    msg=There is probably no DS Projects with Diplay Name equal to ${displayed_name}
            Continue For Loop
        ELSE
            Oc Delete    kind=Project   name=${project_k8s_name}
            WHILE    ${TRUE}
                ${exists} =    Run And Return Rc    oc get project ${project_k8s_name}
                IF    "${exists}" == "1"    BREAK
                Sleep    5s    reason=let's not overload the API
            END
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

Launch And Access Workbench From Projects Home Page
    [Documentation]    Launches a running workbench from DS Projects home page.
    [Arguments]     ${workbench_title}    ${project_title}    ${username}=${TEST_USER_3.USERNAME}
    ...             ${password}=${TEST_USER_3.PASSWORD}    ${auth_type}=${TEST_USER_3.AUTH_TYPE}
    ${is_started}=      Run Keyword And Return Status   Workbench Status Should Be From Projects Home Page
    ...    workbench_title=${workbench_title}   status=${WORKBENCH_STATUS_RUNNING}    project_title=${project_title}
    IF    ${is_started} == ${TRUE}
        Click Element       xpath=//tr[td/div/a[text()="${project_title}"]]/td//a[text()="${workbench_title}"]
        Switch Window   NEW
        Access To Workbench    username=${username}    password=${password}
        ...    auth_type=${auth_type}
    ELSE
        Fail   msg=Cannot Launch And Access Workbench ${workbench_title} because it is not running...
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

Go To Next Page Of Data Science Projects
    [Documentation]    Navigate to next page when more than 10 Data Science Projects Appear
    Click Button    xpath=//button[@data-action="next"]

Launch Data Science Project Main Page
    [Documentation]    Launch DS Projects page in RHODS Dashboard using a given user
    [Arguments]     ${username}=${TEST_USER_3.USERNAME}     ${password}=${TEST_USER_3.PASSWORD}
    ...             ${ocp_user_auth_type}=${TEST_USER_3.AUTH_TYPE}    ${browser_alias}=${NONE}
    Launch Dashboard    ocp_user_name=${username}  ocp_user_pw=${password}  ocp_user_auth_type=${ocp_user_auth_type}
    ...                 dashboard_url=${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    ...                 browser_alias=${browser_alias}
    Open Data Science Projects Home Page

Remove Current Page Projects From All Projects
    [Documentation]    Remove list of currently displayed Data Science projects from list of all projects
    [Arguments]        ${all_projects}    ${curr_page_projects}
    FOR    ${project}    IN    @{curr_page_projects}
        Remove Values From List    ${all_projects}    ${project}
    END
    RETURN    ${all_projects}

Check Pagination Is Correct On The Current Page
    [Documentation]    Check the pagination is correct for the Data Science displayed on current page
    [Arguments]     ${page}    ${total}
    ${actual_text}=    Get Text    xpath://span[@class="pf-c-options-menu__toggle-text"]
    IF    ${page}==1
        ${expected_text}=    Set Variable   1 - 10 of ${total}
    ELSE IF    ${page}==2
        ${expected_text}=    Set Variable   11 - ${total} of ${total}
    END
    Should Be Equal    ${expected_text}    ${actual_text}

Check Resource Name Should Be Immutable
    [Documentation]    Checks if the Resource Name is not editable
    [Arguments]     ${project_title}
    Workbenches.Click Action From Actions Menu    item_title=${project_title}    item_type=project   action=Edit
    Wait Until Page Contains Element    ${RESOURCE_INPUT_XP}
    Element Should Be Disabled    ${RESOURCE_INPUT_XP}
    Click Button    Cancel

Update Data Science Project Name
    [Documentation]    Updates the existing DSG project name and verifies changes are done
    [Arguments]     ${project_title}    ${new_title}
    Workbenches.Click Action From Actions Menu    item_title=${project_title}    item_type=project   action=Edit
    Wait Until Page Contains Element    ${DESCR_INPUT_XP}
    Input Text    ${TITLE_INPUT_XP}    ${new_title}
    Click Button    Update
    Wait Until Generic Modal Disappears
    Wait Until Page Contains    ${new_title}

Update Data Science Project Description
    [Documentation]    Updates the existing DSG project description
    [Arguments]    ${project_title}    ${new_description}
    Workbenches.Click Action From Actions Menu    item_title=${project_title}    item_type=project   action=Edit
    Wait Until Page Contains Element    ${DESCR_INPUT_XP}
    Input Text    ${DESCR_INPUT_XP}    ${new_description}
    Click Button    Update
    Wait Until Generic Modal Disappears

Permissions Tab Should Be Accessible
    [Documentation]    Verify user can access the "Permissions" tab of a DS project
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element
    ...    xpath://span[text()="Permissions"]
    Move To Tab    tab_title=Permissions
    Wait Until Permissions Tab Is Open

Permissions Tab Should Not Be Accessible
    [Documentation]    Verify user cannot access the "Permissions" tab of a DS project
    ${status}=    Run Keyword And Return Status    Permissions Tab Should Be Accessible
    IF    ${status} == ${TRUE}
        Capture Page Screenshot
        Fail    msg=user should not have rights to access Permissions tab on the current DS Project
    END

Wait Until Permissions Tab Is Open
    [Documentation]    Wait until "Permissions" tab is rendered
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element    id:user-permission-User

Wait Until Components Tab Is Open
    [Documentation]    Wait until "Components" tab is rendered
    Run Keyword And Continue On Failure
    ...    Wait Until Page Contains Element    id:workbenches-title

Components Tab Should Be Accessible
    [Documentation]    Verify user can access the "Permissions" tab of a DS project
    Run Keyword And Continue On Failure
    ...    Page Should Contain Element
    ...    xpath://span[text()="Components"]
    Move To Tab    tab_title=Components
    Wait Until Components Tab Is Open

Move To Tab
    [Documentation]    Open one of the tabs in a DS Project details page (e.g., Permissions)
    [Arguments]    ${tab_title}
    Click Element    xpath://span[text()="${tab_title}"]
