*** Settings ***
Documentation       Post install test cases that mainly verify OCP resources and objects

Library             String
Library             OperatingSystem
Library             OpenShiftCLI
Library             OpenShiftLibrary
Library             ../../../../libs/Helpers.py
Resource            ../../../Resources/OCP.resource
Resource            ../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../Resources/Page/ODH/Prometheus/Prometheus.robot
Resource            ../../../Resources/ODS.robot
Resource            ../../../Resources/Page/ODH/Grafana/Grafana.resource

Suite Setup         RHOSi Setup

Resource            ../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource            ../../../Resources/Common.robot

*** Test Cases ***
Verify Traefik Deployment
    [Documentation]  Verifies RHODS Traefik deployment
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-546
    ...       ODS-552
    @{traefik} =  OpenShiftCLI.Get  kind=Pod  namespace=redhat-ods-applications  label_selector=name = traefik-proxy
    ${containerNames} =  Create List  traefik-proxy  configmap-puller
    Verify Deployment  ${traefik}  3  2  ${containerNames}

Verify JH Deployment
    [Documentation]  Verifies RHODS JH deployment
    [Tags]    Sanity
    ...       ODS-546  ODS-294  ODS-1250  ODS-237
    @{JH} =  OpenShiftCLI.Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
    ${containerNames} =  Create List  jupyterhub  jupyterhub-ha-sidecar
    Verify JupyterHub Deployment  ${JH}  3  2  ${containerNames}

Verify GPU Operator Deployment  # robocop: disable
    [Documentation]  Verifies Nvidia GPU Operator is correctly installed
    [Tags]  Sanity
    ...     Resources-GPU  # Not actually needed, but we first need to enable operator install by default
    ...     ODS-1157

    # Before GPU Node is added to the cluster
    # NS
    Verify Namespace Status  label=kubernetes.io/metadata.name=redhat-gpu-operator
    # Node-Feature-Discovery Operator
    Verify Operator Status  label=operators.coreos.com/node-feature-discovery-operator.redhat-gpu-operator
    ...    operator_name=node-feature-discovery-operator.v*
    # GPU Operator
    Verify Operator Status  label=operators.coreos.com/gpu-operator-certified-addon.redhat-gpu-operator
    ...    operator_name=gpu-operator-certified-addon.v*
    # nfd-controller-manager
    Verify Deployment Status  label=operators.coreos.com/node-feature-discovery-operator.redhat-gpu-operator
    ...    DName=nfd-controller-manager
    # nfd-master
    Verify DaemonSet Status  label=app=nfd-master  DSName=nfd-master
    # nfd-worker
    Verify DaemonSet Status  label=app=nfd-worker  DSName=nfd-worker

    # After GPU Node is added to the cluster
    # TODO: gpu-feature-discovery DS
    # ...   nvidia-container-toolkit-daemonset DS
    # ...   gpu-cluster-policy CP
    # ...   nvidia-dcgm-exporter DS
    # ...   nvidia-dcgm DS
    # ...   nvidia-device-plugin-daemonset DS
    # ...   nvidia-driver-daemonset-49.84.202201212103-0 DS
    # ...   nvidia-node-status-exporter DS
    # ...   nvidia-operator-validator DS

Verify That Prometheus Image Is A CPaaS Built Image
    [Documentation]    Verifies the images used for prometheus
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-734
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    Verify Container Image    redhat-ods-monitoring    ${pod}    prometheus
    ...    "registry.redhat.io/openshift4/ose-prometheus"
    Verify Container Image    redhat-ods-monitoring    ${pod}    oauth-proxy
    ...    "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify That Grafana Image Is A Red Hat Built Image
    [Documentation]    Verifies the images used for grafana
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-736
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=grafana-
    Verify Container Image    redhat-ods-monitoring    ${pod}    grafana
    ...    "registry.redhat.io/rhel8/grafana:7"
    Verify Container Image    redhat-ods-monitoring    ${pod}    auth-proxy
    ...    "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify That Blackbox-exporter Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for blackbox-exporter
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-735
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=blackbox-exporter-
    Verify Container Image    redhat-ods-monitoring    ${pod}    blackbox-exporter
    ...    "quay.io/integreatly/prometheus-blackbox-exporter:v0.19.0"

