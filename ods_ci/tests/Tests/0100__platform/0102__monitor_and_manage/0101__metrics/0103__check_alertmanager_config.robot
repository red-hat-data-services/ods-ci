*** Settings ***
Documentation   RHODS_alertmanager__VERIFICATION
...             Verify alertmanager secrets are correctly stored in when installing RHODS not using the add-on flow
...
...             = Variables =
...             | NAMESPACE                | Required |        RHODS Namespace/Project for RHODS operator POD |
...             | Secret Name              | Required |        Secret Name|
...             | CONFIGMAP_NAME           | Required |        Name  of config map|

Library        Collections
Library        OperatingSystem
Library        String
Library        OpenShiftLibrary

Resource       ../../../../Resources/RHOSi.resource
Resource       ../../../../Resources/Common.robot

Suite Setup     RHOSi Setup
Suite Teardown  RHOSi Teardown


*** Variables ***
${NAMESPACE}            ${MONITORING_NAMESPACE}
${CONFIGMAP_NAME}       alertmanager
${SECRET_NAME}          redhat-rhods-pagerduty


*** Test Cases ***
PagerDuty Dummy Secret Verification
     [Documentation]    Verification of PagerDuty Secret
     [Tags]  Smoke
     ...     ODS-737
     ...     ODS-500
     ...     RHOAIENG-13069
     ...     Deployment-Cli
     ...     Monitoring
     Skip If RHODS Is Self-Managed
     ${service_key}   Get PagerDuty Key From Alertmanager ConfigMap
     ${secret_key}    Get PagerDuty Key From Secrets
     Should Be Equal As Strings    ${service_key}   ${secret_key}   foo-bar

Verify DeadManSnitch configuration
    [Documentation]    Verification of DeadManSnitch configuration
    [Tags]   Smoke
    ...      ODS-648
    ...      RHOAIENG-13268
    ...      Monitoring
    Skip If RHODS Is Self-Managed
    ${rc}    Run And Return Rc
    ...    oc get secret redhat-rhods-deadmanssnitch -n ${MONITORING_NAMESPACE}
    Should Be Equal As Integers    ${rc}    0
    ${secret_snitch_url}    Run
    ...    oc get secret redhat-rhods-deadmanssnitch -n ${MONITORING_NAMESPACE} -o yaml | yq -r '.data.SNITCH_URL' | base64 -d
    ${configmap_snitch_url}    Run
    ...    oc get configmap alertmanager -n ${MONITORING_NAMESPACE} -o yaml | yq -r '.data["alertmanager.yml"] | from_yaml | .receivers[] | select(.name == "deadman-snitch") | .webhook_configs[0].url'
    Should Start With    ${configmap_snitch_url}    ${secret_snitch_url}


*** Keywords ***
Get PagerDuty Key From Alertmanager ConfigMap
     [Documentation]    Get Service Key From Alertmanager ConfigMap
     ${c_data}   Oc Get  kind=ConfigMap  namespace=${NAMESPACE}   field_selector=metadata.name==${CONFIGMAP_NAME}    #robocop:disable
     ${a_data}    Set Variable     ${c_data[0]['data']['alertmanager.yml']}
     ${match_list}      Get Regexp Matches   ${a_data}     service_key(:).*
     ${key}       Split String    ${match_list[0]}
     RETURN     ${key[-1]}

Get PagerDuty Key From Secrets
     [Documentation]    Get Secret Key From Secrets
     ${new}     Oc Get  kind=Secret  namespace=${namespace}   field_selector=metadata.name==${SECRET_NAME}
     ${body}    Set Variable    ${new[0]['data']['PAGERDUTY_KEY']}
     ${string}  Evaluate    base64.b64decode('${body}').decode('ascii')      modules=base64
     RETURN   ${string}
