*** Settings ***
Documentation       Post install test cases that mainly verify OCP resources and objects
Library             String
Library             OperatingSystem
Library             OpenShiftLibrary
Library             ../../../../libs/Helpers.py
Resource            ../../../Resources/RHOSi.resource
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../Resources/Page/ODH/Prometheus/Prometheus.robot
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/Grafana/Grafana.resource
Resource            ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource            ../../../Resources/Common.robot
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Test Cases ***
Verify Dashbord has no message with NO Component Found
    [Tags]  Tier3
    ...     ODS-1493
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with bad subscription present in openshift
    [Setup]   Test Setup For Rhods Dashboard
    Oc Apply  kind=Subscription  src=tests/Tests/100__deploy/100__installation/bad_subscription.yaml
    Delete Dashboard Pods And Wait Them To Be Back
    Reload Page
    Menu.Navigate To Page    Applications    Explore
    Sleep    10s
    Page Should Not Contain    No Components Found
    Capture Page Screenshot
    [Teardown]  Close All Browsers

Verify Traefik Deployment
    [Documentation]  Verifies RHODS Traefik deployment
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-546
    ...       ODS-552
    Skip      msg=Traefik proxy is removed after KFNBC migration

Verify Notebook Controller Deployment
    [Documentation]    Verifies RHODS Notebook Controller deployment
    [Tags]    Sanity
    ...       ODS-546  ODS-294  ODS-1250  ODS-237
    @{NBC} =  Oc Get    kind=Pod  namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=notebook-controller
    @{ONBC} =  Oc Get    kind=Pod  namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=odh-notebook-controller
    ${containerNames} =  Create List  manager
    Verify Deployment  ${NBC}  1  1  ${containerNames}
    Verify Deployment  ${ONBC}  1  1  ${containerNames}

Verify GPU Operator Deployment  # robocop: disable
    [Documentation]  Verifies Nvidia GPU Operator is correctly installed
    [Tags]  Sanity
    ...     Resources-GPU  # Not actually needed, but we first need to enable operator install by default
    ...     ODS-1157

    # Before GPU Node is added to the cluster
    # NS
    Verify Namespace Status  label=kubernetes.io/metadata.name=nvidia-gpu-operator
    # GPU Operator
    Verify Operator Status  label=operators.coreos.com/gpu-operator-certified.nvidia-gpu-operator
    ...    operator_name=gpu-operator-certified.v*

    # After GPU Node is added to the cluster
    Verify DaemonSet Status  label=app=gpu-feature-discovery  dsname=gpu-feature-discovery
    Verify DaemonSet Status  label=app=nvidia-container-toolkit-daemonset  dsname=nvidia-container-toolkit-daemonset
    Verify DaemonSet Status  label=app=nvidia-dcgm-exporter  dsname=nvidia-dcgm-exporter
    Verify DaemonSet Status  label=app=nvidia-dcgm  dsname=nvidia-dcgm
    Verify DaemonSet Status  label=app=nvidia-device-plugin-daemonset  dsname=nvidia-device-plugin-daemonset
    # app=nvidia-driver-daemonset-410.84.202205191234-0
    # Verify DaemonSet Status  label=app=nvidia-driver-daemonset-*  dsname=nvidia-driver-daemonset-*
    Verify DaemonSet Status  label=app=nvidia-node-status-exporter  dsname=nvidia-node-status-exporter
    Verify DaemonSet Status  label=app=nvidia-operator-validator  dsname=nvidia-operator-validator

Verify That Prometheus Image Is A CPaaS Built Image
    [Documentation]    Verifies the images used for prometheus
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-734
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=prometheus-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    prometheus
    ...    registry.redhat.io/openshift4/ose-prometheus
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    oauth-proxy
    ...    registry.redhat.io/openshift4/ose-oauth-proxy

Verify That Grafana Image Is A CPaaS Built Image
    [Documentation]    Verifies the images used for grafana
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-736
    Skip If RHODS Version Greater Or Equal Than    version=1.20.0
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=grafana-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    grafana
    ...    registry.redhat.io/rhel8/grafana
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    auth-proxy
    ...    registry.redhat.io/openshift4/ose-oauth-proxy

Verify That Blackbox-exporter Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for blackbox-exporter
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-735
    Skip If RHODS Is Self-Managed
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=blackbox-exporter-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    blackbox-exporter
    ...    quay.io/integreatly/prometheus-blackbox-exporter

Verify That Alert Manager Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for alertmanager
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-733
    Skip If RHODS Is Self-Managed
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=prometheus-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    alertmanager
    ...    registry.redhat.io/openshift4/ose-prometheus-alertmanager

