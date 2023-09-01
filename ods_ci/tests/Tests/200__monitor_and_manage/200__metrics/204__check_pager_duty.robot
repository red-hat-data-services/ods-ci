*** Settings ***
Documentation   RHODS_Pager_duty_key__VERIFICATION
...             Verify PagerDuty dummy secret is correctly stored in when installing RHODS not using the add-on flow
...
...             = Variables =
...             | NAMESPACE                | Required |        RHODS Namespace/Project for RHODS operator POD |
...             | REGEX_PATTERN            | Required |        Regular Expression Pattern to match the erro msg in capture log|
...             | Secret Name              | Required |        Secret Name|
...             | CONFIGMAP_NAME           | Required |        Name  of config map|

Library        Collections
Library        OperatingSystem
Library        String
Library        OpenShiftLibrary

Resource       ../../../Resources/RHOSi.resource
Resource       ../../../Resources/Common.robot

Suite Setup     RHOSi Setup
Suite Teardown  RHOSi Teardown


*** Variables ***
${NAMESPACE}            ${MONITORING_NAMESPACE}
${CONFIGMAP_NAME}         alertmanager
${SECRET_NAME}          redhat-rhods-pagerduty


*** Test Cases ***
PagerDuty Dummy Secret Verification
     [Documentation]    Verification of PagerDuty Secret
     [Tags]  Sanity
     ...     Tier1
     ...     ODS-737
     ...     Deployment-Cli
     Skip If RHODS Is Self-Managed
     ${service_key}   Get PagerDuty Key From Alertmanager ConfigMap
     ${secret_key}    Get PagerDuty Key From Secrets
     Should Be Equal As Strings    ${service_key}   ${secret_key}   foo-bar


*** Keywords ***
Get PagerDuty Key From Alertmanager ConfigMap
     [Documentation]    Get Service Key From Alertmanager ConfigMap
     ${c_data}   Oc Get  kind=ConfigMap  namespace=${NAMESPACE}   field_selector=metadata.name==${CONFIGMAP_NAME}    #robocop:disable
     ${a_data}    Set Variable     ${c_data[0]['data']['alertmanager.yml']}
     ${match_list}      Get Regexp Matches   ${a_data}     service_key(:).*
     ${key}       Split String    ${match_list[0]}
     RETURN     ${key[-1]}

Get PagerDuty Key From Secrets
     [Documentation]    Get Secert Key From Secrets
     ${new}     Oc Get  kind=Secret  namespace=${namespace}   field_selector=metadata.name==${SECRET_NAME}
     ${body}    Set Variable    ${new[0]['data']['PAGERDUTY_KEY']}
     ${string}  Evaluate    base64.b64decode('${body}').decode('ascii')      modules=base64
     RETURN   ${string}