Verify That Alert Manager Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for alertmanager
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-733
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    Verify Container Image    redhat-ods-monitoring    ${pod}    alertmanager
    ...    "registry.redhat.io/openshift4/ose-prometheus-alertmanager"

Verify Oath-Proxy Image Is fetched From CPaaS
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-666
    ${pod} =    Find First Pod By Name  namespace=redhat-ods-applications   pod_start_with=rhods-dashboard-
    Verify Container Image      redhat-ods-applications     ${pod}      oauth-proxy
    ...     "registry.redhat.io/openshift4/ose-oauth-proxy:v4.8"

Verify Pytorch And Tensorflow Can Be Spawned
    [Documentation]    Check Cuda builds are complete and  Verify Pytorch and Tensorflow can be spawned
    [Tags]    Sanity
    ...       ODS-480
    Verify Cuda Builds Are Completed
    Verify Image Can Be Spawned  image=pytorch  size=Default
    Verify Image Can Be Spawned  image=tensorflow  size=Default

Verify That Blackbox-exporter Is Protected With Auth-proxy
    [Documentation]    Vrifies the blackbok-exporter inludes 2 containers one for application and second for oauth proxy
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1090
    Verify BlackboxExporter Includes Oauth Proxy
    Verify Authentication Is Required To Access BlackboxExporter

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
    ...       ODS-478
    ${version} =  Get RHODS Version
    Should Match Regexp    ${version}    ^[0-9]+\.[0-9]+\.[0-9]+\(-[0-9]+)*$

Verify Users Can Update Notification Email After Installing RHODS With The AddOn Flow
    [Documentation]    Vrifies the Alert Notification email is updated in Addon-Managed-Odh-Parameters Secret and Alertmanager ConfigMap
    [Tags]    Tier2
    ...       ODS-673
    ...       KnownIssues
    ...       Deployment-AddOnFlow
    ${email_to_change} =    Set Variable    dummyemail1@redhat.com
    ${cluster_id} =    Get Cluster ID
    ${cluster_name} =    Get Cluster Name By Cluster ID    ${cluster_id}
    ${current_email} =    Get Notification Email From Addon-Managed-Odh-Parameters Secret
    Update Notification Email Address    ${cluster_name}    ${email_to_change}
    Wait Until Notification Email From Addon-Managed-Odh-Parameters Contains  email=${email_to_change}
    Wait Until Notification Email In Alertmanager ConfigMap Is    ${email_to_change}
    [Teardown]    Update Notification Email Address    ${cluster_name}    ${current_email}

Verify JupyterHub Pod Logs Dont Have Errors About Distutil Library
    [Documentation]    Verifies that there are no errors related to DistUtil Library in Jupyterhub Pod logs
    [Tags]    Tier2
    ...       ODS-586
    Verify Errors In Jupyterhub Logs

Verify Grafana Is Connected To Prometheus Using TLS
    [Documentation]    Verifies Grafana is connected to Prometheus using TLS
    [Tags]    Tier2
    ...       ODS-963
    [Setup]  Set Library Search Order  Selenium Library
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
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-applications
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-monitoring
    Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods In Project    redhat-ods-operator

*** Keywords ***
Verify Cuda Builds Are Completed
    [Documentation]    Verify All Cuda Builds have status as Complete
    ${Pods} =    Run    oc get build -n redhat-ods-applications
    @{builds} =    Split String    ${Pods}    \n
    ${len} =    Get Length    ${builds}
    FOR    ${ind}    IN RANGE    1    ${len}
        @{pre} =    Split String    ${builds}[${ind}]
        ${is_cuda_build} =   Run Keyword And Return Status   Should Contain    ${pre}[0]    cuda
        IF    ${is_cuda_build} == True
            Should Be Equal As Strings    ${pre}[3]    Complete
        END
        Should Be Equal As Strings    ${pre}[3]    Complete
    END

