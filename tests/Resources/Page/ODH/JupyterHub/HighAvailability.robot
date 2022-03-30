*** Settings ***
Resource    ../../OCPDashboard/DeploymentConfigs/DeploymentConfigs.robot
Library  Collections
Library   OpenShiftCLI

Library  ../../../../libs/Helpers.py
Resource  ../../OCPDashboard/InstalledOperators/InstalledOperators.robot

*** Keywords ***
Verify Deployment
    [Documentation]     verifies the status of a Deployment in Openshift
    [Arguments]  ${component}  ${nPods}  ${nContainers}  ${containerNames}
    #No. of replicas
    Length Should Be  ${component}  ${nPods}

    FOR  ${index}  IN RANGE  0  ${nPods}
        &{pod} =  Set Variable  ${component}[${index}]
        #No. of containers
        Length Should Be  ${pod.status.containerStatuses}  ${nContainers}
        @{names} =  Create List
        FOR  ${j}  IN RANGE  0  ${nContainers}
            Append To List  ${names}  ${pod.status.containerStatuses[${j}].name}
            Should Be Equal As Strings  ${pod.status.phase}  Running
            ${state} =  Get Dictionary Keys  ${pod.status.containerStatuses[${j}].state}
            Should Be Equal As Strings  ${state}[0]  running
        END
        Sort List  ${names}
        Sort List  ${containerNames}
        Lists Should Be Equal  ${names}  ${containerNames}
    END

Verify JupyterHub Deployment
    [Documentation]     Enriched version of "Verify Deployment" keyword to check status
    ...                 of JupyterHub deployment
    [Arguments]  ${component}  ${nPods}  ${nContainers}  ${containerNames}
    #Standard deployment check
    Verify Deployment  ${component}  ${nPods}  ${nContainers}  ${containerNames}

    ${leader} =  Set Variable  None
    ${leader-found} =  Set Variable  False
    #Force to integer
    ${standby} =  Set Variable  ${0}

    FOR  ${index}  IN RANGE  0  ${nPods}
        &{pod} =  Set Variable  ${component}[${index}]
        ${version-check} =  Is RHODS Version Greater Or Equal Than  1.9.0
        IF  ${version-check}==True
            # Grab x.y.z version of jupyterhub
            ${jh_version} =    Run  oc -n redhat-ods-applications exec ${pod.metadata.name} -c jupyterhub -- pip show jupyterhub | grep Version: | awk '{split($0,a); print a[2]}'
            # 1.5 <= ${jh_version} < 2.0
            ${min} =    GTE    ${jh_version}    1.5.0
            ${max} =    GTE    1.9.99    ${jh_version}
            IF  ${min}==False or ${max}==False
                Fail    msg=JH version ${jh_version} is wrong (should be >=1.5,<2.0)
            END
        END
        FOR  ${j}  IN RANGE  0  ${nContainers}
            IF  '${pod.status.containerStatuses[${j}].name}' == 'jupyterhub'
                #leader's pod is recognized by jupyterhub container in ready status
                IF  '${pod.status.containerStatuses[${j}].ready}' == 'True'
                    IF  ${leader-found}
                        Log  ${leader}, ${pod.metadata.name}
                        Fail  Multiple Leaders
                    ELSE
                        ${leader} =  Set Variable  ${pod.metadata.name}
                        ${leader-found} =  Set Variable  True
                        Log  Leader Found: ${leader}
                    END
                ELSE
                    #there should be two pods with jupyterhub not in ready status
                    #increase value by one
                    ${standby} =  Set Variable  ${standby+1}
                END
            END
        END
    END
    Should Not Be Equal As Strings  ${leader}  None
    Should Be Equal As Strings  ${leader-found}  True
    Should Be Equal As Integers  ${standby}  2

Wait Until JH Deployment Is Ready
    [Documentation]     Wait Until jupyterhub deployment is completed
    [Arguments]   ${retries}=50
    FOR  ${index}  IN RANGE  0  1+${retries}
        @{JH} =  OpenShiftCLI.Get  kind=Pod  namespace=redhat-ods-applications  label_selector=deploymentconfig = jupyterhub
        ${containerNames} =  Create List  jupyterhub  jupyterhub-ha-sidecar
        ${jh_status}=    Run Keyword And Return Status    Verify JupyterHub Deployment  ${JH}  3  2  ${containerNames}
        Exit For Loop If    $jh_status == True
        Sleep    0.5
    END
    IF    $jh_status == False
        Fail    Jupyter Deployment not ready. Checks the logs
    END
    Sleep   1

Rollout JupyterHub
    [Documentation]     Rollouts JupyterHub deployment and wait until it is finished
    Start Rollout   dc_name=jupyterhub  namespace=redhat-ods-applications
    Wait Until JH Deployment Is Ready



