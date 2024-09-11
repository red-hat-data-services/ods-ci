*** Settings ***
Documentation    Collection of keywords to interact with Data Science Pipelines via CLI
Library          OperatingSystem
Library          String
Resource         ../../../Resources/OCP.resource


*** Variables ***
${DSPA_PATH}=      tests/Resources/Files/pipeline-samples/v2/dspa


*** Keywords ***
Create Pipeline Server
    [Documentation]    Creates a pipeline server providing object storage and database information
    ...    When ${configure_pip_index}=${TRUE}, a configmap ds-pipeline-custom-env-vars is added to the
    ...    project, storing the values for pip_index_url and pip_trusted_host
    ...
    ...    Note: currently, only some of the parameters are used. In the future this keyword will be
    ...    enhanced to use them all
    [Arguments]    ${namespace}
    ...    ${object_storage_access_key}    ${object_storage_secret_key}
    ...    ${object_storage_endpoint}      ${object_storage_region}
    ...    ${object_storage_bucket_name}
#    ...    ${database_host}=${EMPTY}    ${database_port}=3306
#    ...    ${database_username}=${EMPTY}    ${database_password}=${EMPTY}
#    ...    ${database_db_name}=${EMPTY}
    ...    ${dsp_version}=v2
    ...    ${configure_pip_index}=${TRUE}

    Create Secret With Pipelines Object Storage Information    namespace=${namespace}
    ...    object_storage_access_key=${object_storage_access_key}
    ...    object_storage_secret_key=${object_storage_secret_key}

    # Pipeline Server creation fails if object storage url starts with https:// or http:// or if it ends with /
    ${object_storage_endpoint}=    Remove String    ${object_storage_endpoint}    https://    http://
    ${object_storage_endpoint}=    Strip String     ${object_storage_endpoint}    characters=/

    # Process DSPA Template to create pipeline server
    ${template_parameters}=    Catenate    -p DSP_VERSION=${dsp_version}
    ...    -p OBJECT_STORAGE_HOST=${object_storage_endpoint}
    ...    -p OBJECT_STORAGE_REGION=${object_storage_region}
    ...    -p OBJECT_STORAGE_BUCKET=${object_storage_bucket_name}

    Run      oc process -f ${DSPA_PATH}/dspa-template.yaml ${template_parameters} | oc apply -n ${namespace} -f -

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

# robocop: disable:line-too-long
Create PipelineServer Using Custom DSPA
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    ...    When ${configure_pip_index}=${TRUE}, a configmap ds-pipeline-custom-env-vars is added to the
    ...    project, storing the values for pip_index_url and pip_trusted_host
    ...
    [Arguments]     ${namespace}    ${dspa_file}=data-science-pipelines-sample.yaml
    ...    ${assert_install}=${TRUE}    ${configure_pip_index}=${TRUE}

    Run     oc apply -f "${DSPA_PATH}/${dspa_file}" -n ${namespace}
    IF    ${assert_install}==True
        ${generation_value}    Run    oc get datasciencepipelinesapplications -n ${namespace} -o json | jq '.items[0].metadata.generation'
        Should Be True    ${generation_value} == 2    DataSciencePipelinesApplication created
    END

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

Verify Pipeline Server Deployments    # robocop: disable
    [Documentation]    Verifies the correct deployment of DS Pipelines in the rhods namespace
    [Arguments]    ${namespace}

    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=component=data-science-pipelines
    Run Keyword And Continue On Failure    Length Should Be    ${all_pods}    7

    @{pipeline_api_server}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-dspa
    ${containerNames}=  Create List  oauth-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_api_server}  1  2  ${containerNames}

    @{pipeline_metadata_envoy}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-envoy-dspa
    ${containerNames}=  Create List  container    oauth-proxy
    Verify Deployment    ${pipeline_metadata_envoy}  1  2  ${containerNames}

    @{pipeline_metadata_grpc}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-metadata-grpc-dspa
    ${containerNames}=  Create List  container
    Verify Deployment    ${pipeline_metadata_grpc}  1  1  ${containerNames}

    @{pipeline_persistenceagent}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-dspa
    ${containerNames}=  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${pipeline_persistenceagent}  1  1  ${containerNames}

    @{pipeline_scheduledworkflow}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-dspa
    ${containerNames}=  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${pipeline_scheduledworkflow}  1  1  ${containerNames}

    @{pipeline_workflow_controller}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-workflow-controller-dspa
    ${containerNames}=  Create List  ds-pipeline-workflow-controller
    Verify Deployment    ${pipeline_workflow_controller}  1  1  ${containerNames}

    @{mariadb}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-dspa
    ${containerNames}=  Create List  mariadb
    Verify Deployment    ${mariadb}  1  1  ${containerNames}

Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    [Arguments]    ${namespace}
    Wait Until Keyword Succeeds    10 times    10s
    ...    Verify Pipeline Server Deployments    namespace=${namespace}

Wait Until Pipeline Server Is Deleted
    [Documentation]    Waits until all pipeline server pods are deleted
    [Arguments]    ${namespace}
    # robocop: off=expression-can-be-simplified
    FOR  ${_}  IN RANGE  0  30
        ${pod_count}=    Run    oc get pods -n ${namespace} -l component=data-science-pipelines | wc -l
        IF  ${pod_count}==0  BREAK
        Sleep  1s
    END

# robocop: disable:line-too-long
Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host
    [Documentation]     Creates a Configmap (ds-pipeline-custom-env-vars) in the project,
    ...    storing the values for pip_index_url and pip_trusted_host
    [Arguments]    ${namespace}
    Run    oc create configmap ds-pipeline-custom-env-vars -n ${namespace} --from-literal=pip_index_url=${PIP_INDEX_URL} --from-literal=pip_trusted_host=${PIP_TRUSTED_HOST}

Create Secret With Pipelines Object Storage Information
    [Documentation]     Creates a secret needed to create a pipeline server containing the object storage credentials
    [Arguments]    ${namespace}    ${object_storage_access_key}    ${object_storage_secret_key}
    Run    oc create secret generic dashboard-dspa-secret -n ${namespace} --from-literal=AWS_ACCESS_KEY_ID=${object_storage_access_key} --from-literal=AWS_SECRET_ACCESS_KEY=${object_storage_secret_key}
    Run    oc label secret dashboard-dspa-secret -n ${namespace} opendatahub.io/dashboard=true
