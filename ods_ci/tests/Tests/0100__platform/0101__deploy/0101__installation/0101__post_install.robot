*** Settings ***
Documentation       Post install test cases that mainly verify OCP resources and objects
Library             OperatingSystem
Library             String
Library             OpenShiftLibrary
Library             yaml
Library             ../../../../../libs/Helpers.py
Resource            ../../../../Resources/RHOSi.resource
Resource            ../../../../Resources/OCP.resource
Resource            ../../../../Resources/Page/OCPDashboard/OCPDashboard.resource
Resource            ../../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot
Resource            ../../../../Resources/Page/ODH/Prometheus/Prometheus.robot
Resource            ../../../../Resources/Page/ODH/Prometheus/Alerts.resource
Resource            ../../../../Resources/ODS.robot
Resource            ../../../../Resources/Page/ODH/Grafana/Grafana.resource
Resource            ../../../../Resources/Page/HybridCloudConsole/HCCLogin.robot
Resource            ../../../../Resources/Common.robot
Resource            ../../../../Resources/Page/NetworkPolicies/NetworkPolicies.resource
Resource            ../../../../Resources/Page/Notebooks/Notebooks.resource
Resource            ../../../../Resources/Page/Platforms/Platforms.resource
Suite Setup         RHOSi Setup
Suite Teardown      RHOSi Teardown


