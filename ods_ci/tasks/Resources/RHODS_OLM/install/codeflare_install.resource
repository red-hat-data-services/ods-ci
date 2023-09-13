*** Settings ***
Documentation    RHODS CodeFlare operator installation keywords
Resource         ../../../../tests/Resources/Common.robot
Library    String
Library    OperatingSystem
Library    OpenShiftLibrary


*** Keywords ***
Installing CodeFlare Operator
  [Documentation]   Installs the RHODS CodeFlare operator if it is not already installed
  ${is_operator_installed} =  Is CodeFlare Installed
  IF  not ${is_operator_installed}
        Log  Installing CodeFlare operator  console=yes
        Install CodeFlare    ${cluster_type}
  END

CodeFlare Operator Should Be Installed
  [Documentation]   Verifies the RHODS CodeFlare operator installation and stores CodeFlare version
  Verify CodeFlare Installation
  ${version} =  Get CodeFlare Version
  Set Global Variable  $CODEFLARE_VERSION  ${version}
  Log  CodeFlare has been installed  console=yes

Install CodeFlare
  [Documentation]  Installs the RHODS CodeFlare operator, expects RHODS operator already installed
  [Arguments]  ${cluster_type}
  ${file_path} =    Set Variable    tasks/Resources/Files/
  IF  "${cluster_type}" == "managed"
        ${catalog_source} =   Set Variable    "addon-managed-odh-catalog"
  ELSE
        ${catalog_source} =   Set Variable    "redhat-operators"
  END
  Copy File    source=${file_path}codeflare_sub_template.yaml    destination=${file_path}codeflare_sub_apply.yaml
  Run    sed -i 's/<UPDATE_CHANNEL>/${CODEFLARE_UPDATE_CHANNEL}/' ${file_path}codeflare_sub_apply.yaml
  Run    sed -i 's/<CATALOG_SOURCE>/${catalog_source}/' ${file_path}codeflare_sub_apply.yaml
  Oc Apply   kind=List   src=${file_path}codeflare_sub_apply.yaml
  Remove File    ${file_path}codeflare_sub_apply.yaml

Verify CodeFlare Installation
  [Documentation]   Verifies the RHODS CodeFlare operator deployment existence
  Log  Verifying CodeFlare installation  console=yes
  Log To Console    Waiting for CodeFlare resources to be up and running
  Wait For Pods Numbers  1
  ...                   namespace=openshift-operators
  ...                   label_selector=app.kubernetes.io/name=codeflare-operator
  ...                   timeout=2000
  Wait For Pods Status  namespace=openshift-operators
  ...                   label_selector=app.kubernetes.io/name=codeflare-operator
  ...                   timeout=1200
  Log  Verified rhods-codeflare-operator  console=yes
