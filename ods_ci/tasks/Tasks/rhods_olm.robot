*** Settings ***
Documentation    Perform and verify RHODS OLM tasks
Metadata         RHODS OLM Version    1.0.0
Resource         ../Resources/RHODS_OLM/RHODS_OLM.resource
Resource         ../../tests/Resources/Common.robot
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String

***Variables***
${cluster_type}                 selfmanaged
${image_url}                    ${EMPTY}
${TEST_ENV}                     AWS
${INSTALL_TYPE}                 OperatorHub
${UPDATE_CHANNEL}               odh-nightlies
${RHODS_VERSION}                None
${CATALOG_SOURCE}               redhat-operators
${RHOAI_VERSION}                ${EMPTY}

*** Tasks ***
Can Install RHODS Operator
  [Tags]  install
  IF  "${PRODUCT}" == "ODH" and "${UPDATE_CHANNEL}" != "odh-stable"
      Set Global Variable  ${OPERATOR_NAME_LABEL}  opendatahub-operator
      Set Global Variable  ${MODEL_REGISTRY_NAMESPACE}    odh-model-registries
      Set Global Variable  ${OPERATOR_YAML_LABEL}  opendatahub-operator
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          Set Global Variable  ${OPERATOR_NAME}  rhods-operator
      ELSE
          Set Global Variable  ${OPERATOR_NAME}  opendatahub-operator
      END
  ELSE
      Set Global Variable  ${OPERATOR_NAME}  rhods-operator
      Set Global Variable  ${OPERATOR_NAME_LABEL}  rhods-operator
      Set Global Variable  ${OPERATOR_YAML_LABEL}  rhods-operator
      Set Global Variable  ${MODEL_REGISTRY_NAMESPACE}    rhoai-model-registries
  END
  Given Selected Cluster Type ${cluster_type}
  When Installing RHODS Operator    ${image_url}    ${install_plan_approval}    ${RHOAI_VERSION}
  Then RHODS Operator Should Be Installed
  [Teardown]   Install Teardown

Can Uninstall RHODS Operator
  [Tags]  uninstall
  IF  "${PRODUCT}" == "ODH" and "${UPDATE_CHANNEL}" != "odh-stable"
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          Set Global Variable  ${OPERATOR_NAME}  rhods-operator
      ELSE
          Set Global Variable  ${OPERATOR_NAME}  opendatahub-operator
      END
  ELSE
      Set Global Variable  ${OPERATOR_NAME}  rhods-operator
  END
  Given Selected Cluster Type ${cluster_type}
  When Uninstalling RHODS Operator
  Then RHODS Operator Should Be Uninstalled
  [Teardown]   Install Teardown

Can Upgrade RHODS Operator
  [Tags]  upgrade
  ...     ODS-543
  Given Selected Cluster Type ${cluster_type}
  When Upgrading RHODS Operator ${image_url}
  Then RHODS Operator Should Be Upgraded
