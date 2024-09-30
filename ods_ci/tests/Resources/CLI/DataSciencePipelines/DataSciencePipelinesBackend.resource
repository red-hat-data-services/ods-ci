*** Settings ***
Documentation    Collection of keywords to interact with Data Science Pipelines via CLI
Library          String
Library          ../../../../libs/DataSciencePipelinesAPI.py
Library          ../../../../libs/DataSciencePipelinesKfp.py
Resource         ../../../Resources/OCP.resource
Resource         ../../../Resources/Common.robot


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

    Run And Verify Command    oc process -f ${DSPA_PATH}/dspa-template.yaml ${template_parameters} | oc apply -n ${namespace} -f -    # robocop: off=line-too-long

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

Get DSP Version
    [Documentation]    Returns dspVersion of the DSPA deployed in ${namespace}
    [Arguments]     ${namespace}
    ${dsp_version}=    Run And Verify Command    oc get datasciencepipelinesapplications -n ${namespace} -o json | jq -r '.items[0].spec.dspVersion'    # robocop: off=line-too-long
    RETURN    ${dsp_version}

# robocop: disable:line-too-long
Create PipelineServer Using Custom DSPA
    [Documentation]    Install and verifies that DataSciencePipelinesApplication CRD is installed and working
    ...    When ${configure_pip_index}=${TRUE}, a configmap ds-pipeline-custom-env-vars is added to the
    ...    project, storing the values for pip_index_url and pip_trusted_host
    ...
    [Arguments]     ${namespace}    ${dspa_file}=data-science-pipelines-sample.yaml
    ...    ${assert_install}=${TRUE}    ${configure_pip_index}=${TRUE}

    Run And Verify Command     oc apply -f "${DSPA_PATH}/${dspa_file}" -n ${namespace}
    IF    ${assert_install}==True
        ${generation_value}=    Run And Verify Command    oc get datasciencepipelinesapplications -n ${namespace} -o json | jq '.items[0].metadata.generation'    # robocop: off=line-too-long
        Should Be True    ${generation_value} == 2    DataSciencePipelinesApplication created
    END

    IF  ${configure_pip_index}   Create Pipelines ConfigMap With Custom Pip Index Url And Trusted Host  ${namespace}

Verify Pipeline Server Deployments    # robocop: disable
    [Documentation]    Verifies the correct deployment of a DSPv2 DataSciencePipelineApplication
    [Arguments]    ${namespace}

    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=component=data-science-pipelines

    ${pods_count}=   Get Length    ${all_pods}
    IF    ${pods_count} < 7
         Fail    DSPA requires at least 7 pods running in the namespace
    END

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

Verify DSPv1 Pipeline Server Deployments
    [Documentation]    Verifies the correct deployment of a DSPv1 DataSciencePipelineApplication
    [Arguments]    ${namespace}

    @{all_pods}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=component=data-science-pipelines

    ${pods_count}=   Get Length    ${all_pods}
    IF    ${pods_count} < 4
         Fail    DSPA requires at least 4 pods running in the namespace
    END

    @{pipeline_api_server}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-dspa
    ${containerNames}=  Create List  oauth-proxy    ds-pipeline-api-server
    Verify Deployment    ${pipeline_api_server}  1  2  ${containerNames}

    @{pipeline_persistenceagent}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-persistenceagent-dspa
    ${containerNames}=  Create List  ds-pipeline-persistenceagent
    Verify Deployment    ${pipeline_persistenceagent}  1  1  ${containerNames}

    @{pipeline_scheduledworkflow}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=ds-pipeline-scheduledworkflow-dspa
    ${containerNames}=  Create List  ds-pipeline-scheduledworkflow
    Verify Deployment    ${pipeline_scheduledworkflow}  1  1  ${containerNames}

    @{mariadb}=  Oc Get    kind=Pod    namespace=${namespace}
    ...    label_selector=app=mariadb-dspa
    ${containerNames}=  Create List  mariadb
    Verify Deployment    ${mariadb}  1  1  ${containerNames}

Wait Until Pipeline Server Is Deployed
    [Documentation]    Waits until all the expected pods of the pipeline server
    ...                are running
    [Arguments]    ${namespace}

    ${dspVersion}=    Get DSP Version    ${namespace}
    IF    "${dspVersion}" == "v2"
            Wait Until Keyword Succeeds    10 times    10s
            ...    Verify Pipeline Server Deployments    namespace=${namespace}
    ELSE
             Wait Until Keyword Succeeds    10 times    10s
            ...    Verify DSPv1 Pipeline Server Deployments    namespace=${namespace}
    END


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
    Run And Verify Command    oc create configmap ds-pipeline-custom-env-vars -n ${namespace} --from-literal=pip_index_url=${PIP_INDEX_URL} --from-literal=pip_trusted_host=${PIP_TRUSTED_HOST}    # robocop: off=line-too-long

