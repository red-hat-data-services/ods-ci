*** Settings ***
Documentation       Suite to test Workload metrics feature
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Suite Setup         Project Suite Setup
Suite Teardown      Project Suite Teardown
Test Tags           DistributedWorkloadMetrics


*** Variables ***
${PRJ_TITLE}=    test-dw-ui
${PRJ_TITLE_NONADMIN}=    test-dw-nonadmin
${PRJ_DESCRIPTION}=    project used for distributed workload metrics
${KUEUE_RESOURCES_SETUP_FILEPATH}=    ods_ci/tests/Resources/Page/DistributedWorkloads/kueue_resources_setup.sh
${CPU_SHARED_QUOTA}=    20
${MEMEORY_SHARED_QUOTA}=    36
${project_created}=    False
${RESOURCE_FLAVOR_NAME}=    test-resource-flavor
${CLUSTER_QUEUE_NAME}=    test-cluster-queue
${LOCAL_QUEUE_NAME}=    test-local-queue


*** Test Cases ***
Verify Workload Metrics Home page Contents
    [Documentation]    Verifies "Workload Metrics" page is accessible from
    ...                the navigation menu on the left and page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    Open Distributed Workload Metrics Home Page
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}   timeout=20
    Wait until Element is Visible    ${PROJECT_METRICS_TAB_XP}   timeout=20
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TITLE_XP}
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}
    Page Should Contain Element     ${PROJECT_XP}
    Page Should Contain Element     ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element     ${WORKLOAD_STATUS_TAB_XP}
    Click Element    ${REFRESH_INTERNAL_MENU_XP}
    ${get_refresh_interval_list}=    Get All Text Under Element   xpath=//*[starts-with(@id, "select-option-")]
    Lists Should Be Equal    ${REFRESH_INTERNAL_LIST}    ${get_refresh_interval_list}

Verify Project Metrics Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    [Documentation]    Verifiy Project Metrics default Page contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Check Project Metrics Default Page Contents    ${PRJ_TITLE}

Verify Distributed Workload status Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads
    [Documentation]    Verifiy distributed workload status page default contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Wait until Element is Visible    xpath=//div[text()="Distributed workload resource metrics"]   timeout=20
    Check Distributed Workload Status Page Contents

Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-4837
    ...       Tier1    DistributedWorkloads
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE_NONADMIN}   description=${PRJ_DESCRIPTION}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Wait until Element is Visible    xpath=//h4[text()="Configure the project queue"]   timeout=20
    Page Should Contain Element     xpath=//div[text()="Configure the queue for this project, or select a different project."]
    # setup Kueue resource for the created project
    Setup Kueue Resources    ${PRJ_TITLE_NONADMIN}    cluster-queue-user    resource-flavor-user    local-queue-user
    Click Link    Distributed Workload Metrics
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Check Project Metrics Default Page Contents    ${PRJ_TITLE_NONADMIN}
    Check Distributed Workload Status Page Contents
    [Teardown]    Run Keywords
    ...    Cleanup Kueue Resources    ${PRJ_TITLE_NONADMIN}    cluster-queue-user    resource-flavor-user    local-queue-user
    ...    AND
    ...    Delete Data Science Project   ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Switch Browser    1


*** Keywords ***
Project Suite Setup
    [Documentation]    Suite setup steps for testing Distributed workload Metrics UI
    Set Library Search Order    SeleniumLibrary
    RHOSi Setup
    Launch Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ...    ${ODH_DASHBOARD_URL}    ${BROWSER.NAME}    ${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE}    description=${PRJ_DESCRIPTION}
    Set Global Variable    ${project_created}    True
    # setup Kueue resource for the created project
    Setup Kueue Resources    ${PRJ_TITLE}    ${CLUSTER_QUEUE_NAME}    ${RESOURCE_FLAVOR_NAME}    ${LOCAL_QUEUE_NAME}

Project Suite Teardown
    [Documentation]    Suite teardown steps after testing Distributed Workload metrics .
    Cleanup Kueue Resources    ${PRJ_TITLE}    ${CLUSTER_QUEUE_NAME}    ${RESOURCE_FLAVOR_NAME}    ${LOCAL_QUEUE_NAME}
    IF  ${project_created} == True    Run Keywords
    ...    Delete Data Science Project   ${PRJ_TITLE}    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown

Check Project Metrics Default Page Contents
    [Documentation]    checks Project Metrics Default Page contents exists
    [Arguments]    ${project_name}
    Wait until Element is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Page Should Contain Element    ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${REQUESTED_RESOURCES_TITLE_XP}
    Check Requested Resources    ${project_name}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    0    0
    Page Should Contain Element    ${RESOURCES_CONSUMING_TITLE_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-top-consuming-workloads"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]
    Page Should Contain Element    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-workloada-resource-metrics"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]

Check Distributed Workload Status Page Contents
    [Documentation]    checks Distributed Workload status Default Page contents exists
    Click Button    ${WORKLOAD_STATUS_TAB_XP}
    Wait until Element is Visible  ${WORKLOADS_STATUS_XP}    timeout=20
    Page Should Contain Element    ${REFRESH_INTERVAL_XP}
    Page Should Contain Element    ${STATUS_OVERVIEW_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-status-overview-card"]//*[text()="Select another project or create a distributed workload in the selected project."]
    Page Should Contain Element    ${WORKLOADS_STATUS_XP}
    Page Should Contain Element    xpath=//*[@data-testid="dw-workloads-table-card"]//*[text()="Select another project or create a distributed workload in the selected project."]

Check Requested Resources
    [Documentation]    checks requested resource contents
    [Arguments]    ${project_name}   ${cpu_shared_quota}    ${memory_shared_quota}    ${cpu_requested}    ${memory_requested}
    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-0"]    Requested by ${project_name}: ${cpu_requested}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-2"]    Total shared quota: ${CPU_SHARED_QUOTA}

    Check Expected String Equals    //*[@id="requested-resources-chart-CPU-ChartLegend-ChartLabel-1"]    Requested by all projects: ${cpu_requested}

    Check Expected String Equals   //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-0"]    Requested by ${project_name}: ${memory_requested}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-1"]    Requested by all projects: ${memory_requested}

    Check Expected String Equals    //*[@id="requested-resources-chart-Memory-ChartLegend-ChartLabel-2"]   Total shared quota: ${memory_shared_quota}

Setup Kueue Resources
    [Documentation]    Setup the kueue resources for the project
    [Arguments]    ${project_name}    ${cluster_queue_name}    ${resource_flavor_name}    ${local_queue_name}
    ${result} =    Run Process    sh ${KUEUE_RESOURCES_SETUP_FILEPATH} ${cluster_queue_name} ${resource_flavor_name} ${local_queue_name} ${project_name} ${CPU_SHARED_QUOTA} ${MEMEORY_SHARED_QUOTA}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to setup kueue resources
    END

Cleanup Kueue Resources
    [Documentation]    Cleanup the kueue resources for the project
    [Arguments]    ${project_name}    ${cluster_queue_name}   ${resource_flavor}    ${local_queue_name}
    ${result}=    Run Process    oc delete LocalQueue ${local_queue_name} -n ${project_name} & oc delete ClusterQueue ${cluster_queue_name} & oc delete ResourceFlavor ${resource_flavor}
    ...    shell=true
    ...    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL    Failed to delete kueue resources
    END
