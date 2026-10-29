*** Settings ***
Documentation    RHODS operator installation top-level keywords
Resource   ../pre-tasks/oc_is_operator_installed.robot
Resource   oc_install.robot


*** Keywords ***
Installing RHODS Operator
  [Documentation]   Installing the RHOAI operator
  [Arguments]       ${image_url}    ${install_plan_approval}    ${rhoai_version}=${EMPTY}
  ${is_operator_installed} =  Is RHODS Installed
  IF  not ${is_operator_installed}  Run Keywords
  ...  Log  Installing RHODS operator in ${cluster_type}  console=yes  AND
  ...  Set Suite Variable  ${image_url}  AND
  ...  Set Test Variable  ${OLM_INSTALL_GIT_REPO}  AND
  ...  Set Test Variable  ${OLM_INSTALL_GIT_REPO_BRANCH}  AND
  ...  Install RHODS   ${cluster_type}    ${image_url}    ${install_plan_approval}    ${rhoai_version}

RHODS Operator Should Be installed
  Verify RHODS Installation
  Configure MAPT Certificate Workaround
  ${version} =  Get RHODS Version    True
  Set Global Variable  ${RHODS_VERSION}  ${version}
  Log  RHODS has been installed  console=yes

Configure MAPT Certificate Workaround
  [Documentation]    Configure MAPT ingress certificate trust for RHOAI GatewayConfig versions
  IF    $TEST_ENV != "IBM_MAPT" or $PRODUCT not in ["RHOAI", "RHODS"]    RETURN
  ${version} =    Get RHODS Version    True
  ${supports_gateway_config} =
  ...    Evaluate    int(str($version).split(".")[0].lstrip("v")) >= 3
  IF    ${supports_gateway_config}
      ${certificate_command} =    Catenate    SEPARATOR=${SPACE}
      ...    bash ${EXECDIR}/tasks/Resources/RHODS_OLM/install/configure_mapt_certificates.sh
      ...    "${APPLICATIONS_NAMESPACE}" "${DSCI_NAME}"
      ${return_code}    ${output} =    Run And Return Rc And Output    ${certificate_command}
      Log    ${output}    console=yes
      Should Be Equal As Integers    ${return_code}    0
      ...    msg=Failed to apply the IBM_MAPT certificate workaround
  ELSE
      Log    Skipping IBM_MAPT certificate workaround for RHOAI ${version}; GatewayConfig requires RHOAI 3.0 or later
  END

Install Teardown
  [Documentation]   Remove cloned git repository
  [Arguments]       ${dir}=${OLM_DIR}
  ${status} =   Run Keyword And Return Status    Directory Should Exist   ${EXECDIR}/${dir}
  IF  "${INSTALL_TYPE}" != "OperatorHub"
      ${status} =   Run Keyword And Return Status    Directory Should Exist   ${dir}
      IF    ${status}
            ${return_code} =	  Run And Return Rc  rm -rf ${EXECDIR}/${dir}
            Should Be Equal As Integers	  ${return_code}	 0
      ELSE
            Log     Mentioned directory ${dir} is not present. Kindly verify if provided folder name is correct   level=WARN   console=yes
      END
  END