Verify Oath-Proxy Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for oauth-proxy
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-666
    ${pod} =    Find First Pod By Name  namespace=${APPLICATIONS_NAMESPACE}   pod_start_with=rhods-dashboard-
    Container Image Url Should Contain      ${APPLICATIONS_NAMESPACE}     ${pod}      oauth-proxy
    ...     registry.redhat.io/openshift4/ose-oauth-proxy

Verify That CUDA Build Chain Succeeds
    [Documentation]    Check Cuda builds are complete. Verify CUDA (minimal-gpu),
    ...    Pytorch and Tensorflow can be spawned successfully
    [Tags]    Sanity
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-316    ODS-481
    Verify Image Can Be Spawned    image=pytorch  size=Small
    ...    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Verify Image Can Be Spawned    image=tensorflow  size=Small
    ...    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    auth_type=${TEST_USER.AUTH_TYPE}
    [Teardown]    CUDA Teardown

Verify That Blackbox-exporter Is Protected With Auth-proxy
    [Documentation]    Verifies the blackbok-exporter pod is running the oauht-proxy container. Verify also
    ...    that all blackbox-exporter targets require authentication.
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1090

    Skip If RHODS Is Self-Managed

    Verify BlackboxExporter Includes Oauth Proxy

    Verify Authentication Is Required To Access BlackboxExporter Target
    ...    target_name=user_facing_endpoints_status_dsp    expected_endpoint_count=1

    Verify Authentication Is Required To Access BlackboxExporter Target
    ...    target_name=user_facing_endpoints_status_rhods_dashboard    expected_endpoint_count=1

    Verify Authentication Is Required To Access BlackboxExporter Target
    ...    target_name=user_facing_endpoints_status_workbenches    expected_endpoint_count=2

Verify That "Usage Data Collection" Is Enabled By Default
    [Documentation]    Verify that "Usage Data Collection" is enabled by default when installing ODS
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1234

    ${version_check} =    Is RHODS Version Greater Or Equal Than    1.8.0
    IF    ${version_check}==True
        ODS.Usage Data Collection Should Be Enabled
        ...    msg="Usage Data Collection" should be enabled by default after installing ODS
    ELSE
        ODS.Usage Data Collection Should Not Be Enabled
        ...    msg="Usage Data Collection" should not be enabled by default after installing ODS
    END

Verify Tracking Key Used For "Usage Data Collection"
    [Documentation]    Verify that "Usage Data Collection" is enabled by default when installing ODS
    [Tags]    Tier1
    ...       Sanity
    ...       ODS-1235

    ODS.Verify "Usage Data Collection" Key

Verify RHODS Release Version Number
    [Documentation]    Verify RHODS version matches x.y.z-build format
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-478   ODS-472
    ${version} =  Get RHODS Version
    Should Match Regexp    ${version}    ^[0-9]+\.[0-9]+\.[0-9]+\(-[0-9]+)*$

Verify Users Can Update Notification Email After Installing RHODS With The AddOn Flow
    [Documentation]    Verifies the Alert Notification email is updated in Addon-Managed-Odh-Parameters Secret and Alertmanager ConfigMap
    [Tags]    Tier2
    ...       ODS-673
    ...       Deployment-AddOnFlow
    ${email_to_change} =    Set Variable    dummyemail1@redhat.com
    ${cluster_name} =    Common.Get Cluster Name From Console URL
    ${current_email} =    Get Notification Email From Addon-Managed-Odh-Parameters Secret
    Update Notification Email Address    ${cluster_name}    ${email_to_change}
    Wait Until Notification Email From Addon-Managed-Odh-Parameters Contains  email=${email_to_change}
    Wait Until Notification Email In Alertmanager ConfigMap Is    ${email_to_change}
    [Teardown]    Update Notification Email Address    ${cluster_name}    ${current_email}

Verify JupyterHub Pod Logs Dont Have Errors About Distutil Library
    [Documentation]    Verifies that there are no errors related to DistUtil Library in Jupyterhub Pod logs
    [Tags]    Tier2
    ...       ODS-586
    Skip      msg=JupyterHub Pod is removed after KFNBC migration

