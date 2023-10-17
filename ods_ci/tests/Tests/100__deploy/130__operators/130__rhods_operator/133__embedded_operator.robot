*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Library    ../../../../../libs/Helpers.py
Resource   ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource   ../../../../../tasks/Resources/RHODS_OLM/pre-tasks/oc_is_operator_installed.robot
Resource   ../../../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot
Suite Teardown    Uninstall RHODS V2 Embedded


***Variables***
${cluster_type}              selfmanaged
${image_url}                 ${EMPTY}
${dsci_name}                 default
${dsc_name}                  default


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
        ${rc}  ${out} =    Run And Return Rc And Output    oc create ns ${OPERATOR_NAMESPACE}
        IF    ${rc}!=0    Fail
        Log    ${out}    console=yes
        Copy File    source=${file_path}operatorgroup_template.yaml    destination=${file_path}operatorgroup_apply.yaml
        Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}operatorgroup_apply.yaml
        ${rc}  ${out} =    Run And Return Rc And Output   oc apply -f ${file_path}operatorgroup_apply.yaml
        IF    ${rc}!=0    Fail
        Log    ${out}    console=yes
        Remove File    ${file_path}operatorgroup_apply.yaml
        ${image_url_bool} =    Evaluate    '${image_url}' == ''
        IF  ${image_url_bool}
            # Prod 2.1 build
            Log    Installing prod 2.1 build    console=yes
            Copy File    source=${file_path}subscription_template_21.yaml    destination=${file_path}subscription_apply.yaml  # robocop: disable
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}subscription_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            # Approve install since installPlan set to manual approval
            ${rc}  ${out} =    Run And Return Rc And Output    oc patch installplan $(oc get installplans -n redhat-ods-operator | grep -v NAME | awk '{print $1}') -n redhat-ods-operator --type='json' -p '[{"op": "replace", "path": "/spec/approved", "value": true}]'  # robocop: disable
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            Remove File    ${file_path}subscription_apply.yaml
        ELSE
            # z-stream releases
            Log    Installing z-stream build with IIB ${image_url}    console=yes
            ${image_escaped} =    Escape Forward Slashes    ${image_url}
            Copy File    source=${file_path}cs_template.yaml    destination=${file_path}cs_apply.yaml
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}cs_apply.yaml
            Run    sed -i 's/<IMAGE_URL>/${image_escaped}/' ${file_path}cs_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}cs_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            Remove File    ${file_path}cs_apply.yaml
            Copy File    source=${file_path}subscription_template_z.yaml    destination=${file_path}subscription_apply.yaml  # robocop: disable
            Run    sed -i 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            Run    sed -i 's/<CS_NAME>/rhods-catalog-dev/' ${file_path}subscription_apply.yaml
            # Might need to be changed to openshift-marketplace in the future
            Run    sed -i 's/<CS_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}subscription_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
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
    IF    '${APPLICATIONS_NAMESPACE}'!='${OPERATOR_NAMESPACE}'    Namespace Should Not Exist    ${APPLICATIONS_NAMESPACE}  # robocop: disable
    Log  Verified ${APPLICATIONS_NAMESPACE}  console=yes
    IF    '${MONITORING_NAMESPACE}'!='${OPERATOR_NAMESPACE}'    Namespace Should Not Exist    ${MONITORING_NAMESPACE}
    Log  Verified ${MONITORING_NAMESPACE}  console=yes
    IF    '${NOTEBOOKS_NAMESPACE}'!='${OPERATOR_NAMESPACE}'    Namespace Should Not Exist    ${NOTEBOOKS_NAMESPACE}
    Log  Verified ${NOTEBOOKS_NAMESPACE}  console=yes
    V2 CRs Should Not Exist    ${dsc_name}    ${dsci_name}
    Log  Verified DSC and DSCI CRs  console=yes
    ${filepath} =    Set Variable    ods_ci/tests/Resources/Files/operatorV2/
    ${image_url_bool} =    Evaluate    '${image_url}' == ''
    IF  ${image_url_bool}
        Process Resource List    filename_in=${filepath}embedded.txt
        ...    filename_out=${filepath}embedded_processed_expected.txt
    ELSE
        Process Resource List    filename_in=${filepath}embedded_cs.txt
        ...    filename_out=${filepath}embedded_processed_expected.txt
    END
    Run    oc get $(oc api-resources --namespaced=true --verbs=list -o name | awk '{printf "%s%s",sep,$0;sep=","}') --ignore-not-found -n ${OPERATOR_NAMESPACE} -o=custom-columns=KIND:.kind,NAME:.metadata.name | sort -k1,1 -k2,2 | grep -v "PackageManifest\\|Event\\|ClusterServiceVersion\\|Lease" > ${filepath}embedded_runtime.txt  # robocop: disable
    Process Resource List    filename_in=${filepath}embedded_runtime.txt
    ...    filename_out=${filepath}embedded_processed_runtime.txt
    ${expected} =    Get File    ${filepath}embedded_processed_expected.txt
    ${actual} =    Get File    ${filepath}embedded_processed_runtime.txt
    Remove File    ${filepath}embedded_processed_runtime.txt
    Remove File    ${filepath}embedded_runtime.txt
    Remove File    ${filepath}embedded_processed_expected.txt
    Should Be Equal As Strings    ${expected}    ${actual}

Namespace Should Not Exist
    [Arguments]    ${namespace}
    ${rc}  ${out} =    Run And Return Rc And Output    oc get namespace ${namespace}
    Should Be Equal As Integers    ${rc}    1
    Should Be Equal As Strings    ${out}    Error from server (NotFound): namespaces "${namespace}" not found

V2 CRs Should Not Exist
    [Arguments]    ${dsc_name}    ${dsci_name}
    ${rc}  ${out} =    Run And Return Rc And Output    oc get datasciencecluster ${dsc_name}
    Should Be Equal As Integers    ${rc}    1
    Should Be Equal As Strings    ${out}    Error from server (NotFound): datascienceclusters.datasciencecluster.opendatahub.io "${dsc_name}" not found  # robocop: disable
    ${rc}  ${out} =    Run And Return Rc And Output    oc get dscinitialization ${dsci_name}
    Should Be Equal As Integers    ${rc}    1
    Should Be Equal As Strings    ${out}    Error from server (NotFound): dscinitializations.dscinitialization.opendatahub.io "${dsci_name}" not found  # robocop: disable

Uninstall RHODS V2 Embedded
    [Documentation]    Keyword to uninstall the version 2 of the RHODS operator in Self-Managed
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete subscription $(oc get subscription -n redhat-ods-operator --no-headers | awk '{print $1}') -n ${OPERATOR_NAMESPACE}  # robocop: disable
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting RHODS subscription
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete operatorgroup $(oc get operatorgroup -n redhat-ods-operator --no-headers | awk '{print $1}') -n ${OPERATOR_NAMESPACE}  # robocop: disable
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting operatorgroup
    ${return_code}    ${output}    Run And Return Rc And Output    oc delete ns -l opendatahub.io/generated-namespace
    Verify Project Does Not Exists  redhat-ods-applications
    Verify Project Does Not Exists  redhat-ods-monitoring
    Verify Project Does Not Exists  rhods-notebooks
    ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace ${OPERATOR_NAMESPACE}
    Verify Project Does Not Exists  ${OPERATOR_NAMESPACE}