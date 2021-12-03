**Settings**
Library    OpenShiftCLI
Resource   ../../../Resources/Page/ODH/JupyterHub/HighAvailability.robot

**Test Cases**
Verify Dashboard Deployment
    @{dashboard} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deployment = rhods-dashboard
    ${containerNames} =  Create List  rhods-dashboard  oauth-proxy
    Verify Deployment  ${dashboard}  2  2  ${containerNames}

Verify Traefik Deployment
    @{traefik} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=name = traefik-proxy
    ${containerNames} =  Create List  traefik-proxy  configmap-puller
    Verify Deployment  ${traefik}  3  2  ${containerNames}

Verify JH Deployment
    @{JH} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
    ${containerNames} =  Create List  jupyterhub  jupyterhub-ha-sidecar
    Verify JupyterHub Deployment  ${JH}  3  2  ${containerNames}