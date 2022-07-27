*** Keywords ***
Installing RHODS Operator ${operator_version}
  ${is_operator_installed} =  Is RHODS Installed
  Run Keyword Unless  ${is_operator_installed}  Run Keywords
  ...  Log  Installing RHODS operator in ${cluster_type}  console=yes  AND
  ...  Set Suite Variable  ${operator_version}  AND
  ...  Set Test Variable  ${RHODS_INSTALL_REPO}  AND
  ...  Install RHODS  ${operator_version}   ${cluster_type}

RHODS Operator Should Be installed
  Verify RHODS Installation
  ${version} =  Get RHODS Version
  Set Global Variable  ${RHODS_VERSION}  ${version}
  Log  RHODS has been installed  console=yes

Install Teardown
  [Documentation]   Remove cloned git repository
  [Arguments]    ${folder_name}= ${filename}
  ${return_code}	  Run And Return Rc  rm -rf ${EXECDIR}/${filename}
  Should Be Equal As Integers	  ${return_code}	 0