Verify Authentication Is Required To Access BlackboxExporter
    [Documentation]    Verifies authentication is required to access blackbox exporter. To do so,
    ...                runs the curl command from the prometheus container trying to access a blacbox-exporter target.
    ...                The test fails if the response is not a prompt to log in with OpenShift
    @{links} =    Get Target Endpoints    target_name=user_facing_endpoints_status    pm_url=${RHODS_PROMETHEUS_URL}    pm_token=${RHODS_PROMETHEUS_TOKEN}    username${OCP_ADMIN_USER.USERNAME}    password=${OCP_ADMIN_USER.PASSWORD}
    Length Should Be    ${links}    2
    ${pod_name} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=prometheus-
    FOR    ${link}    IN    @{links}
        ${command} =    Set Variable    curl --insecure ${link}
        ${output} =    Run Command In Container    namespace=redhat-ods-monitoring    pod_name=${pod_name}
        ...    command=${command}    container_name=prometheus
        Should Contain    ${output}    Log in with OpenShift
        ...    msg=Log in with OpenShift should be required to access blackbox-exporter
    END

Verify BlackboxExporter Includes Oauth Proxy
    [Documentation]     Verifies the blackbok-exporter inludes 2 containers one for
    ...                 application and second for oauth proxy
    ${pod} =    Find First Pod By Name    namespace=redhat-ods-monitoring    pod_start_with=blackbox-exporter-
    @{containers} =    Get Containers    pod_name=${pod}    namespace=redhat-ods-monitoring
    List Should Contain Value    ${containers}    oauth-proxy
    List Should Contain Value    ${containers}    blackbox-exporter

Verify Errors In Jupyterhub Logs
    [Documentation]    Verifies that there are no errors related to Distutil Library in Jupyterhub Pod Logs
    @{pods} =    Oc Get    kind=Pod    namespace=redhat-ods-applications  label_selector=app=jupyterhub
    FOR    ${pod}    IN    @{pods}
        ${logs} =    Oc Get Pod Logs    name=${pod['metadata']['name']}   namespace=redhat-ods-applications
        ...    container=${pod['spec']['containers'][0]['name']}
        Should Not Contain    ${logs}    ModuleNotFoundError: No module named 'distutils.util'
    END

Verify Grafana Datasources Have TLS Enabled
    [Documentation]    Verifies TLS Is Enabled in Grafana Datasources
    ${secret} =  Oc Get  kind=Secret  name=grafana-datasources  namespace=redhat-ods-monitoring
    ${secret} =  Evaluate  base64.b64decode("${secret[0]['data']['datasources.yaml']}").decode('utf-8')  modules=base64
    ${secret} =  Evaluate  json.loads('''${secret}''')  json
    Run Keyword If  'tlsSkipVerify' in ${secret['datasources'][0]['jsonData']}
    ...  Should Be Equal As Strings  ${secret['datasources'][0]['jsonData']['tlsSkipVerify']}  False

Verify Grafana Can Obtain Data From Prometheus Datasource
    [Documentation]   Verifies Grafana Can Obtain Data From Prometheus Datasource
    ${grafana_url} =  Get Grafana URL
    Launch Grafana    ocp_user_name=${OCP_ADMIN_USER.USERNAME}    ocp_user_pw=${OCP_ADMIN_USER.PASSWORD}    ocp_user_auth_type=${OCP_ADMIN_USER.AUTH_TYPE}    grafana_url=https://${grafana_url}   browser=${BROWSER.NAME}   browser_options=${BROWSER.OPTIONS}
    Select Explore
    Select Data Source  datasource_name=Monitoring
    Run Promql Query  query=traefik_backend_server_up
    Page Should Contain  text=Graph

Verify CPU And Memory Requests And Limits Are Defined For All Containers In All Pods in Project
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
    END
