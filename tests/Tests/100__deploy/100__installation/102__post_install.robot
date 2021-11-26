**Settings**
Library  OpenShiftCLI

**Test Cases**
HA Components Are Deployed

    #Dashboard
    @{dashboard} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deployment = rhods-dashboard
    Length Should Be  ${dashboard}  2
    &{dict0} =  Set Variable  ${dashboard}[0]
    Length Should Be  ${dict0.status.containerStatuses}  2
    Log  ${dict0.status.containerStatuses[0].name}
    Log  ${dict0.status.containerStatuses[1].name}
    &{dict1} =  Set Variable  ${dashboard}[1]
    Length Should Be  ${dict1.status.containerStatuses}  2
    Log  ${dict1.metadata.name}
    Log  ${dict1.status.containerStatuses[0].name}
    Log  ${dict1.status.containerStatuses[1].name}

    #Traefik
    @{traefik} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=name = traefik-proxy
    Length Should Be  ${traefik}  3
    &{dict0} =  Set Variable  ${traefik}[0]
    Log  ${dict0.metadata.name}
    Length Should Be  ${dict0.status.containerStatuses}  2
    Log  ${dict0.status.containerStatuses[0].name}
    Log  ${dict0.status.containerStatuses[1].name}
    &{dict1} =  Set Variable  ${traefik}[1]
    Log  ${dict1.metadata.name}
    Length Should Be  ${dict1.status.containerStatuses}  2
    Log  ${dict1.status.containerStatuses[0].name}
    Log  ${dict1.status.containerStatuses[1].name}
    &{dict2} =  Set Variable  ${traefik}[2]
    Log  ${dict2.metadata.name}
    Length Should Be  ${dict2.status.containerStatuses}  2
    Log  ${dict2.status.containerStatuses[0].name}
    Log  ${dict2.status.containerStatuses[1].name}

    #JH
    @{JH} =  Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
    Length Should Be  ${JH}  3
    &{dict0} =  Set Variable  ${JH}[0]
    Log  ${dict0.metadata.name}
    Length Should Be  ${dict0.status.containerStatuses}  2
    Log  ${dict0.status.containerStatuses[0].name}
    Log  ${dict0.status.containerStatuses[1].name}
    &{dict1} =  Set Variable  ${JH}[1]
    Log  ${dict1.metadata.name}
    Length Should Be  ${dict1.status.containerStatuses}  2
    Log  ${dict1.status.containerStatuses[0].name}
    Log  ${dict1.status.containerStatuses[1].name}
    &{dict2} =  Set Variable  ${JH}[2]
    Log  ${dict2.metadata.name}
    Length Should Be  ${dict2.status.containerStatuses}  2
    Log  ${dict2.status.containerStatuses[0].name}
    Log  ${dict2.status.containerStatuses[1].name}