*** Settings ***
Documentation    Collection of keywords to interact with Distributed Workloads Metrics UI
Resource         ../../Common.robot


*** Variables ***
${PROJECT_XP}=    xpath=//div[text()='Project']
${DISTRIBUITED_WORKLOAD_METRICS_TITLE_XP}=    xpath=//h1[text()="Distributed Workload Metrics"]
${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}=    xpath=//div[text()='Monitor the metrics of your active resources.']
${PROJECT_METRICS_TAB_XP}=    xpath=//button[@aria-label="Project metrics tab"]
${WORKLOAD_STATUS_TAB_XP}=    xpath=//button[@aria-label="Distributed workload status tab"]
${STATUS_OVERVIEW_XP}=    xpath=//div[text()='Status overview']
${REFRESH_INTERVAL_XP}=    xpath=//div[text()='Refresh interval']
${WORKLOADS_STATUS_XP}=    xpath=//div[text()='Distributed Workloads']
${REFRESH_INTERNAL_MENU_XP}=    xpath=//button[@aria-label="Options menu"]
@{STATUS_LIST}=    Pending    Inadmissible    Admitted    Running    Evicted    Succeeded    Failed
@{REFRESH_INTERNAL_LIST}=    15 seconds    30 seconds    1 minute    5 minutes    15 minutes    30 minutes    1 hour    2 hours    1 day
${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}=    xpath=//div[text()="Distributed workload resource metrics"]
${REQUESTED_RESOURCES_TITLE_XP}=    xpath=//div[text()="Requested resources"]
${RESOURCES_CONSUMING_TITLE_XP}=    xpath=//div[text()="Top resource-consuming distributed workloads"]


*** Keywords ***
Open Distributed Workload Metrics Home Page
    [Documentation]    This will launch to the distributed Workloads Home page
    Wait Until Page Contains    Distributed Workload Metrics    timeout=30
    Click Link    Distributed Workload Metrics
    Wait For RHODS Dashboard To Load    wait_for_cards=${FALSE}    expected_page=Distributed Workload Metrics

Select Distributed Workload Project By Name
    [Documentation]    Select the project in distributed workload metrics page by project name
    [Arguments]    ${project_name}
    Wait until Element is Visible    ${PROJECT_XP}   timeout=20
    Click Element    xpath://div[@data-testid="project-selector-dropdown"]
    Click Element    xpath://a[@role="menuitem" and text()="${project_name}"]

Check Expected String Contains
    [Documentation]    Check Expected String Contains with the xpath prvoided get text
    [Arguments]    ${GET_TEXT_XP}    ${expected_output}
    ${output} =  Get Text  xpath=${GET_TEXT_XP}
    Should Contain   ${output}    ${expected_output}

Check Expected String Equals
    [Documentation]    Check Expected String Equals with the xpath prvoided get text
    [Arguments]    ${GET_TEXT_XP}    ${expected_output}
    ${output} =  Get Text  xpath=${GET_TEXT_XP}
    Should Match   ${output}    ${expected_output}
