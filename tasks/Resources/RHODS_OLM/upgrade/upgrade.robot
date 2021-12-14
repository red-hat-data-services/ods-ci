*** Keywords ***
Upgrading RHODS Operator ${operator_version}
  ${is_operator_installed} =  Is RHODS Installed
  IF  ${is_operator_installed}
    ${old_version} =  Get RHODS Version 
    Set Global Variable  ${RHODS_VERSION}  ${old_version} 
    Log  Upgrading RHODS  console=yes
    Upgrade RHODS  ${operator_version}
  ELSE 
    Fail  RHODS is not installed
  END 

RHODS Operator Should Be Upgraded
  Verify RHODS Upgrade
  Compare RHODS Versions
  Set Global Variable  ${RHODS_VERSION}  ${new_version}
  Log  RHODS has been upgraded  console=yes

Compare RHODS Versions
  ${new_version} =  Get RHODS Version
  ${RHODS_VERSION_EXISTS} =  Run Keyword And Return Status
  ...  Variable Should Exist  ${RHODS_VERSION}
  IF  ${RHODS_VERSION_EXISTS}
    Should Not Be Equal  ${new_version}  ${RHODS_VERSION}
  ELSE 
    Fail  Upgrade has failed
  END

Wait For RHODS Operator Pod Is Running
  Wait For Pods Number  6
  ...                   namespace=redhat-ods-operator
  ...                   label_selector=name=rhods-operator  
  ...                   timeout=180
  Log  pod operator created
  Wait for pods status  namespace=redhat-ods-operator  timeout=180