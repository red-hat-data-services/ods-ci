*** Settings ***
Resource          ../../Resources/RHOSi.resource
Resource          ../../Resources/ODS.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.robot
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboard.resource
Resource          ../../Resources/Page/ODH/ODHDashboard/ODHDashboardResources.resource
Resource          ../../Resources/Page/LoginPage.robot
Suite Setup       RHOSi Setup
Suite Teardown    RHOSi Teardown
Test Setup        Resources Test Setup
Test Teardown     Resources Test Teardown
Test Tags         Dashboard


*** Variables ***
@{LIST_OF_IDS_FOR_COMBINATIONS}         documentation--check-box    Red Hat managed--check-box
${SUCCESS_STEP}              h3[normalize-space(@class="pf-v5-c-title pf-m-md pfext-quick-start-task-header__title
...                           pfext-quick-start-task-header__title-success")]


*** Test Cases ***
Verify Quick Starts Work As Expected On Yes And Restart
    [Documentation]   Verify the Quickstarts are completed successfully
    ...    when all steps are marked as yes and restarted later
    ...    ProductBug: RHOAIENG-5273
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1306    ODS-1308    ODS-1166    ODS-1406    ODS-1405
    Set Quick Starts Elements List Based On RHODS Type
    Validate Number Of Quick Starts In Dashboard Is As Expected    ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When All Steps Are Marked As Yes   ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When Restarted And Left In Between    ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When Restarting The Previous One    ${QUICKSTART_ELEMENTS}

Verify Quick Starts Work When All Steps Are Skipped
    [Documentation]   Verify the Quickstarts work fine when all
    ...    steps are skipped
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1402
    Set Quick Starts Elements List Based On RHODS Type
    Validate Number Of Quick Starts In Dashboard Is As Expected    ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When All Steps Are Skipped    ${QUICKSTART_ELEMENTS}

Verify Quick Starts Work When At Least One Step Is Skipped
    [Documentation]   Verify the Quickstarts work fine when at least of the
    ...    steps are skipped
    ...    ProductBug: RHOAIENG-5273
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1403
    Set Quick Starts Elements List Based On RHODS Type
    Validate Number Of Quick Starts In Dashboard Is As Expected    ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When At Least One Step Is Skipped    ${QUICKSTART_ELEMENTS}

Verify Quick Starts Work As Expected When At Least One Step Is Marked As No
    [Documentation]   Verify the Quickstarts are works as expected
    ...    when mark last one step as no
    ...    ProductBug: RHOAIENG-5273
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1307
    Set Quick Starts Elements List Based On RHODS Type
    Validate Number Of Quick Starts In Dashboard Is As Expected    ${QUICKSTART_ELEMENTS}
    Verify Quick Starts Work As Expected When One Step Is Marked As No    ${QUICKSTART_ELEMENTS}

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
    [Tags]    Sanity    Tier1
    ...       ODS-531    ODS-507
    Click Link    Resources
    Sleep    5
    ${link_elements}=     Get Link Web Elements From Resource Page
    URLs HTTP Status Code Should Be Equal To     link_elements=${link_elements}    expected_status=200

Verify Filters Are Working On Resources Page
    [Documentation]    check if it is possible to filter items by enabling various filters like status,provider
    [Tags]    Sanity
    ...       ODS-489
    ...       Tier1
    Click Link    Resources
    Wait For RHODS Dashboard To Load    expected_page=Resources
    Set Expected Items Based On RHODS Type
    Number Of Items Should Be    expected_number=${EXPECTED_RESOURCE_ITEMS}
    Filter Resources By Status "Enabled" And Check Output
    Filter By Resource Type And Check Output
    Filter By Provider Type And Check Output
    Filter By Application (Aka Povider) And Check Output
    Filter By Using More Than One Filter And Check Output

Verify App Name On Resource Tile
    [Documentation]    Check that each resource tile specifies which application it refers to
    [Tags]    Sanity
    ...       ODS-395
    ...       Tier1
    Click Link    Resources
    Wait For RHODS Dashboard To Load    expected_page=Resources
    Validate App Name Is Present On Each Tile


*** Keywords ***
Resources Test Setup
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard    ${TEST_USER_2.USERNAME}    ${TEST_USER_2.PASSWORD}    ${TEST_USER_2.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Click Link      Resources
    Sleep   3

Resources Test Teardown
    Close All Browsers

Filter Resources By Status "Enabled" And Check Output
    [Documentation]    Filters the resources By Status Enabled
    ${id_name}=  Set Variable    enabled-filter-checkbox--check-box
    Run Keyword And Continue On Failure
    ...    Verify Resources Count By Checkbox ID    ${id_name}

Filter By Application (Aka Povider) And Check Output
    [Documentation]    Filter by application (aka provider)
    ${id_name}=  Set Variable    Anaconda Professional--check-box
    Run Keyword And Continue On Failure
    ...    Verify Resources Count By Checkbox ID    ${id_name}

Filter By Resource Type And Check Output
    [Documentation]    Filter by resource type
    ${id_name}=  Set Variable    tutorial--check-box
    Run Keyword And Continue On Failure
    ...    Verify Resources Count By Checkbox ID    ${id_name}

Filter By Provider Type And Check Output
    [Documentation]    Filter by provider type
    ${id_name}=  Set Variable    Red Hat managed--check-box
    Run Keyword And Continue On Failure
    ...    Verify Resources Count By Checkbox ID    ${id_name}

Filter By Using More Than One Filter And Check Output
    [Documentation]    Filter resouces using more than one filter ${list_of_ids} = list of check-box ids
    FOR    ${id}    IN    @{LIST_OF_IDS_FOR_COMBINATIONS}
        Select Checkbox Using Id    id=${id}
    END
    Verify The Resources Are Filtered
    ...    list_of_items=${EXPECTED_ITEMS_FOR_COMBINATIONS}
    FOR    ${id}    IN    @{LIST_OF_IDS_FOR_COMBINATIONS}
        Deselect Checkbox Using Id    id=${id}
    END

Set Expected Items Based On RHODS Type    # robocop: disable
    [Documentation]    Sets some required variables depending on if RHODS is
    ...                installed as Self-Managed or Cloud Service
    ${is_self_managed}=    Is RHODS Self-Managed
    ${n_items}=    Set Variable    49
    ${EXPECTED_ITEMS_FOR_ENABLE}=    Create List
    ...    Creating a Jupyter notebook
    ...    Deploying a sample Python application using Flask and OpenShift.
    ...    How to install Python packages on your notebook server
    ...    How to update notebook server settings
    ...    How to use data from Amazon S3 buckets
    ...    How to view installed packages on your notebook server
    ...    Jupyter
    ${EXPECTED_ITEM_PROVIDERS}=    Create List       by Anaconda Professional
    ${EXPECTED_ITEM_RESOURCE_TYPE}=    Create List     Tutorial
    ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}=     Evaluate    ${EXPECTED_ITEMS_FOR_ENABLE}.copy()
    Append To List    ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}
    ...    OpenShift AI tutorial - Fraud detection example
    ...    Red Hat OpenShift AI
    @{EXPECTED_ITEMS_FOR_COMBINATIONS}=      Create List
    ...    Jupyter
    ...    Red Hat OpenShift AI
    IF    ${is_self_managed} == ${TRUE}
        # Deprecated
        # Remove From List   ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}   -1
        # Remove From List   ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}   -1
        # Remove From List   ${EXPECTED_ITEMS_FOR_COMBINATIONS}   -1
        ${n_items}=    Set Variable    48
    END
    Set Suite Variable    ${EXPECTED_RESOURCE_ITEMS}    ${n_items}
    Set Suite Variable    ${EXPECTED_ITEMS_FOR_ENABLE}    ${EXPECTED_ITEMS_FOR_ENABLE}
    Set Suite Variable    ${EXPECTED_ITEM_PROVIDERS}    ${EXPECTED_ITEM_PROVIDERS}
    Set Suite Variable    ${EXPECTED_ITEM_RESOURCE_TYPE}    ${EXPECTED_ITEM_RESOURCE_TYPE}
    Set Suite Variable    ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}    ${EXPECTED_ITEMS_FOR_PROVIDER_TYPE}
    Set Suite Variable    ${EXPECTED_ITEMS_FOR_COMBINATIONS}    ${EXPECTED_ITEMS_FOR_COMBINATIONS}

