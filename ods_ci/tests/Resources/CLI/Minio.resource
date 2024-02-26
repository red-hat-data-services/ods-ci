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
    [Arguments]    ${minio_image}=quay.io/modh/ods-ci-minio-models:1.0
    ...            ${namespace}=minio
    # ${key}    ${pw}=    Generate Minio Random Credentials
    ${key}=    Set Variable    user
    ${pw}=    Set Variable    myfakepassword
    Set Test Variable    ${key}
    Set Test Variable    ${pw}
    Set Test Variable    ${url}    ${minio_image}
    Create File From Template    ${MINIO_POD_FILEPATH}    ${MINIO_RESOURCES_DIRPATH}/minio_filled.yaml
    # Create File From Template    ${MINIO_SECRET_FILEPATH}    ${MINIO_RESOURCES_DIRPATH}/minio_secret_filled.yaml
    ${rc}=    Run And Return Rc    oc new-project ${namespace}
    ${rc}    ${out}=    Run And Return Rc And Output    oc apply -f ${MINIO_RESOURCES_DIRPATH}/minio_filled.yaml -n ${namespace}
    # Oc Apply    kind=Pod    src=${MINIO_RESOURCES_DIRPATH}/minio_filled.yaml    namespace=${namespace}
    # Oc Apply    kind=Secret    src=${MINIO_RESOURCES_DIRPATH}/minio_secret_filled.yaml    namespace=${namespace}
    # Oc Apply    kind=ServiceAccount    src=${MINIO_SA_FILEPATH}    namespace=${namespace}
    ${route}=    Run And Return Rc And Output    oc get route minio-route -n ${namespace} --template={{.spec.host}}
    RETURN    ${route}

Generate Minio Random Credentials
    ${key}=    Generate Random String    chars=[NUMBERS][LETTERS]
    ${pw}=    Generate Random String    chars=[NUMBERS][LETTERS]
    RETURN    ${key}    ${pw}

Get Minio Credentials
    [Arguments]    ${namespace}    ${podname}=ods-ci-minio
    ${key}=    Set Variable    user
    ${pw}=    Set Variable    myfakepassword
    RETURN    ${key}    ${pw}