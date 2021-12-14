*** Keywords ***
Uninstalling RHODS Operator
  ${is_operator_installed} =  Is RHODS Installed
  Run Keyword If  ${is_operator_installed}  Run Keywords
  ...  Log  Uninstalling RHODS operator in ${cluster_type}  console=yes  AND
  ...  Uninstall RHODS

Uninstall RHODS  
  IF  '${cluster_type}'=='OSD'
    Uninstall RHODS In OSD
  ELSE IF  '${cluster_type}'=='PSI'
    Uninstall RHODS In PSI
  ELSE
    Fail  Only PSI and OSD are cluster types available
  END

Uninstall RHODS In OSD
  Delete RHODS CatalogSource
  Trigger RHODS Uninstall 
    
Uninstall RHODS In PSI
  Fail  Not implemented yet

RHODS Operator Should Be Uninstalled
  Verify RHODS Uninstallation
  Log  RHODS has been uninstalled  console=yes