Create Secret With Pipelines Object Storage Information
    [Documentation]     Creates a secret needed to create a pipeline server containing the object storage credentials
    [Arguments]    ${namespace}    ${object_storage_access_key}    ${object_storage_secret_key}
    Run And Verify Command    oc create secret generic dashboard-dspa-secret -n ${namespace} --from-literal=AWS_ACCESS_KEY_ID=${object_storage_access_key} --from-literal=AWS_SECRET_ACCESS_KEY=${object_storage_secret_key}    # robocop: off=line-too-long
    Run And Verify Command    oc label secret dashboard-dspa-secret -n ${namespace} opendatahub.io/dashboard=true


Import Pipeline And Create Run
    [Documentation]
    [Arguments]    ${namespace}           ${username}                ${password}
    ...    ${pipeline_name}               ${pipeline_description}    ${pipeline_package_path}
    ...    ${pipeline_run_name}           ${pipeline_run_params}=${None}
    ...    ${experiment_name}=Default     ${experiment_description}=${EMPTY}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    ${pipeline_id}    ${pipeline_version_id}=    DataSciencePipelinesKfp.Upload Pipeline
    ...   pipeline_package_path=${pipeline_package_path}
    ...   pipeline_name=${pipeline_name}
    ...   description=${pipeline_description}
    ...   namespace=${namespace}

    ${experiment_id}=    DataSciencePipelinesKfp.Create Experiment    name=${experiment_name}
    ...    description=${experiment_description}    namespace=${namespace}

    ${pipeline_run_id}=    DataSciencePipelinesKfp.Run Pipeline
    ...   experiment_id=${experiment_id}
    ...   job_name=${pipeline_run_name}
    ...   pipeline_id=${pipeline_id}
    ...   version_id=${pipeline_version_id}
    ...   params=${pipeline_run_params}

    RETURN    ${pipeline_id}    ${pipeline_version_id}    ${pipeline_run_id}    ${experiment_id}

Verify Run Status
    [Documentation]  Verifies pipeline run status matches ${pipeline_run_expected_status}
    [Arguments]    ${namespace}           ${username}                  ${password}
    ...    ${pipeline_run_id}    ${pipeline_run_expected_status}="SUCCEEDED"

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    ${pipeline_run_status}=    DataSciencePipelinesKfp.Get Run Status    run_id=${pipeline_run_id}
    IF   "${pipeline_run_status}" != "${pipeline_run_expected_status}"
        ${error_msg}=    Catenate    Expected pipeline status was ${pipeline_run_expected_status} but pipeline run
        ...    has status=${pipeline_run_status}
        Fail    ${error_msg}
    END

Wait For Run Completion And Verify Status
    [Documentation]
    [Arguments]    ${namespace}           ${username}                  ${password}
    ...    ${pipeline_run_id}             ${pipeline_run_timeout}=180
    ...    ${pipeline_run_expected_status}="SUCCEEDED"

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    ${pipeline_run_status}=    DataSciencePipelinesKfp.Wait For Run Completion    run_id=${pipeline_run_id}
    ...    timeout=${pipeline_run_timeout}     sleep_duration=${5}

    Verify Run Status   namespace=${namespace}    username=${username}    password=${password}
    ...    pipeline_run_id=${pipeline_run_id}    pipeline_run_expected_status=${pipeline_run_expected_status}

    RETURN    ${pipeline_run_status}

Delete Pipeline And Related Resources
    [Documentation]  Deletes a pipeline, all it's versions and runs depending on the parameters
    ...    If ${delete_versions}=${TRUE}, deletes all versions
    ...    If ${delete_runs}=${TRUE}, deletes pipeline runs in ${experiment_id}
    ...    If ${experiment_id} is not provided, Default experiment will be used
    [Tags]    robot:recursive-continue-on-failure
    [Arguments]    ${namespace}           ${username}                ${password}
    ...    ${pipeline_id}                 ${experiment_id}=${EMPTY}
    ...    ${delete_versions}=${TRUE}     ${delete_runs}=${TRUE}

    DataSciencePipelinesKfp.Setup Client    user=${username}    pwd=${password}    project=${namespace}

    IF    ${delete_runs}==True
        DataSciencePipelinesKfp.Delete All Runs For Pipeline
        ...    namespace=${namespace}    pipeline_id=${pipeline_id}    experiment_id=${experiment_id}
    END

    # TODO: delete recurent jobs

    IF    ${delete_versions}==True
        DataSciencePipelinesKfp.Delete All Pipeline Versions    ${pipeline_id}
    END

    DataSciencePipelinesKfp.Delete Pipeline    ${pipeline_id}