Verify Grafana Is Connected To Prometheus Using TLS
    [Documentation]    Verifies Grafana is connected to Prometheus using TLS
    [Tags]    Tier2
    ...       ODS-963
    ...       ProductBug
    [Setup]  Set Library Search Order  Selenium Library
    Skip If RHODS Version Greater Or Equal Than    version=1.20.0
    ...    msg=Grafana was removed in RHODS 1.20
    Verify Grafana Datasources Have TLS Enabled
    Verify Grafana Can Obtain Data From Prometheus Datasource
    [Teardown]  Close Browser

Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In All ODS Projects
    [Documentation]    Verifies that CPU and Memory requests and limits are defined
    ...                for all containers in all pods for all ODS projects
    [Tags]    Sanity
    ...       Tier1
    ...       ProductBug
    ...       ODS-385
    ...       ODS-554
    ...       ODS-556
    ...       ODS-313
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    ${APPLICATIONS_NAMESPACE}
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    ${MONITORING_NAMESPACE}
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    ${OPERATOR_NAMESPACE}

Verify Monitoring Stack Is Reconciled Without Restarting The ODS Operator
    [Documentation]    Verify Monitoring Stack Is Reconciled Without Restarting The RHODS Operator
    [Tags]    Tier2
    ...       ODS-699
    ...       Execution-Time-Over-15m
    Replace "Prometheus" With "Grafana" In Rhods-Monitor-Federation
    Wait Until Operator Reverts "Grafana" To "Prometheus" In Rhods-Monitor-Federation

Verify RHODS Dashboard Explore And Enabled Page Has No Message With No Component Found
    [Tags]  Tier3
    ...     ODS-1556
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with data value empty for odh-enabled-applications-config
    ...     configmap in openshift
    ...     ProductBug:RHODS-4308
    [Setup]   Test Setup For Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=${APPLICATIONS_NAMESPACE}    name=odh-enabled-applications-config    src={"data":null}   #robocop: disable
    Delete Dashboard Pods And Wait Them To Be Back
    Reload Page
    Menu.Navigate To Page    Applications   Enabled
    Sleep    5s    msg=Wait for page to load
    Run Keyword And Continue On Failure   Page Should Not Contain    No Components Found
    Menu.Navigate To Page    Applications   Explore
    Sleep    5s    msg=Wait for page to load
    Run Keyword And Continue On Failure   Page Should Not Contain    No Components Found
    [Teardown]   Test Teardown For Configmap Changed On RHODS Dashboard

Verify RHODS Display Name and Version
    [Documentation]   Verify consistent rhods display name and version using
    ...    ClusterServiceVersion CR
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-1862
    ${rhods_csv_detail}   Oc Get    kind=ClusterServiceVersion    label_selector=olm.copiedFrom=${OPERATOR_NAMESPACE}
    ${rhods_csv_name}     Set Variable     ${rhods_csv_detail[0]['metadata']['name']}
    ${rhods_version}      Set Variable       ${rhods_csv_detail[0]['spec']['version']}
    ${rhods_displayname}  Set Variable       ${rhods_csv_detail[0]['spec']['displayName']}
    ${rhods_version_t}    Split String   ${rhods_csv_name}    .    1
    Should Be Equal       ${rhods_version_t[1]}   ${rhods_version}   msg=RHODS vesrion and label is not consistent
    Should Be Equal       ${rhods_displayname}   Red Hat OpenShift Data Science  msg=Dieplay name doesn't match

Verify RHODS Notebooks Network Policies
    [Documentation]    Verifies that the network policies for RHODS Notebooks are present on the cluster
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-2045
    Launch Notebook And Stop It
    ${CR_name} =    Get User CR Notebook Name    username=${TEST_USER.USERNAME}
    ${policy_ctrl} =    Run
    ...    oc get networkpolicy ${CR_name}-ctrl-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0]'
    ${expected_policy_ctrl} =    Get File    ods_ci/tests/Resources/Files/expected_ctrl_np.txt
    Should Be Equal As Strings    ${policy_ctrl}    ${expected_policy_ctrl}
    Log    ${policy_ctrl}
    Log    ${expected_policy_ctrl}
    ${policy_oauth} =    Run
    ...    oc get networkpolicy ${CR_name}-oauth-np -n ${NOTEBOOKS_NAMESPACE} -o json | jq '.spec.ingress[0]'
    ${expected_policy_oauth} =    Get File    ods_ci/tests/Resources/Files/expected_oauth_np.txt
    Should Be Equal As Strings    ${policy_oauth}    ${expected_policy_oauth}
    Log    ${policy_oauth}
    Log    ${expected_policy_oauth}

