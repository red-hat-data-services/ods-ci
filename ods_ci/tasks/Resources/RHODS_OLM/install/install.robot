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
  ${return_code}	  Run And Return Rc  rm -rf ${EXECDIR}/${OLM_DIR}
  Should Be Equal As Integers	  ${return_code}	 0
