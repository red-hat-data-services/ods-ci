*** Settings ***
Library  Collections

*** Keywords ***
Verify Deployment
    [Arguments]  ${component}  ${nPods}  ${nContainers}  ${containerNames}  ${status}=True
    Set Log Level  Trace
    #No. of replicas
    Length Should Be  ${component}  ${nPods}

    FOR  ${index}  IN RANGE  0  ${nPods}
        &{pod} =  Set Variable  ${component}[${index}]
        #No. of containers
        Length Should Be  ${pod.status.containerStatuses}  ${nContainers}
        @{names} =  Create List
        FOR  ${j}  IN RANGE  0  ${nContainers}
            Append To List  ${names}  ${pod.status.containerStatuses[${j}].name}
            IF  ${status}
                Should Be Equal As Strings  ${pod.status.phase}  Running
                ${state} =  Get Dictionary Keys  ${pod.status.containerStatuses[${j}].state}
                Should Be Equal As Strings  ${state}[0]  running
            END
        END
        Sort List  ${names}
        Sort List  ${containerNames}
        Lists Should Be Equal  ${names}  ${containerNames}
    END