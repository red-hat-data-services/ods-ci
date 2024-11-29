*** Settings ***
Documentation       Suite to test Workload metrics feature
Library             SeleniumLibrary
Library             OpenShiftLibrary
Resource            ../../Resources/Page/DistributedWorkloads/WorkloadMetricsUI.resource
Resource            ../../Resources/Page/ODH/ODHDashboard/ODHDataScienceProject/Projects.resource
Resource            ../../Resources/Page/DistributedWorkloads/DistributedWorkloads.resource
Suite Setup         Project Suite Setup
Suite Teardown      Project Suite Teardown
Test Tags           DistributedWorkloadMetrics


*** Variables ***
${PRJ_TITLE}=    test-dw-ui
${PRJ_TITLE_NONADMIN}=    test-dw-nonadmin
${PRJ_DESCRIPTION}=    project used for distributed workload metric
${project_created}=    False
${RESOURCE_FLAVOR_NAME}=    test-resource-flavor
${CLUSTER_QUEUE_NAME}=    test-cluster-queue
${LOCAL_QUEUE_NAME}=    test-local-queue
${CPU_REQUESTED}=    1
${MEMORY_REQUESTED}=    1500
${JOB_NAME_QUEUE}=    kueue-job
${RAY_CLUSTER_NAME}=    mnist


*** Test Cases ***
Verify Workload Metrics Home page Contents
    [Documentation]    Verifies "Workload Metrics" page is accessible from
    ...                the navigation menu on the left and page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads    Training    WorkloadsOrchestration
    Open Distributed Workload Metrics Home Page
    Wait Until Element Is Visible    ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}   timeout=20
    Wait Until Element Is Visible    ${PROJECT_METRICS_TAB_XP}   timeout=20
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TITLE_XP}
    Page Should Contain Element     ${DISTRIBUITED_WORKLOAD_METRICS_TEXT_XP}
    Page Should Contain Element     ${PROJECT_XP}
    Page Should Contain Element     ${PROJECT_METRICS_TAB_XP}
    Page Should Contain Element     ${WORKLOAD_STATUS_TAB_XP}
    Click Element    ${REFRESH_INTERNAL_MENU_XP}
    ${get_refresh_interval_list}=    Get All Text Under Element   xpath=//button[@role="option"]
    Lists Should Be Equal    ${REFRESH_INTERNAL_LIST}    ${get_refresh_interval_list}

Verify Project Metrics Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads    Training    WorkloadsOrchestration
    [Documentation]    Verifiy Project Metrics default Page contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Check Project Metrics Default Page Contents    ${PRJ_TITLE}

Verify Distributed Workload status Default Page contents
    [Tags]    RHOAIENG-4837
    ...       Sanity    DistributedWorkloads    Training    WorkloadsOrchestration
    [Documentation]    Verifiy distributed workload status page default contents
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Wait Until Element Is Visible    xpath=//div[text()="Distributed workload resource metrics"]   timeout=20
    Check Distributed Workload Status Page Contents

Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-4837
    ...       Tier1    DistributedWorkloads    Training    WorkloadsOrchestration
    Launch Dashboard    ocp_user_name=${TEST_USER_3.USERNAME}    ocp_user_pw=${TEST_USER_3.PASSWORD}
    ...    ocp_user_auth_type=${TEST_USER_3.AUTH_TYPE}    dashboard_url=${ODH_DASHBOARD_URL}
    ...    browser=${BROWSER.NAME}    browser_options=${BROWSER.OPTIONS}
    Open Data Science Projects Home Page
    Create Data Science Project    title=${PRJ_TITLE_NONADMIN}   description=${PRJ_DESCRIPTION}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE_NONADMIN}
    Wait Until Element Is Visible    xpath=//h4[text()="Configure the project queue"]   timeout=20
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
    ...    Delete Project Via CLI By Display Name   ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE_NONADMIN}
    ...    AND
    ...    Switch Browser    1

