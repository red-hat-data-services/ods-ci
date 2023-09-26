*** Settings ***
Documentation    RHODS CodeFlare operator installation keywords
Resource         ../../../../tests/Resources/Common.robot
Library    String
Library    OperatingSystem
Library    OpenShiftLibrary


*** Keywords ***
Installing CodeFlare Operator
  [Documentation]   Installs the RHODS CodeFlare operator if it is not already installed
  [Arguments]  ${cluster_type}     ${image_url}
  ${is_operator_installed} =  Is CodeFlare Installed
  IF  not ${is_operator_installed}
        Log  Installing CodeFlare operator  console=yes
        Install CodeFlare    ${cluster_type}  ${image_url}
  END

CodeFlare Operator Should Be Installed
  [Documentation]   Verifies the RHODS CodeFlare operator installation and stores CodeFlare version
  Verify CodeFlare Installation
  ${version} =  Get CodeFlare Version
  Set Global Variable  $CODEFLARE_VERSION  ${version}
  Log  CodeFlare has been installed  console=yes

Install CodeFlare
  [Documentation]  Installs the RHODS CodeFlare operator, expects RHODS operator already installed
  [Arguments]  ${cluster_type}  ${image_url}
  ${file_path} =    Set Variable    tasks/Resources/Files/
  IF  "${cluster_type}" == "selfmanaged"
    IF  "${INSTALL_TYPE}" == "CLi"
        ${catalog_source} =   Set Variable    "rhods-catalog-dev"
    ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
        ${catalog_source} =   Set Variable    "redhat-operators"
    ELSE
        FAIL    Provided test environment ${cluster_type} and install type ${INSTALL_TYPE} not supported for CodeFlare
    END
  ELSE
    IF  "${INSTALL_TYPE}" == "CLi"
        ${catalog_source} =   Set Variable    "rhods-codeflare-catalog"
        # addon-managed-odh-catalog created by olminstall is scoped to redhat-ods-operator namespace,
        # a cluster-wide catalog source has to be created
        Create CodeFlare CatalogSource For Managed  ${file_path}  ${image_url}
    ELSE
        FAIL    Provided test environment ${cluster_type} and install type ${INSTALL_TYPE} not supported for CodeFlare
    END
  END

  Copy File    source=${file_path}codeflare_sub_template.yaml    destination=${file_path}codeflare_sub_apply.yaml
  Run    sed -i 's/<UPDATE_CHANNEL>/${CODEFLARE_UPDATE_CHANNEL}/' ${file_path}codeflare_sub_apply.yaml
  Run    sed -i 's/<CATALOG_SOURCE>/${catalog_source}/' ${file_path}codeflare_sub_apply.yaml
  Oc Apply   kind=List   src=${file_path}codeflare_sub_apply.yaml
  Remove File    ${file_path}codeflare_sub_apply.yaml

Create CodeFlare CatalogSource For Managed
  [Documentation]   Creates a new CatalogSource for managed env since the addon CS by olminstall is not cluster-wide
  [Arguments]  ${resource_file_path}  ${image_url}
  Copy File    source=${resource_file_path}codeflare_cs_template.yaml
  ...          destination=${resource_file_path}codeflare_cs_apply.yaml
  Run    sed -i 's,<CODEFLARE_INDEX_IMAGE>,${image_url},' ${resource_file_path}codeflare_cs_apply.yaml
  Oc Apply   kind=List   src=${resource_file_path}codeflare_cs_apply.yaml
  Remove File    ${resource_file_path}codeflare_cs_apply.yaml

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