Verify All The Pods Are Using Image Digest Instead Of Tags
    [Documentation]    Verifies that the all the rhods pods are using image digest
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-2406
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get ns -l opendatahub.io/generated-namespace -o jsonpath='{.items[*].metadata.name}' ; echo ; oc get ns -l opendatahub.io/dashboard -o jsonpath='{.items[*].metadata.name}'  # robocop: disable
    Should Be Equal As Integers	 ${return_code}	 0  msg=Error getting the namespace using label
    ${projects_list} =    Split String    ${output}
    Append To List    ${projects_list}     ${OPERATOR_NAMESPACE}
    Container Image Url Should Use Image Digest Instead Of Tags Based On Project Name  @{projects_list}


*** Keywords ***
Delete Dashboard Pods And Wait Them To Be Back
    [Documentation]    Delete Dashboard Pods And Wait Them To Be Back
    Oc Delete    kind=Pod     namespace=${APPLICATIONS_NAMESPACE}    label_selector=app=rhods-dashboard
    OpenShiftLibrary.Wait For Pods Status    namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=rhods-dashboard  timeout=120

Test Setup For Rhods Dashboard
    [Documentation]    Test Setup for Rhods Dashboard
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}  ocp_user_auth_type=${TEST_USER.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}

Test Teardown For Configmap Changed On RHODS Dashboard
    [Documentation]    Test Teardown for Configmap changes on Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=${APPLICATIONS_NAMESPACE}    name=odh-enabled-applications-config    src={"data": {"jupyterhub": "true"}}   #robocop: disable
    Delete Dashboard Pods And Wait Them To Be Back
    Close All Browsers

Verify Authentication Is Required To Access BlackboxExporter Target
    [Documentation]    Verifies authentication is required to access a blackbox exporter target. To do so,
    ...                runs the curl command from the prometheus container trying to access a blacbox-exporter target.
    ...                The test fails if the response is not a prompt to log in with OpenShift
    [Arguments]    ${target_name}    ${expected_endpoint_count}
    @{links} =    Prometheus.Get Target Endpoints
    ...    target_name=${target_name}
    ...    pm_url=${RHODS_PROMETHEUS_URL}
    ...    pm_token=${RHODS_PROMETHEUS_TOKEN}
    ...    username=${OCP_ADMIN_USER.USERNAME}
    ...    password=${OCP_ADMIN_USER.PASSWORD}

    Length Should Be    ${links}    ${expected_endpoint_count}
    ...    msg=Unexpected number of endpoints in blackbox-exporter target (target_name:${target_name})

    ${pod_name} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=prometheus-
    FOR    ${link}    IN    @{links}
        Log    link:${link}
        ${command} =    Set Variable    curl --silent --insecure ${link}
        ${output} =    Run Command In Container    namespace=${MONITORING_NAMESPACE}    pod_name=${pod_name}
        ...    command=${command}    container_name=prometheus
        Should Contain    ${output}    Log in with OpenShift
        ...    msg=Authentication not present in blackbox-exporter target (target_name:${target_name} link: ${link})
    END

Verify BlackboxExporter Includes Oauth Proxy
    [Documentation]     Verifies the blackbok-exporter inludes 2 containers one for
    ...                 application and second for oauth proxy
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_start_with=blackbox-exporter-
    @{containers} =    Get Containers    pod_name=${pod}    namespace=${MONITORING_NAMESPACE}
    List Should Contain Value    ${containers}    oauth-proxy
    List Should Contain Value    ${containers}    blackbox-exporter

Verify Errors In Jupyterhub Logs
    [Documentation]    Verifies that there are no errors related to Distutil Library in Jupyterhub Pod Logs
    @{pods} =    Oc Get    kind=Pod    namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=jupyterhub
    FOR    ${pod}    IN    @{pods}
        ${logs} =    Oc Get Pod Logs    name=${pod['metadata']['name']}   namespace=${APPLICATIONS_NAMESPACE}
        ...    container=${pod['spec']['containers'][0]['name']}
        Should Not Contain    ${logs}    ModuleNotFoundError: No module named 'distutils.util'
    END

Verify Grafana Datasources Have TLS Enabled
    [Documentation]    Verifies TLS Is Enabled in Grafana Datasources
    ${secret} =  Oc Get  kind=Secret  name=grafana-datasources  namespace=${MONITORING_NAMESPACE}
    ${secret} =  Evaluate  base64.b64decode("${secret[0]['data']['datasources.yaml']}").decode('utf-8')  modules=base64
    ${secret} =  Evaluate  json.loads('''${secret}''')  json
    IF  'tlsSkipVerify' in ${secret['datasources'][0]['jsonData']}
    ...  Should Be Equal As Strings  ${secret['datasources'][0]['jsonData']['tlsSkipVerify']}  False

