*** Settings ***
Documentation    RHODS operator installation top-level keywords
Resource   ../pre-tasks/oc_is_operator_installed.robot
Resource   oc_install.robot


*** Keywords ***
Installing RHODS Operator ${image_url}
  ${is_operator_installed} =  Is RHODS Installed
  IF  not ${is_operator_installed}  Run Keywords
  ...  Log  Installing RHODS operator in ${cluster_type}  console=yes  AND
  ...  Set Suite Variable  ${image_url}  AND
  ...  Set Test Variable  ${RHODS_OSD_INSTALL_REPO}  AND
  ...  Install RHODS   ${cluster_type}    ${image_url}

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