Validate App Name Is Present On Each Tile
    [Documentation]    Check that each Resource tile contains
    ...    the name of the application
    ${elements}=    Get WebElements    //article[contains(@class, 'pf-v5-c-card')]//div[@class="pf-v5-c-content"]//small
    ${len}=    Get Length    ${elements}
    FOR    ${counter}    IN RANGE    ${len}
        ${name}=    Get Text    ${elements}[${counter}]
        Should Start With    ${name}    by
        ${appName}=    Remove String    ${name}    by
        ${length}=    Get Length    ${appName}
        Should Be True	${length} > 2
    END

Set Quick Starts Elements List Based On RHODS Type
    [Documentation]    Set QuickStarts list based on RHODS
    ...     is self-managed or managed
    ${is_self_managed}=    Is RHODS Self-Managed
    IF    ${is_self_managed} == ${TRUE}
            @{quickStartElements}=      Create List
            ...    create-jupyter-notebook    create-jupyter-notebook-anaconda
            ...    build-deploy-watson-model    deploy-python-model    pachyderm-beginner-tutorial-notebook
            ...    using-starburst-enterprise    create-aikit-notebook    openvino-inference-notebook
    ELSE
            @{quickStartElements}=      Create List
            ...    create-jupyter-notebook    create-jupyter-notebook-anaconda
            ...    deploy-python-model    create-aikit-notebook    deploy-model-rhoam    gpu-enabled-notebook-quickstart
            ...    pachyderm-beginner-tutorial-notebook    openvino-inference-notebook    using-starburst-galaxy
            ...    gpu-quickstart    build-deploy-watson-model
    END
    Set Suite Variable    ${QUICKSTART_ELEMENTS}    ${quickStartElements}

