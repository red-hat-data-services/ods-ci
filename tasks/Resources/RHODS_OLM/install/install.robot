*** Keywords ***
Installing RHODS Operator ${operator_version}
  ${is_operator_installed} =  Is RHODS Installed
  Run Keyword Unless  ${is_operator_installed}  Run Keywords
  ...  Log  Installing RHODS operator in ${cluster_type}  console=yes  AND
  ...  Set Suite Variable  ${operator_version}  AND
  ...  Install RHODS  ${operator_version}
    
RHODS Operator Should Be installed
  Verify RHODS Installation
  ${version} =  Get RHODS Version
  Set Global Variable  ${RHODS_VERSION}  ${version}
  Log  RHODS has been installed  console=yes