Verify The Workload Metrics By Submitting Kueue Batch Workload
    [Documentation]    Monitor the workload metrics status and chart details by submitting kueue batch workload
    [Tags]    RHOAIENG-5216
    ...       Tier1    DistributedWorkloads    Training    WorkloadsOrchestration
    Open Distributed Workload Metrics Home Page
    # Submitting kueue batch workload
    Submit Kueue Workload    ${LOCAL_QUEUE_NAME}    ${PRJ_TITLE}    ${CPU_REQUESTED}    ${MEMORY_REQUESTED}    ${JOB_NAME_QUEUE}
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Select Refresh Interval    15 seconds
    Wait Until Element Is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Wait For Job With Status    ${JOB_NAME_QUEUE}    Running    60

    ${cpu_requested} =   Get CPU Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}
    ${memory_requested} =   Get Memory Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}    Job
    Check Requested Resources Chart    ${PRJ_TITLE}    ${cpu_requested}    ${memory_requested}
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    ${cpu_requested}    ${memory_requested}    Job


    Check Distributed Workload Resource Metrics Status    ${JOB_NAME_QUEUE}    Running
    Check Distributed Worklaod Status Overview    ${JOB_NAME_QUEUE}    Running    All pods were ready or succeeded since the workload admission

    Click Button    ${PROJECT_METRICS_TAB_XP}

    Check Distributed Workload Resource Metrics Chart    ${PRJ_TITLE}    ${cpu_requested}    ${memory_requested}    Job    ${JOB_NAME_QUEUE}
    Wait For Job With Status    ${JOB_NAME_QUEUE}    Succeeded    180
    Select Refresh Interval    15 seconds
    Page Should Not Contain Element    xpath=//*[text()="Running"]
    Page Should Contain Element    xpath=//*[text()="Succeeded"]
    Select Refresh Interval    15 seconds
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    0    0    Job
    Check Distributed Workload Resource Metrics Status    ${JOB_NAME_QUEUE}    Succeeded
    # Once fixed  https://issues.redhat.com/browse/RHOAIENG-9092 update Job success message
    Check Distributed Worklaod Status Overview    ${JOB_NAME_QUEUE}    Succeeded    No message

    ${result} =    Run Process  oc delete Job ${JOB_NAME_QUEUE} -n ${PRJ_TITLE}
    ...    shell=true    stderr=STDOUT
    Log To Console    ${result.stdout}
    IF    ${result.rc} != 0
        FAIL   Failed to delete job ${JOB_NAME_QUEUE}
    END

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Wait Until Element Is Visible    xpath=//*[@data-testid="dw-workload-resource-metrics"]//*[text()="No distributed workloads in the selected project are currently consuming resources."]    timeout=60
    Page Should Not Contain    ${JOB_NAME_QUEUE}
    Page Should Not Contain    Succeeded
    Check Distributed Workload Status Page Contents
    [Teardown]    Run Process     oc delete Job ${JOB_NAME_QUEUE} -n ${PRJ_TITLE}    shell=true

Verify The Workload Metrics By Submitting Ray Workload
    [Documentation]    Monitor the workload metrics status and chart details by submitting Ray workload
    [Tags]    RHOAIENG-5216
    ...       Tier1    DistributedWorkloads    Training    WorkloadsOrchestration
    Create Ray Cluster Workload   ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}    ${RAY_CLUSTER_NAME}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Select Refresh Interval    15 seconds
    Wait Until Element Is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Wait For Job With Status    ${RAY_CLUSTER_NAME}    Admitted    30
    Wait For Job With Status    ${RAY_CLUSTER_NAME}    Running    180

    ${cpu_requested} =   Get CPU Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}
    ${memory_requested} =   Get Memory Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}   RayCluster
    Check Requested Resources Chart    ${PRJ_TITLE}    ${cpu_requested}    ${memory_requested}
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    ${cpu_requested}    ${memory_requested}    RayCluster

    Check Distributed Workload Resource Metrics Status    ${RAY_CLUSTER_NAME}    Running
    Check Distributed Worklaod Status Overview    ${RAY_CLUSTER_NAME}    Running    All pods were ready or succeeded since the workload admission

    Click Button    ${PROJECT_METRICS_TAB_XP}
    Check Distributed Workload Resource Metrics Chart    ${PRJ_TITLE}    ${cpu_requested}    ${memory_requested}    RayCluster    ${RAY_CLUSTER_NAME}

    [Teardown]    Cleanup Ray Cluster Workload    ${PRJ_TITLE}    ${RAY_CLUSTER_NAME}

