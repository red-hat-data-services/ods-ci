*** Settings ***
Library    String
Library    OpenShiftLibrary
Library    OperatingSystem


*** Keywords ***
Install CodeFlare
  [Documentation]  Installs the RHODS CodeFlare operator, expects RHODS operator already installed (with the appropriate CatalogSource already created)
  [Arguments]  ${cluster_type}
  ${file_path} =    Set Variable    tasks/Resources/CODEFLARE_OLM/install/
  IF  "${cluster_type}" == "managed"
        ${catalog_source}    Set Variable    "addon-managed-odh-catalog"
  ELSE
        ${catalog_source}    Set Variable    "redhat-operators"
  END
  Copy File    source=${file_path}subscription_template.yaml    destination=${file_path}subscription_apply.yaml
  Run    sed -i 's/<UPDATE_CHANNEL>/${UPDATE_CHANNEL}/' ${file_path}subscription_apply.yaml
  Run    sed -i 's/<CATALOG_SOURCE>/${catalog_source}/' ${file_path}subscription_apply.yaml
  Oc Apply   kind=List   src=${file_path}subscription_apply.yaml
  Remove File    ${file_path}subscription_apply.yml

Verify CodeFlare Installation
  Log  Verifying CodeFlare installation  console=yes
  Log To Console    Waiting for CodeFlare resources to be up and running
  Wait For Pods Numbers  1
  ...                   namespace=openshift-operators
  ...                   label_selector=app.kubernetes.io/name=codeflare-operator
  ...                   timeout=2000
  Wait For Pods Status  namespace=openshift-operators label_selector=app.kubernetes.io/name=codeflare-operator timeout=1200
  Log  Verified rhods-codeflare-operator  console=yes

Wait For Pods Numbers
  [Documentation]   Wait for number of pod during installation
  [Arguments]     ${count}     ${namespace}     ${label_selector}    ${timeout}
  ${status}   Set Variable   False
  FOR    ${counter}    IN RANGE   ${timeout}
         ${return_code}    ${output}    Run And Return Rc And Output   oc get pod -n ${namespace} -l ${label_selector} | tail -n +2 | wc -l
         IF    ${output} == ${count}
               ${status}  Set Variable  True
               Log To Console  pods ${label_selector} created
               Exit For Loop
         END
         Sleep    1 sec
  END
  IF    '${status}' == 'False'
        Run Keyword And Continue On Failure    FAIL    Timeout- ${output} pods found with the label selector ${label_selector} in ${namespace} namespace
  END