Validate Number Of Quick Starts In Dashboard Is As Expected
    [Arguments]    ${quickStartElements}
    ${expectedLen} =    Get Length    ${quickStartElements}
    ${actualQuickStarts} =    Get QuickStart Items
    ${actualLen} =    Get Length    ${actualQuickStarts}
    Run Keyword And Continue On Failure
    ...    Should Be True    ${expectedLen} == ${actualLen}    Quick Starts have been updated. Update the list accordingly.

Verify Quick Starts Work As Expected When Restarted And Left In Between
    [Arguments]    ${quickStartElements}
    FOR    ${element}    IN    @{quickStartElements}
        Run Keyword And Continue On Failure    QuickStart Status Should Be    ${element}  Complete
        Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}
        ...    exp_link_text=Restart
        Open QuickStart Element In Resource Section By Name     ${element}
        Page Should Not Contain         //article[@id="${element}"]//span[@class="pf-v5-c-label pf-m-green pf-m-outline"]
        ${count}=   Get The Count Of QuickStart Steps
        Run Keyword And Continue On Failure     Click Button    //button[@data-testid="qs-drawer-start"]
        Run Keyword And Continue On Failure     Wait Until Page Contains Element
        ...    //div[@class="pfext-quick-start-content"]
        ${temp_count}   Set Variable    2
        FOR     ${index}    IN RANGE    ${temp_count}
            IF  ${index} != ${count-1}
                Run Keyword And Continue On Failure     Wait Until Keyword Succeeds    2 times   0.3s
                ...    Mark Step Check As Yes
                Run Keyword And Continue On Failure     Go To Next QuickStart Step
            END
        END
        Run Keyword And Continue On Failure     Close QuickStart From Top     decision=leave
        Run Keyword And Continue On Failure     Page Should Not Contain QuickStart Sidebar
        Run Keyword And Continue On Failure     QuickStart Status Should Be    ${element}  In Progress
        Run Keyword And Continue On Failure     Link Text On QuickStart Card Should Be  element=${element}
        ...    exp_link_text=Continue
        Run Keyword And Continue On Failure     Click Link      //article[@id="${element}"]//a
        Run Keyword And Continue On Failure     Wait Until Page Contains ELement
        ...    //div[@class="pf-v5-c-drawer__panel-main"]     5
        FOR     ${index}    IN RANGE    ${temp_count}
            Run Keyword And Continue On Failure     Page Should Contain Element
            ...    //div[@class="pfext-quick-start-tasks__list"]//li[${index+1}]//${SUCCESS_STEP}
        END
        Run Keyword And Continue On Failure     Click Button    //button[@data-testid="qs-drawer-side-note-action"]
        FOR     ${index}    IN RANGE    ${count}
            Run Keyword And Continue On Failure     Page Should Contain Element
            ...    //ul[@class="pf-v5-c-list pfext-quick-start-task-header__list"]/li[${index}+1]
        END
        Click Button        //button[@data-testid="qs-drawer-restart"]
        FOR     ${index}    IN RANGE    ${count}
            Run Keyword And Continue On Failure     Wait Until Keyword Succeeds    2 times   0.3s
            ...    Mark Step Check As Yes
            Run Keyword And Continue On Failure     Go To Next QuickStart Step
        END
        Run Keyword And Continue On Failure     Go Back And Check Previouse Step Is Selected     n_steps=${count}
        ...    exp_step=${count-1}
        Go To Next QuickStart Step
        Go To Next QuickStart Step
        Run Keyword And Continue On Failure     Close QuickStart From Button
    END

