*** Settings ***
Library     OpenShiftCLI
Resource    ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot


*** Test Cases ***
Verify Dashboard Deployment
    [Tags]    Sanity    ODS-546
    @{dashboard} =    Get    kind=Pod    namespace=redhat-ods-applications    label_selector=deployment = rhods-dashboard
    ${containerNames} =    Create List    rhods-dashboard    oauth-proxy
    Verify Deployment    ${dashboard}    2    2    ${containerNames}

Verify Traefik Deployment
    [Tags]    Sanity    ODS-546
    @{traefik} =    Get    kind=Pod    namespace=redhat-ods-applications    label_selector=name = traefik-proxy
    ${containerNames} =    Create List    traefik-proxy    configmap-puller
    Verify Deployment    ${traefik}    3    2    ${containerNames}

Verify JH Deployment
    [Tags]    Sanity    ODS-546    ODS-294
    @{JH} =    Get    kind=Pod    namespace=redhat-ods-applications    label_selector=deploymentconfig = jupyterhub
    ${containerNames} =    Create List    jupyterhub    jupyterhub-ha-sidecar
    Verify JupyterHub Deployment    ${JH}    3    2    ${containerNames}