*** Variables ***
${RHODS_OPERATOR_GIT_REPO}       %{RHODS_OPERATOR_GIT_REPO=https://github.com/red-hat-data-services/rhods-operator}
${RHODS_OPERATOR_GIT_DIR}        ${OUTPUT DIR}/rhods-operator


*** Test Cases ***
Verify Dashbord has no message with NO Component Found
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with bad subscription present in openshift
    [Tags]  Tier3
    ...     ODS-1493
    [Setup]   Test Setup For Rhods Dashboard
    Oc Apply  kind=Subscription  src=tests/Tests/0100__platform/0101__deploy/0101__installation/bad_subscription.yaml
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
    [Tags]    Sanity    Tier1
    ...       ODS-546  ODS-294  ODS-1250  ODS-237
    @{NBC} =  Oc Get    kind=Pod  namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=notebook-controller
    @{ONBC} =  Oc Get    kind=Pod  namespace=${APPLICATIONS_NAMESPACE}  label_selector=app=odh-notebook-controller
    ${containerNames} =  Create List  manager
    Verify Deployment  ${NBC}  1  1  ${containerNames}
    Verify Deployment  ${ONBC}  1  1  ${containerNames}

Verify GPU Operator Deployment  # robocop: disable
    [Documentation]  Verifies Nvidia GPU Operator is correctly installed
    [Tags]  Sanity    Tier1
    ...     Resources-GPU    NVIDIA-GPUs  # Not actually needed, but we first need to enable operator install by default
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
    Skip If RHODS Is Self-Managed    # TODO Observability: Test can be removed once we fully onboard on the new stack.
    # Observability operator deploys Prometheus for us.
    Wait For Pods To Be Ready    label_selector=deployment=prometheus
    ...    namespace=${MONITORING_NAMESPACE}    timeout=60s
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_regex=prometheus-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    prometheus
    ...    registry.redhat.io/openshift4/ose-prometheus
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    oauth-proxy
    ...    registry.redhat.io/openshift4/ose-oauth-proxy

Verify That Blackbox-exporter Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for blackbox-exporter
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-735
    Skip If RHODS Is Self-Managed    # TODO Observability: We don't deploy blackbox-exporter yet on self-managed
    Wait For Pods To Be Ready    label_selector=deployment=blackbox-exporter
    ...    namespace=${MONITORING_NAMESPACE}    timeout=60s
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_regex=blackbox-exporter-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    blackbox-exporter
    ...    quay.io/integreatly/prometheus-blackbox-exporter

Verify That Alert Manager Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for alertmanager
    [Tags]    Sanity
    ...       Tier1
    ...       ODS-733
    Skip If RHODS Is Self-Managed    # TODO Observability: Test can be removed once we fully onboard on the new stack.
    # Observability operator deploys alertmanager for us.
    Wait For Pods To Be Ready    label_selector=deployment=prometheus
    ...    namespace=${MONITORING_NAMESPACE}    timeout=60s
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_regex=prometheus-
    Container Image Url Should Contain    ${MONITORING_NAMESPACE}    ${pod}    alertmanager
    ...    registry.redhat.io/openshift4/ose-prometheus-alertmanager

Verify Oath-Proxy Image Is A CPaaS Built Image
    [Documentation]    Verifies the image used for oauth-proxy
    [Tags]      Sanity
    ...         Tier1
    ...         ODS-666
    Wait For Pods To Be Ready    label_selector=app=${DASHBOARD_APP_NAME}
    ...    namespace=${APPLICATIONS_NAMESPACE}    timeout=60s
    ${pod} =    Find First Pod By Name  namespace=${APPLICATIONS_NAMESPACE}   pod_regex=${DASHBOARD_APP_NAME}-
    Container Image Url Should Contain      ${APPLICATIONS_NAMESPACE}     ${pod}      oauth-proxy
    ...     registry.redhat.io/openshift4/ose-oauth-proxy

Verify That CUDA Build Chain Succeeds
    [Documentation]    Check Cuda builds are complete. Verify CUDA (minimal-gpu),
    ...    Pytorch and Tensorflow can be spawned successfully
    [Tags]    Sanity
    ...       Tier1
    ...       OpenDataHub
    ...       ODS-316    ODS-481
    Verify Image Can Be Spawned    image=pytorch
    ...    username=${TEST_USER_3.USERNAME}    password=${TEST_USER_3.PASSWORD}
    ...    auth_type=${TEST_USER_3.AUTH_TYPE}
    Verify Image Can Be Spawned    image=tensorflow
    ...    username=${TEST_USER.USERNAME}    password=${TEST_USER.PASSWORD}
    ...    auth_type=${TEST_USER.AUTH_TYPE}
    [Teardown]    CUDA Teardown

Verify That Blackbox-exporter Is Protected With Auth-proxy
    [Documentation]    Verifies the blackbok-exporter pod is running the oauht-proxy container. Verify also
    ...    that all blackbox-exporter targets require authentication.
    [Tags]  Sanity
    ...     Tier1
    ...     ODS-1090

    Skip If RHODS Is Self-Managed    # TODO Observability: We don't deploy blackbox-exporter yet on self-managed
    # Oauth Proxy won't be used in new monitoring stack, it will be kube-rbac-proxy

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
    IF    ${version_check}
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

Verify JupyterHub Pod Logs Dont Have Errors About Distutil Library
    [Documentation]    Verifies that there are no errors related to DistUtil Library in Jupyterhub Pod logs
    [Tags]    Tier2
    ...       ODS-586
    Skip      msg=JupyterHub Pod is removed after KFNBC migration

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
    ...       Monitoring
    ...       Execution-Time-Over-15m
    Skip If RHODS Is Self-Managed    # TODO Observability: Likely needs to be revisited if it makes sense. Probably we
    # can change MonitoringStack/Otel collector and see if it reconciles back
    Replace "Prometheus" With "Grafana" In Rhods-Monitor-Federation
    Wait Until Operator Reverts "Grafana" To "Prometheus" In Rhods-Monitor-Federation

Verify RHODS Dashboard Explore And Enabled Page Has No Message With No Component Found
    [Documentation]   Verify "NO Component Found" message dosen't display
    ...     on Rhods Dashbord page with data value empty for odh-enabled-applications-config
    ...     configmap in openshift
    ...     ProductBug:RHODS-4308
    [Tags]  Tier3
    ...     ODS-1556
    [Setup]   Test Setup For Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=${APPLICATIONS_NAMESPACE}    name=odh-enabled-applications-config    src={"data":null}   # robocop: disable
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
    IF  "${PRODUCT}" == "${None}" or "${PRODUCT}" == "RHODS"
        ${CSV_DISPLAY} =    Set Variable     Red Hat OpenShift AI
    ELSE
        ${CSV_DISPLAY} =    Set Variable     Open Data Hub Operator
    END
    ${csv_name} =    Run    oc get csv -n ${OPERATOR_NAMESPACE} --no-headers | awk '/${CSV_DISPLAY}/ {print \$1}'
    ${csv_version} =    Run    oc get csv -n ${OPERATOR_NAMESPACE} --no-headers ${csv_name} -o custom-columns=":spec.version"
    ${csv_version_t} =    Split String   ${csv_name}    .    1
    Should Be Equal       ${csv_version_t[1].replace('v','')}   ${csv_version}
    ...    msg='${csv_name}' name and '${csv_version}' vesrion are not consistent

Verify Notebooks Network Policies For All Platforms
    [Documentation]    Creates a notebook programmatically using oc commands and verifies that the correct network policies are automatically created by the DSCInitialization controller. This test validates that:
    ...    - A notebook CR can be created without UI interaction
    ...    - The DSCInitialization controller automatically creates network policies via ReconcileDefaultNetworkPolicy()
    ...    - Network policies are properly configured for security isolation across all platforms
    ...    - Platform-specific network policy configurations are correctly applied
    ...    - Namespace labeling follows platform-specific patterns
    ...    - Policy compliance with OpenDataHub security requirements
    [Tags]    Smoke
    ...       Tier1
    ...       JupyterHub
    ...       ODS-2045
    ...       Operator

    ${platform_type} =    Detect Platform Type
    Create Notebook Programmatically And Wait For Ready
    ${CR_name} =    Get User CR Notebook Name    username=${TEST_USER.USERNAME}
    Verify Network Policy Existence And Configuration    ${CR_name}    ${platform_type}
    [Teardown]    Cleanup Notebook CR    ${TEST_USER.USERNAME}

Verify All The Pods Are Using Image Digest Instead Of Tags
    [Documentation]    Verifies that the all the rhods pods are using image digest
    [Tags]    Smoke
    ...       Tier1
    ...       ODS-2406
    ...       Operator
    ...       ExcludeOnODH
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get ns -l opendatahub.io/generated-namespace -o jsonpath='{.items[*].metadata.name}' ; echo ; oc get ns -l opendatahub.io/dashboard -o jsonpath='{.items[*].metadata.name}'  # robocop: disable
    Should Be Equal As Integers     ${return_code}     0  msg=Error getting the namespace using label
    ${projects_list} =    Split String    ${output}
    Append To List    ${projects_list}     ${OPERATOR_NAMESPACE}
    Container Image Url Should Use Image Digest Instead Of Tags Based On Project Name  @{projects_list}

Verify No Application Pods Run With Anyuid SCC Or As Root
    [Documentation]    Verifies that no pods in application namespace run with anyuid SCC or as a root
    [Tags]    Smoke
    ...       RHOAIENG-15892
    ...       Operator
    ${return_code}    ${output} =    Run And Return Rc And Output    oc get pod -n ${APPLICATIONS_NAMESPACE} -o custom-columns="NAMESPACE:metadata.namespace,NAME:metadata.name,SCC:.metadata.annotations.openshift\\.io/scc,CONTAINER_NAME:.spec.containers[*].name,RUNASUSER_CONTAINERS:.spec.containers[*].securityContext.runAsUser,RUNASUSER:.spec.securityContext.runAsUser"  # robocop: disable
    Should Be Equal As Integers     ${return_code}     0  msg=Error getting SCC of pods
    Log    Pods and their SCC are: ${output}
    ${status} =    Run Keyword And Return Status    Should Not Contain Any    ${output}    anyuid
    IF    not ${status}    Fail      msg=Some pods are running with anyuid SCC

    ${return_code}    ${output} =    Run And Return Rc And Output    oc get pod -n ${APPLICATIONS_NAMESPACE} -o json | jq '.items[] | select(any(.spec.containers[].securityContext.runAsUser; . == 0 ) or .spec.securityContext.runAsUser == 0) | .metadata.namespace + "/" + .metadata.name'
    Should Be Equal As Integers     ${return_code}     0  msg=Error getting runAsUser of pods
    ${status} =    Run Keyword And Return Status    Should Be Empty    ${output}
    IF    not ${status}    Fail      msg=Some pods are running as root (UID=0)

Verify No Alerts Are Firing After Installation Except For DeadManSnitch    # robocop: disable:too-long-test-case
    [Documentation]    Verifies that, after installation, only the DeadManSnitch alert is firing
    [Tags]    Smoke
    ...       ODS-540
    ...       RHOAIENG-13079
    # ...       Monitoring - just for tracking purposes but commented to not run the same test many times
    ...       Operator
    Skip If RHODS Is Self-Managed And New Observability Stack Is Disabled    # TODO Observability: We don't configure alerts yet with new observability stack, so may likely fail
    # If these numbers change, add also alert-specific tests
    # Need to wait to stabilize alerts after installation
    Run Keyword And Continue On Failure
    ...    Wait Until Keyword Succeeds    5 min    0 sec    Verify Number Of Alerting Rules  47  inactive
    Run Keyword And Continue On Failure
    ...    Verify Number Of Alerting Rules  1  firing
    # Order of keys in prometheus-configs.yaml
    # deadmanssnitch-alerting.rules
    Verify Alert Is Firing And Continue On Failure
    ...    DeadManSnitch    DeadManSnitch
    # trainingoperator-alerting.rules
    Verify "KubeFlow Training Operator" Alerts Are Not Firing And Continue On Failure
    # rhods-dashboard-alerting.rules
    Verify "RHODS Dashboard Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure
    Verify "RHODS Dashboard Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    # data-science-pipelines-operator-alerting.rules
    Verify "Data Science Pipelines Application Route Error Burn Rate" Alerts Are Not Firing And Continue On Failure
    Verify "Data Science Pipelines Operator Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    Verify "RHODS Data Science Pipelines" Alerts Are Not Firing And Continue On Failure
    # odh-model-controller-alerting.rules
    Verify "ODH Model Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    # kserve-alerting.rules
    Verify "Kserve Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    # ray-alerting.rules
    Verify "Distributed Workloads Kuberay" Alerts Are Not Firing And Continue On Failure
    # kueue-alerting.rules
    Verify "Distributed Workloads Kueue" Alerts Are Not Firing And Continue On Failure
    # workbenches-alerting.rules
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage above 90%    alert-duration=120
    Verify Alert Is Not Firing And Continue On Failure
    ...    RHODS-PVC-Usage    User notebook pvc usage at 100%    alert-duration=120
    Verify "Kubeflow Notebook Controller Pod Is Not Running" Alerts Are Not Firing And Continue On Failure
    Verify "ODH Notebook Controller Pod Is Not Running" Alerts Are Not Firing And Continue On Failure
    Verify "RHODS Jupyter Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    # trustyai-alerting.rules
    Verify "TrustyAI Controller Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure
    # model-registry-operator-alerting.rules
    # Model Registry not GA yet (Removed state), so its metrics are not enabled by default
    # Verify "Model Registry Operator Probe Success Burn Rate" Alerts Are Not Firing And Continue On Failure

Verify DSC Contains Correct Component Versions  # robocop: disable:too-long-test-case
    [Documentation]   Verify that component versions are present in DSC status and match the release repo
    [Tags]    Smoke
    ...       Operator
    ...       RHOAIENG-12693
    ...       ExcludeOnODH
    Gather Release Attributes From DSC And DSCI
    ${rhods_operator_branch} =  Replace String Using Regexp  ${DSC_RELEASE_VERSION}  ^([0-9]+\\.[0-9]+).*  \\1
    Common.Clone Git Repository  ${RHODS_OPERATOR_GIT_REPO}  rhoai-${rhods_operator_branch}  ${RHODS_OPERATOR_GIT_DIR}
    ${component_versions} =  Run
    ...    oc get dsc default-dsc -o json | jq '.status.components'
    ${component_versions_json} =    Evaluate     json.loads("""${component_versions}""")    json
    ${components} =  List Directories In Directory    ${RHODS_OPERATOR_GIT_DIR}/prefetched-manifests
    FOR  ${c}  IN  @{components}
        ${component_metadata_file} =  Set Variable
        ...     ${RHODS_OPERATOR_GIT_DIR}/prefetched-manifests/${c}/component_metadata.yaml
        ${file_exists} =  Run Keyword And Return Status    File Should Exist  ${component_metadata_file}
        IF  ${file_exists}
            IF    "${c}" == "datasciencepipelines"
                ${cmp} =  Set Variable   aipipelines
            ELSE
                ${cmp} =  Set Variable   ${c}
            END
            IF  $cmp not in $component_versions_json
                Log  ${cmp} present in the operator manifests, but not present in the DSC definition, hence skipping
                CONTINUE
            END
            IF  $component_versions_json[$cmp] == {} or $component_versions_json[$cmp]["managementState"] != "Managed"
                Log  ${cmp} is not managed, skipping version check
                CONTINUE
            END
            ${component_metadata_content} =  Get File  ${component_metadata_file}
            ${component_metadata} =    Evaluate     yaml.safe_load("""${component_metadata_content}""")    yaml
            Lists Should Be Equal    ${component_versions_json}[${cmp}][releases]   ${component_metadata}[releases]
            ...    msg=Component versions in DSC don't match component metadata in repo
        ELSE
            Log  ${c} does not provide component_metadata.yaml
        END
    END
    [Teardown]    Remove Directory  ${RHODS_OPERATOR_GIT_DIR}  recursive=True


*** Keywords ***
Delete Dashboard Pods And Wait Them To Be Back
    [Documentation]    Delete Dashboard Pods And Wait Them To Be Back
    Oc Delete    kind=Pod     namespace=${APPLICATIONS_NAMESPACE}    label_selector=app=${DASHBOARD_APP_NAME}
    # This should not be necessary but the `oc wait` command was failing otherwise
    Sleep    10s    msg=Wait for pods to be deleted.
    Wait For Pods To Be Ready    label_selector=app=${DASHBOARD_APP_NAME}
    ...    namespace=${APPLICATIONS_NAMESPACE}  timeout=180s

Test Setup For Rhods Dashboard
    [Documentation]    Test Setup for Rhods Dashboard
    Set Library Search Order    SeleniumLibrary
    Launch Dashboard  ocp_user_name=${TEST_USER.USERNAME}  ocp_user_pw=${TEST_USER.PASSWORD}  ocp_user_auth_type=${TEST_USER.AUTH_TYPE}
    ...               dashboard_url=${ODH_DASHBOARD_URL}  browser=${BROWSER.NAME}  browser_options=${BROWSER.OPTIONS}

Test Teardown For Configmap Changed On RHODS Dashboard
    [Documentation]    Test Teardown for Configmap changes on Rhods Dashboard
    Oc Patch    kind=ConfigMap      namespace=${APPLICATIONS_NAMESPACE}    name=odh-enabled-applications-config    src={"data": {"jupyterhub": "true"}}   # robocop: disable
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

    ${pod_name} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_regex=prometheus-
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
    ${pod} =    Find First Pod By Name    namespace=${MONITORING_NAMESPACE}    pod_regex=blackbox-exporter-
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
    ${project_pods_info} =    Fetch Project Pods Info    ${project}
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
    ${app_name} =    Set Variable    ${data[0]['spec']['selector']['matchLabels']['app']}
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