Verify Requested resources When Multiple Local Queue Exists
    [Documentation]    Verify That Not Admin Users Can Access Distributed workload metrics default page contents
    [Tags]    RHOAIENG-8559
    ...       Tier1    DistributedWorkloads    Training    WorkloadsOrchestration
    Submit Kueue Workload    ${LOCAL_QUEUE_NAME}    ${PRJ_TITLE}    ${CPU_REQUESTED}    ${MEMORY_REQUESTED}    ${JOB_NAME_QUEUE}
    ${MULTIPLE_LOCAL_QUEUE}    Set Variable    test-multiple-local-queue
    ${MULTIPLE_JOB_NAME}    Set Variable    multiple-lq-job
    # setup Kueue resource for the created project
    Setup Kueue Resources    ${PRJ_TITLE}    ${CLUSTER_QUEUE_NAME}    ${RESOURCE_FLAVOR_NAME}    ${MULTIPLE_LOCAL_QUEUE}
    # Submitting kueue batch workload
    Submit Kueue Workload    ${MULTIPLE_LOCAL_QUEUE}    ${PRJ_TITLE}    0   ${MEMORY_REQUESTED}    ${MULTIPLE_JOB_NAME}
    Open Distributed Workload Metrics Home Page
    Select Distributed Workload Project By Name    ${PRJ_TITLE}
    Select Refresh Interval    15 seconds
    Wait Until Element Is Visible    ${DISTRIBUITED_WORKLOAD_RESOURCE_METRICS_TITLE_XP}    timeout=20
    Wait For Job With Status    ${JOB_NAME_QUEUE}    Running    60
    Wait For Job With Status   ${MULTIPLE_JOB_NAME}    Running    60

    # verify Requested by all projects requested resources
    ${cpu_requested_1} =   Get CPU Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}
    ${cpu_requested_2} =   Get CPU Requested    ${PRJ_TITLE}    ${MULTIPLE_LOCAL_QUEUE}
    ${cpu_requested} =    Evaluate    ${cpu_requested_1} + ${cpu_requested_2}
    ${memory_requested_1} =   Get Memory Requested    ${PRJ_TITLE}    ${LOCAL_QUEUE_NAME}    Job
    ${memory_requested_2} =   Get Memory Requested    ${PRJ_TITLE}    ${MULTIPLE_LOCAL_QUEUE}    Job
    ${memory_requested} =    Evaluate    ${memory_requested_1} + ${memory_requested_2}
    Check Requested Resources    ${PRJ_TITLE}    ${CPU_SHARED_QUOTA}    ${MEMEORY_SHARED_QUOTA}    ${cpu_requested}    ${memory_requested}    Job

    Wait Until Element Is Visible    xpath=//*[@id="topResourceConsumingCPU-ChartLabel-title"]    timeout=180
    Wait Until Element Is Visible    xpath=//*[@id="topResourceConsumingCPU-ChartLegend-ChartLabel-0"]   timeout=180
    ${cpu_usage} =    Get Current CPU Usage    ${PRJ_TITLE}    Job
    ${cpu_consuming} =    Get Text    xpath:(//*[@style[contains(., 'var(--pf-v5-chart-donut--label--title--Fill')]])[1]
    Check Resource Consuming Usage    ${cpu_usage}    ${cpu_consuming}    CPU

    Wait Until Element Is Visible    xpath=//*[@id="topResourceConsumingMemory-ChartLabel-title"]    timeout=180
    Wait Until Element Is Visible    xpath=//*[@id="topResourceConsumingMemory-ChartLegend-ChartLabel-0"]    timeout=180
    ${memory_usage} =    Get Current Memory Usage    ${PRJ_TITLE}    Job
    ${memory_consuming} =    Get Text    xpath:(//*[@style[contains(., 'var(--pf-v5-chart-donut--label--title--Fill')]])[2]
    Check Resource Consuming Usage    ${memory_usage}    ${memory_consuming}    Memory

    Wait For Job With Status    ${JOB_NAME_QUEUE}    Succeeded    180
    Wait For Job With Status   ${MULTIPLE_JOB_NAME}    Succeeded    180

    [Teardown]    Run Process    oc delete LocalQueue ${MULTIPLE_LOCAL_QUEUE} -n ${PRJ_TITLE}
    ...    shell=true

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
    ...    Delete Project Via CLI By Display Name   ${PRJ_TITLE}    AND
    ...    Wait Until Data Science Project Is Deleted  ${PRJ_TITLE}
    SeleniumLibrary.Close All Browsers
    RHOSi Teardown
