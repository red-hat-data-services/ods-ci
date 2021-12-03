*** Settings ***
Library  Collections

*** Keywords ***
Verify Deployment
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
    [Arguments]  ${component}  ${nPods}  ${nContainers}  ${containerNames}
    #Standard deployment check
    Verify Deployment  ${component}  ${nPods}  ${nContainers}  ${containerNames}

    ${leader} =  Set Variable  None
    ${leader-found} =  Set Variable  False
    #Force to integer
    ${standby} =  Set Variable  ${0}

    FOR  ${index}  IN RANGE  0  ${nPods}
        &{pod} =  Set Variable  ${component}[${index}]
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
