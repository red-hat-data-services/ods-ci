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
    [Documentation]    Install the latest Red Hat OpenShift Pipelines Operator by default. A different version
    ...    can be installed by setting OPENSHIFT_PIPELINES_VERSION in test-variables.yml .
    ...    Example: if the value of OPENSHIFT_PIPELINES_VERSION is pipelines-1.12 will install the latest 1.12 version
    ...    that currently is 1.12.2
    ${return_code}=    Run And Return Rc
    ...    sed -i "s,channel: .*,channel: ${OPENSHIFT_PIPELINES_VERSION},g" ${EXECDIR}/${REDHAT_OPENSHIFT_PIPELINES_YAML}
    Should Be Equal As Integers    ${return_code}    0
    Oc Apply    kind=Subscription    src=${REDHAT_OPENSHIFT_PIPELINES_YAML}
    ${pod_count}=    Wait Until OpenShift Pipelines Operator Is Deployed
    Should Be True    ${pod_count} == 1    msg=Error installing OpenShift Pipelines operator
    ${res}  ${output}=    Run And Return Rc And Output
    ...    oc get csv -ojson | jq -r '.items[] | select(.metadata.name | test("openshift-pipelines-operator")) | .spec.version'
    Log     A OpenShift Pipelines Operator of version ${output} is installed    console=True


