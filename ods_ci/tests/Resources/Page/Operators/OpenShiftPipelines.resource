*** Settings ***
Documentation       Test suite for OpenShift Pipeline

Resource            ../../RHOSi.resource
Resource            ../../ODS.robot
Resource            ../../Common.robot
Resource            ../../Page/ODH/ODHDashboard/ODHDashboard.robot
Resource            ../../Page/OCPDashboard/OCPMenu.robot
Library             DateTime
Library             ../../libs/DataSciencePipelinesAPI.py


*** Variables ***
${REDHAT_OPENSHIFT_PIPELINES_YAML}      ods_ci/tests/Resources/Files/redhat-openshift-pipelines.yaml


*** Keywords ***
# robocop: disable=too-many-calls-in-keyword,line-too-long
Install Red Hat OpenShift Pipelines
    [Documentation]    Install Red Hat OpenShift Pipelines operator depending on
    ...     OpenShift version, platform (AWS/GCP/...) and RHODS flavor (Managed/Self-Managed) with the objective of
    ...     testing all the operator versions without having to test all possible combinations:
    ...     - OpenShift 4.11:                      OpenShift Pipelines 1.9
    ...     - OpenShift 4.12, 4.13 (AWS and GCP):  OpenShift Pipelines 1.10 / 1.11 (depending on platform and flavor)
    ...     - OpenShift >= 4.12 (OpenStack):       OpenShift Pipelines 1.11
    ...     - OpenShift 4.14:                      OpenShift Pipelines 1.12
    ...     Note: the complete operator compatiblity matrix is published at
    ...      https://docs.openshift.com/container-platform/4.13/cicd/pipelines/op-release-notes.html
    ${oc_version}=    Get OpenShift Version
    ${is_self_managed}=    Is RHODS Self-Managed
    ${platform}=    Fetch Cluster Platform Type
    IF    "4.11" in "${oc_version}"
        ${openshift_pipelines_version}=    Set Variable    pipelines-1.9
    ELSE IF    "4.12" in "${oc_version}" or "4.13" in "${oc_version}"
        IF    ${is_self_managed} == ${TRUE} and "${platform}" == "AWS"
            ${openshift_pipelines_version}=    Set Variable    pipelines-1.10
        ELSE IF    ${is_self_managed} == ${FALSE} and "${platform}" == "AWS"
            ${openshift_pipelines_version}=    Set Variable    pipelines-1.11
        ELSE IF    ${is_self_managed} == ${TRUE} and "${platform}" == "GCP"
            ${openshift_pipelines_version}=    Set Variable    pipelines-1.11
        ELSE IF    ${is_self_managed} == ${FALSE} and "${platform}" == "GCP"
            ${openshift_pipelines_version}=    Set Variable    pipelines-1.10
        ELSE
            ${openshift_pipelines_version}=    Set Variable    pipelines-1.12
        END
    ELSE IF    "4.14" in "${oc_version}"
        ${openshift_pipelines_version}=    Set Variable    pipelines-1.12
    ELSE
        ${openshift_pipelines_version}=    Set Variable    pipelines-1.12
    END
    Log    message=Installing OpenShift Pipelines operator: ${openshift_pipelines_version} (${platform} ${oc_version} Self-Managed: ${is_self_managed})
    ...    console=True

    ${return_code}=    Run And Return Rc
    ...    sed -i "s,channel: .*,channel: ${openshift_pipelines_version},g" ${EXECDIR}/${REDHAT_OPENSHIFT_PIPELINES_YAML}
    Should Be Equal As Integers    ${return_code}    0
    Oc Apply    kind=Subscription    src=${REDHAT_OPENSHIFT_PIPELINES_YAML}
    ${pod_count}=    Wait Until OpenShift Pipelines Operator Is Deployed
    Should Be True    ${pod_count} == 1    msg=Error installing OpenShift Pipelines operator
