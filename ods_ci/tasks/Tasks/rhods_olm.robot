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
${RHODS_OSD_INSTALL_REPO}       None
@{SUPPORTED_TEST_ENV}           AWS   AWS_DIS   GCP   PSI   PSI_DIS   ROSA   IBM_CLOUD   CRC    AZURE	ROSA_HCP
${TEST_ENV}                     AWS
${INSTALL_TYPE}                 OperatorHub
${UPDATE_CHANNEL}               odh-nightlies
${OLM_DIR}                      rhodsolm
${RHODS_VERSION}                None

*** Tasks ***
Can Install RHODS Operator
  [Tags]  install
  IF  "${PRODUCT}" == "ODH"
      Set Global Variable  ${OPERATOR_NAMESPACE}  opendatahub-operators
      IF  "${UPDATE_CHANNEL}" == "odh-nightlies"
          Set Global Variable  ${OPERATOR_NAME}  rhods-operator
      ELSE
          Set Global Variable  ${OPERATOR_NAME}  opendatahub-operator
      END
  ELSE
      Set Global Variable  ${OPERATOR_NAME}  rhods-operator
  END
  Given Selected Cluster Type ${cluster_type}
  When Installing RHODS Operator ${image_url}
  Then RHODS Operator Should Be Installed
  [Teardown]   Install Teardown

Can Uninstall RHODS Operator
  [Tags]  uninstall
  IF  "${PRODUCT}" == "ODH"
      Set Global Variable  ${OPERATOR_NAMESPACE}  opendatahub-operators
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
