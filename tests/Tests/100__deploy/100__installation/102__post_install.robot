*** Settings ***
Documentation  Post install test cases that mainly verify OCP resources and objects
Library    String
Library    OpenShiftCLI
Resource   ../../../Resources/OCP.resource
Resource   ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot


*** Test Cases ***
Verify Dashboard Deployment
    [Documentation]  Verifies RHODS Dashboard deployment
    [Tags]    Sanity
    ...       ODS-546
    @{dashboard} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deployment = rhods-dashboard
    ${containerNames} =  Create List  rhods-dashboard  oauth-proxy
    Verify Deployment  ${dashboard}  2  2  ${containerNames}

Verify Traefik Deployment
    [Documentation]  Verifies RHODS Traefik deployment
    [Tags]    Sanity
    ...       ODS-546
    @{traefik} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=name = traefik-proxy
    ${containerNames} =  Create List  traefik-proxy  configmap-puller
    Verify Deployment  ${traefik}  3  2  ${containerNames}

Verify JH Deployment
    [Documentation]  Verifies RHODS JH deployment
    [Tags]    Sanity
    ...       ODS-546  ODS-294
    @{JH} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
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
