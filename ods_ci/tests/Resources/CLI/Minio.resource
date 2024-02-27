*** Settings ***
Documentation       Collcetion of keywords to deploy and remove MinIO storage
Library             OperatingSystem
Resource            ../Common.robot

*** Variables ***
${MINIO_RESOURCES_DIRPATH}=    ods_ci/tests/Resources/Files/minio
${MINIO_POD_FILEPATH}=    ${MINIO_RESOURCES_DIRPATH}/minio.yaml
${MINIO_SECRET_FILEPATH}=    ${MINIO_RESOURCES_DIRPATH}/minio_secret.yaml
${MINIO_SA_FILEPATH}=    ${MINIO_RESOURCES_DIRPATH}/minio_serviceaccount.yaml


*** Keywords ***
Deploy MinIO
    [Documentation]    Deploys MiniIO pod, service and route using the given ${minio_image}
    [Arguments]    ${minio_image}=quay.io/modh/ods-ci-minio-models:1.0
    ...            ${namespace}=minio    ${podname}=ods-ci-minio
    ...            ${service_name}=ods-ci-minio-srv    ${route_name}=ods-ci-minio-route
    ${exists}=    Run Keyword And Return Status
    ...    Check If Pod Exists    namespace=${namespace}    label_selector=app=minio    status_only=${FALSE}
    IF    ${exists}
        Log    message=Minio pod with name ${podname} in ${namespace} NS already present. Re-using existing one.
    ELSE
        ${key}    ${pw}=    Generate Minio Random Credentials
        Set Test Variable    ${key}
        Set Test Variable    ${pw}
        Set Test Variable    ${podname}
        Set Test Variable    ${minio_image}
        Set Test Variable    ${service_name}
        Set Test Variable    ${route_name}
        Create File From Template    ${MINIO_POD_FILEPATH}    ${MINIO_RESOURCES_DIRPATH}/minio_filled.yaml
        ${rc}=    Run And Return Rc    oc new-project ${namespace}
        ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${MINIO_RESOURCES_DIRPATH}/minio_filled.yaml -n ${namespace}
        Wait For Pods To Be Ready    label_selector=app=minio
        ...    namespace=${namespace}
    END
    ${rc}    ${route}=    Run And Return Rc And Output    oc get route ${route_name} -n ${namespace} --template={{.spec.host}}
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${route}

Generate Minio Random Credentials
    [Documentation]    Generates a random pair of keywords to be used as default MinIO user credentials
    ${key}=    Generate Random String    chars=[NUMBERS][LETTERS]
    ${pw}=    Generate Random String    chars=[NUMBERS][LETTERS]    length=12
    RETURN    ${key}    ${pw}

Get Minio Credentials
    [Documentation]    Extracts the default MinIO user credentials from the pod env variables
    [Arguments]    ${namespace}    ${podname}=ods-ci-minio
    ${rc}    ${key}=    Run And Return Rc And Output
    ...    oc get pod ${podname} -n ${namespace} -o jsonpath='{range .spec.containers[*].env[?(@.name=="MINIO_ACCESS_KEY")]}{@.value}{end}'    # robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}
    ${rc}    ${pw}=    Run And Return Rc And Output
    ...    oc get pod ${podname} -n ${namespace} -o jsonpath='{range .spec.containers[*].env[?(@.name=="MINIO_SECRET_KEY")]}{@.value}{end}'    # robocop: disable
    Should Be Equal As Integers    ${rc}    ${0}
    RETURN    ${key}    ${pw}

Remove Minio
    [Documentation]    Delete the MinIO objects from the cluster
    Log    message=To Be Implemented
    # for the time being the test using Minio is deleting the NS.