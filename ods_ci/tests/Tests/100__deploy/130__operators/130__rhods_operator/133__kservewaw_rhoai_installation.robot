*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem
Library    ../../../../../libs/Helpers.py
Resource   ../../../../../tasks/Resources/RHODS_OLM/install/oc_install.robot
Resource   ../../../../../tasks/Resources/RHODS_OLM/pre-tasks/oc_is_operator_installed.robot
Resource   ../../../../../tasks/Resources/RHODS_OLM/uninstall/uninstall.robot



***Variables***
${cluster_type}              selfmanaged
${image_url}                 ${EMPTY}
${dsci_name}                 default-dsci
${dsc_name}                  default-dsc
${UPDATE_CHANNEL}            fast

*** Test Cases ***
Install RHOAI With Kserve Raw
    [Documentation]
    [Tags]   K_RAW_I
    Install RHOAI For KserveRaw   ${cluster_type}     ${image_url}
    Verify KserveRaw Installtion

*** Keywords ***
Install RHOAI For KserveRaw
    [Arguments]    ${cluster_type}     ${image_url}
    ${is_operator_installed} =  Is RHODS Installed
    IF    ${is_operator_installed}
        Fail    Use a clean cluster to run this installation
    END
    IF      "${cluster_type}" == "selfmanaged"
            ${file_path} =    Set Variable    ods_ci/tests/Resources/Files/operatorV2/
            ${rc}  ${out} =    Run And Return Rc And Output    oc create ns ${OPERATOR_NAMESPACE}
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            ${image_escaped} =    Escape Forward Slashes    ${image_url}
            Copy File    source=${file_path}cs_template.yaml    destination=${file_path}cs_apply.yaml
            Run    sed -i'' -e 's/<OPERATOR_NAMESPACE>/openshift-marketplace/' ${file_path}cs_apply.yaml
            Run    sed -i'' -e 's/<IMAGE_URL>/${image_escaped}/' ${file_path}cs_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}cs_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            Remove File    ${file_path}cs_apply.yaml
            Wait for Catalog To Be Ready    catalog_name=rhoai-catalog-dev
            Copy File    source=${file_path}operatorgroup_template.yaml    destination=${file_path}operatorgroup_apply.yaml
            Run    sed -i'' -e 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}operatorgroup_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output   oc apply -f ${file_path}operatorgroup_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            Remove File    ${file_path}operatorgroup_apply.yaml
            Copy File    source=${file_path}subscription_template.yaml    destination=${file_path}subscription_apply.yaml  # robocop: disable
            Run    sed -i'' -e 's/<OPERATOR_NAMESPACE>/${OPERATOR_NAMESPACE}/' ${file_path}subscription_apply.yaml
            Run    sed -i'' -e 's/<UPDATE_CHANNEL>/${UPDATE_CHANNEL}/' ${file_path}subscription_apply.yaml
            Run    sed -i'' -e 's/<CS_NAME>/rhoai-catalog-dev/' ${file_path}subscription_apply.yaml
            Run    sed -i'' -e 's/<CS_NAMESPACE>/openshift-marketplace/' ${file_path}subscription_apply.yaml
            ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}subscription_apply.yaml
            IF    ${rc}!=0    Fail
            Log    ${out}    console=yes
            Remove File    ${file_path}subscription_apply.yaml
            Wait Until Operator Subscription Last Condition Is
            ...    type=CatalogSourcesUnhealthy    status=False
            ...    reason=AllCatalogSourcesHealthy    subcription_name=rhoai-operator
            ...    namespace=${OPERATOR_NAMESPACE}
    ELSE
        FAIL    Vanilla KserveRaw can only be installed in self-managed clusters
    END
Verify KserveRaw Installtion
    ${filepath} =      Set Variable    ods_ci/tests/Resources/Files/operatorV2/
    ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}kserve_raw_dsci.yaml
    IF    ${rc}!=0     Fail
    ${rc}  ${out} =    Run And Return Rc And Output    oc apply -f ${file_path}kserve_raw_dsc.yaml
    IF    ${rc}!=0     Fail
    Log To Console    Waiting for all RHOAI resources to be up and running
    Wait For Pods Numbers  1
    ...                   namespace=${OPERATOR_NAMESPACE}
    ...                   label_selector=name=rhods-operator
    ...                   timeout=2000
    Wait For Pods Status  namespace=${OPERATOR_NAMESPACE}  timeout=1200
    ${kserve} =    Is Component Enabled    kserve    ${DSC_NAME}
    IF    "${kserve}" == "true"
          Wait For Pods Numbers   1
          ...                   namespace=${APPLICATIONS_NAMESPACE}
          ...                   label_selector=control-plane=kserve-controller-manager
          ...                   timeout=120
          Wait For Pods Numbers   3
          ...                   namespace=${APPLICATIONS_NAMESPACE}
          ...                   label_selector=app=odh-model-controller
          ...                   timeout=400
    END

