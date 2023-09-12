*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Library    ../../../../../libs/Helpers.py
Resource   ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource   ../../../../../tasks/Resources/RHODS_OLM/pre-tasks/oc_is_operator_installed.robot


***Variables***
${cluster_type}              selfmanaged
${image_url}                 ${EMPTY}


*** Test Cases ***
Install "Embedded Operator" RHODS
    [Documentation]
    [Tags]
    Set Global Variable    ${UPDATE_CHANNEL}    embedded
    Install Embedded RHODS    ${cluster_type}     ${image_url}

Verify Embedded RHODS Installation
    [Documentation]
    [Tags]
    RHODS Embedded Verification


*** Keywords ***
Install Embedded RHODS
    [Arguments]    ${cluster_type}     ${image_url}
    ${is_operator_installed} =  Is RHODS Installed
    IF    ${is_operator_installed}
        Fail    Use a clean cluster to run this installation
    END
    IF    "${cluster_type}" == "selfmanaged"
        ${file_path} =    Set Variable    ods_ci/tests/Resources/Files/operatorV2/
        ${rc} =    Run And Return Rc    oc create ns ${OPERATOR_NAMESPACE}
        IF    ${rc}!=0    Fail
        Copy File    source=${file_path}operatorgroup_template.yaml    destination=${file_path}operatorgroup_apply.yaml
        Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}operatorgroup_apply.yaml
        ${rc} =    Run And Return Rc    oc apply -f ${file_path}operatorgroup_apply.yaml
        IF    ${rc}!=0    Fail
        Remove File    ${file_path}operatorgroup_apply.yaml
        ${image_url_bool} =    Evaluate    '${image_url}' == ''
        IF  ${image_url_bool}
            # Prod build
            Copy File    source=${file_path}subscription_template.yaml    destination=${file_path}subscription_apply.yaml
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            Run    sed -i 's/<CS_NAME>/redhat-operators/' ${file_path}subscription_apply.yaml
            Run    sed -i 's/<CS_NAMESPACE>/openshift-marketplace/' ${file_path}subscription_apply.yaml
            ${rc} =    Run And Return Rc    oc apply -f ${file_path}subscription_apply.yaml
            IF    ${rc}!=0    Fail
            Remove File    ${file_path}subscription_apply.yaml
        ELSE
            # Custom catalogsource
            Copy File    source=${file_path}cs_template.yaml    destination=${file_path}cs_apply.yaml
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}cs_apply.yaml
            Run    sed -i 's/<IMAGE_URL>/${image_url}/' ${file_path}cs_apply.yaml
            ${rc} =    Run And Return Rc    oc apply -f ${file_path}cs_apply.yaml
            IF    ${rc}!=0    Fail
            Remove File    ${file_path}cs_apply.yaml
            Copy File    source=${file_path}subscription_template.yaml    destination=${file_path}subscription_apply.yaml
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            Run    sed -i 's/<CS_NAME>/rhods-catalog-dev/' ${file_path}subscription_apply.yaml
            Run    sed -i 's/<CS_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            ${rc} =    Run And Return Rc    oc apply -f ${file_path}subscription_apply.yaml
            IF    ${rc}!=0    Fail
            Remove File    ${file_path}subscription_apply.yaml
        END
    ELSE
        FAIL    Embedded RHODS can only be installed in self-managed clusters
    END

RHODS Embedded Verification
    Log  Verifying RHODS embedded installation  console=yes
    Log To Console    Waiting for all RHODS resources to be up and running
    Wait For Pods Numbers  1
    ...                   namespace=${OPERATOR_NAMESPACE}
    ...                   label_selector=name=rhods-operator
    ...                   timeout=2000
    Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
    Log  Verified ${OPERATOR_NAMESPACE}  console=yes
    IF    ${APPLICATIONS_NAMESPACE}!=${OPERATOR_NAMESPACE}    Namespace Should Not Exist    ${APPLICATIONS_NAMESPACE}
    Log  Verified ${APPLICATIONS_NAMESPACE}  console=yes
    IF    ${MONITORING_NAMESPACE}!=${OPERATOR_NAMESPACE}    Namespace Should Not Exist    ${MONITORING_NAMESPACE}
    Log  Verified ${MONITORING_NAMESPACE}  console=yes
    IF    ${NOTEBOOKS_NAMESPACE}!=${OPERATOR_NAMESPACE}    Namespace Should Not Exist    ${NOTEBOOKS_NAMESPACE}
    Log  Verified ${NOTEBOOKS_NAMESPACE}  console=yes
    ${filepath} =    Set Variable    ods_ci/tests/Resources/Files/operatorV2/
    ${expected} =    Get File    ${filepath}embedded.txt
    Run    oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}') --ignore-not-found -n ${OPERATOR_NAMESPACE} -o=custom-columns=KIND:.kind,NAME:.metadata.name | sort -k1,1 -k2,2 | grep -v "PackageManifest\\|Event\\|ClusterServiceVersion" > ${filepath}embedded_runtime.txt  # robocop: disable
    Process Resource List    filename_in=${filepath}$embedded_runtime.txt
    ...    filename_out=${filepath}embedded_processed.txt
    ${actual} =    Get File    ${filepath}embedded_processed.txt
    Remove File    ${filepath}embedded_processed.txt
    Remove File    ${filepath}embedded_runtime.txt
    Should Be Equal As Strings    ${expected}    ${actual}

Namespace Should Not Exist
    [Arguments]    ${namespace}
    ${rc}  ${out} =    Run And Return Rc And Output    oc get namespace ${namespace}
    Should Be Equal    ${rc}    1
    Should Be Equal    ${out}    Error from server (NotFound): namespaces "${namespace}" not found