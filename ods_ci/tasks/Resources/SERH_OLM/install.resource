*** Settings ***
Documentation    Collections of keywords to install/uninstall Managed Starburst
Library          OpenShiftLibrary
Resource         ../../../tests/Resources/Common.robot


*** Variables ***
${STARBURST_CR_DEFAULT_NAMESPACE}=    redhat-starburst-operator


*** Keywords ***
Check Managed Staburst Is Not Installed
    [Documentation]    Checks Managed Staburst is Not installed on the cluster.
    ...                Fails if it is
    ${installed}=    Is Managed Starburst Installed
    IF    ${installed} == ${TRUE}
        Fail    msg=Managed Starburst is still installed or not fully Uninstalled
    END

Is Managed Starburst Installed
    [Documentation]    Checks Managed Staburst is installed on the cluster.
    ...                Returns TRUE if the resources created by the install process
    ...                are found in the cluster
    ${result}=  Run Keyword And Return Status
    ...  Run Keywords
    ...  Oc Get  kind=Project  field_selector=metadata.name=${STARBURST_CR_DEFAULT_NAMESPACE}  AND
    ...  Oc Get  kind=CatalogSource  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}
    ...    field_selector=metadata.name=addon-managed-starburst-catalog
    RETURN  ${result}

Status Of Managed Starburst CR Should Be
    [Documentation]     Get the installation stage by reading the "starburstenterprise" CR YAML
    [Arguments]    ${expected_status}
    ${status}=     Run    oc get starburstenterprise -n ${STARBURST_CR_DEFAULT_NAMESPACE} -o json | jq '.items[].status.conditions[] | .reason,.type' | sed 's/"//g'   # robocop: disable
    ${status_list}=    Text To List    ${status}
    Run Keyword And Continue On Failure   Should Be Equal   ${status_list[-1]}   ${expected_status}

Verify Coordinator And Workers Deployment
    [Documentation]    Verifies the Starburst coordinator and workers have the expected
    ...                pods and containers
    @{coordinator}=  Oc Get    kind=Pod  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  label_selector=role=coordinator
    @{workers}=  Oc Get    kind=Pod  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  label_selector=role=worker
    ${coo_containerNames}=  Create List  coordinator    usage-client
    ${work_containerNames}=  Create List  worker
    Run Keyword And Continue On Failure    Verify Deployment  component=${coordinator}  nPods=1  nContainers=2  containerNames=${coo_containerNames}
    Run Keyword And Continue On Failure    Verify Deployment  component=${workers}      nPods=2  nContainers=1  containerNames=${work_containerNames}

Verify Prometheus Deployment
    [Documentation]    Verifies the Starburst prometheus instance has the expected
    ...                pods and containers
    @{prometheus}=  Oc Get    kind=Pod  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  field_selector=metadata.name==prometheus-starburst-0
    ${prom_containerNames}=  Create List  prometheus    config-reloader
    Run Keyword And Continue On Failure    Verify Deployment  component=${prometheus}      nPods=1  nContainers=2  containerNames=${prom_containerNames}
    @{prometheus_operator}=  Oc Get    kind=Pod  namespace=${STARBURST_CR_DEFAULT_NAMESPACE}  label_selector=k8s-app=prometheus-operator
    ${prom_op_containerNames}=  Create List  prometheus-operator
    Run Keyword And Continue On Failure    Verify Deployment  component=${prometheus_operator}      nPods=1  nContainers=1  containerNames=${prom_op_containerNames}

Managed Starburst Pods Should Be Deployed
    [Documentation]    Verifies the Starburst has the expected pods and containers
    ${running_pods}=     Run    oc get pods -n ${STARBURST_CR_DEFAULT_NAMESPACE} -o json | jq '.items[] | select(.status.phase=="Running") | .metadata.name' | sed 's/"//g'
    ${completed_pods}=     Run    oc get pods -n ${STARBURST_CR_DEFAULT_NAMESPACE} -o json | jq '.items[] | select(.status.phase=="Succeeded") | .metadata.name' | sed 's/"//g'
    ${running_pods_list}=    Text To List    ${running_pods}
    ${completed_pods_list}=    Text To List    ${completed_pods}
    Run Keyword And Continue On Failure    Length Should Be    ${running_pods_list}    7
    Run Keyword And Continue On Failure    Length Should Be    ${completed_pods_list}    2
    Verify Coordinator And Workers Deployment
    Verify Prometheus Deployment

Wait Until Managed Starburst Installation Is Completed
    [Documentation]    Keeps checking for Starburst resources until
    ...                all of them get the expected status
    [Arguments]    ${cr_chk_retries}=30   ${cr_chk_retries_interval}=30s
    ...            ${pods_chk_retries}=30   ${pods_chk_retries_interval}=30s
    Wait Until Keyword Succeeds    ${cr_chk_retries} times    ${cr_chk_retries_interval}
    ...    Status Of Managed Starburst CR Should Be    Deployed
    Wait Until Keyword Succeeds    ${pods_chk_retries} times    ${pods_chk_retries_interval}
    ...    Managed Starburst Pods Should Be Deployed

Delete Managed Starburst CRs
    [Documentation]    Delets the Staburst CRs
    [Arguments]    ${starburst_enterprise_cr}=starburstenterprise    ${starburst_hive_cr}=${NONE}
    ${cr}=     Oc Get    kind=StarburstEnterprise   name=${starburst_enterprise_cr}
    IF    ${cr} == ${NONE}
        Log    msg=There is probably no Starburst Enterprise CR named ${starburst_enterprise_cr}
    ELSE
        ${status}=    Run Keyword And Return Status
        ...    Oc Delete    kind=StarburstEnterprise   name=${starburst_enterprise_cr}
        ...                 namespace=${STARBURST_CR_DEFAULT_NAMESPACE}
        IF    ${status} == ${FALSE}
            Fail    msg=Failed to delete ${starburst_enterprise_cr} CR
        ELSE
            Log    successfully deleted ${starburst_enterprise_cr} CR
        END
    END
    IF    ${starburst_hive_cr} == ${NONE}
        Log    Skipping deletion of StarburstHive
    ELSE
        ${cr}=     Oc Get    kind=StarburstHive   name=${starburst_hive_cr}
        IF    ${cr} == ${NONE}
            Log    msg=There is probably no Starburst Hive CR named ${starburst_hive_cr}    level=WARN
        ELSE
            ${status}=    Run Keyword And Return Status
            ...    Oc Delete    kind=StarburstHive   name=${starburst_hive_cr}
            ...    namespace=${STARBURST_CR_DEFAULT_NAMESPACE}
            IF    ${status} == ${FALSE}
                Fail    msg=Failed to delete ${starburst_hive_cr} CR
            ELSE
                Log    successfully deleted ${starburst_hive_cr} CR    level=WARN
            END
        END
    END
