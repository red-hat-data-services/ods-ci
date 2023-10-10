*** Settings ***
Documentation    RHODS operator installation top-level keywords
Resource   ../pre-tasks/oc_is_operator_installed.robot
Resource   oc_install.robot
Resource   codeflare_install.resource


*** Keywords ***
Installing RHODS Operator ${image_url}
  ${is_operator_installed} =  Is RHODS Installed
  IF  not ${is_operator_installed}  Run Keywords
  ...  Log  Installing RHODS operator in ${cluster_type}  console=yes  AND
  ...  Set Suite Variable  ${image_url}  AND
  ...  Set Test Variable  ${RHODS_OSD_INSTALL_REPO}  AND
  ...  Install RHODS   ${cluster_type}    ${image_url}
  ${is_codeflare_managed} =    Is CodeFlare Managed
  Log  Will install CodeFlare operator: ${is_codeflare_managed}  console=yes
  IF  ${is_codeflare_managed}    Installing CodeFlare Operator

RHODS Operator Should Be installed
  Verify RHODS Installation
  ${version} =  Get RHODS Version
  Set Global Variable  ${RHODS_VERSION}  ${version}
  Log  RHODS has been installed  console=yes

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
  ELSE
            Log To Console    RHODS Operator is uninstalled successfully.
  END
