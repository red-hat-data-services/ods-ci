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
${REDHAT_OPENSHIFT_PIPELINES_YAML}=            ods_ci/tests/Resources/Files/redhat-openshift-pipelines.yaml
&{OPENSHIFT_PIPELINES_VERSION}=                4.10=pipelines-1.8   4.11=pipelines-1.9  4.12=pipelines-1.10   4.13=pipelines-1.10  #robocop:disable


*** Keywords ***
Install Red Hat OpenShift Pipelines
    [Documentation]    Install Red Hat OpenShift Pipelines
    ${oc_vesrion}    Get OpenShift Version
    ${pipeline}   Get From Dictionary     ${OPENSHIFT_PIPELINES_VERSION}    ${oc_vesrion}
    ${return_code}    ${output}    Run And Return Rc And Output    sed -i "s,channel: .*,channel: ${pipeline},g" ${EXECDIR}/${REDHAT_OPENSHIFT_PIPELINES_YAML}    #robocop:disable
    Should Be Equal As Integers	 ${return_code}	 0
    Oc Apply    kind=Subscription    src=${REDHAT_OPENSHIFT_PIPELINES_YAML}
    ${pod_count}    Wait Until OpenShift Pipelines Operator Is Deployed
    Should Be True    ${pod_count} == 1    All the pods were created