Verify Grafana Can Obtain Data From Prometheus Datasource
    [Documentation]   Verifies Grafana Can Obtain Data From Prometheus Datasource
    ${grafana_url} =  Get Grafana URL
    Launch Grafana    ocp_user_name=${OCP_ADMIN_USER.USERNAME}    ocp_user_pw=${OCP_ADMIN_USER.PASSWORD}    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}    grafana_url=https://${grafana_url}   browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Select Explore
    Select Data Source  datasource_name=Monitoring
    Run Promql Query  query=traefik_backend_server_up
    Page Should Contain  text=Graph

Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project
    [Documentation]    Verifies that CPU and Memory requests and limits are defined
    ...                for all containers in all pods for the specified project
    ...    Args:
    ...        project: Project name
    ...    Returns:
    ...        None
    [Arguments]    ${project}
    ${project_pods_info}=    Fetch Project Pods Info    ${project}
    FOR    ${pod_info}    IN    @{project_pods_info}
        Verify CPU And Memory Requests And Limits Are Defined For Pod    ${pod_info}
        IF    "${project}" == "${APPLICATIONS_NAMESPACE}"
            IF    "cuda-s2i" in "${pod_info['metadata']['name']}"
            ...    Verify Requests Contains Expected Values  cpu=2  memory=4Gi  requests=${pod_info['spec']['containers'][0]['resources']['requests']}
            IF    "minimal-gpu" in "${pod_info['metadata']['name']}" or "pytorch" in "${pod_info['metadata']['name']}" or "tensorflow" in "${pod_info['metadata']['name']}"
            ...    Verify Requests Contains Expected Values  cpu=4  memory=8Gi  requests=${pod_info['spec']['containers'][0]['resources']['requests']}
        END
    END

Wait Until Operator Reverts "Grafana" To "Prometheus" In Rhods-Monitor-Federation
    [Documentation]     Waits until rhods-operator reverts the configuration of rhods-monitor-federation,
    ...    verifiying it has the default value ("prometheus")
    Sleep    10m    msg=Waits until rhods-operator reverts the configuration of rhods-monitor-federation
    Wait Until Keyword Succeeds    15m    1m    Verify In Rhods-Monitor-Federation App Is    expected_app_name=prometheus

Verify In Rhods-Monitor-Federation App Is
    [Documentation]     Verifies in rhods-monitor-federation, app is showing ${expected_app_name}
    [Arguments]         ${expected_app_name}
    ${data} =    OpenShiftLibrary.Oc Get    kind=ServiceMonitor   namespace=${MONITORING_NAMESPACE}    field_selector=metadata.name==rhods-monitor-federation
    ${app_name}    Set Variable    ${data[0]['spec']['selector']['matchLabels']['app']}
    Should Be Equal    ${expected_app_name}    ${app_name}

Replace "Prometheus" With "Grafana" In Rhods-Monitor-Federation
    [Documentation]     Replace app to "Prometheus" with "Grafana" in Rhods-Monirot-Federation
    OpenShiftLibrary.Oc Patch    kind=ServiceMonitor
    ...                   src={"spec":{"selector":{"matchLabels": {"app":"grafana"}}}}
    ...                   name=rhods-monitor-federation   namespace=${MONITORING_NAMESPACE}  type=merge

Verify Requests Contains Expected Values
    [Documentation]     Verifies cpu and memory requests contain expected values
    [Arguments]   ${cpu}  ${memory}  ${requests}
    Should Be Equal As Strings    ${requests['cpu']}  ${cpu}
    Should Be Equal As Strings    ${requests['memory']}  ${memory}

CUDA Teardown
    [Documentation]    Ensures spawner is cleaned up if spawn fails
    ...    during the cuda smoke verification
    Fix Spawner Status
    End Web Test

Launch Notebook And Stop It    # robocop: disable
    [Documentation]    Opens a Notebook, forcing the creation of the NetworkPolicies
    Set Library Search Order    SeleniumLibrary
    Open Browser    ${ODH_DASHBOARD_URL}    browser=${BROWSER.NAME}    options=${BROWSER.OPTIONS}
    Login To RHODS Dashboard    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    Wait For RHODS Dashboard To Load
    Launch Jupyter From RHODS Dashboard Link
    Login To Jupyterhub    ${TEST_USER.USERNAME}    ${TEST_USER.PASSWORD}    ${TEST_USER.AUTH_TYPE}
    ${authorization_required} =    Is Service Account Authorization Required
    IF    ${authorization_required}    Authorize Jupyterhub Service Account
    Wait Until Page Contains    Start a notebook server
    Fix Spawner Status
    Spawn Notebook With Arguments    image=minimal-notebook
    End Web Test
