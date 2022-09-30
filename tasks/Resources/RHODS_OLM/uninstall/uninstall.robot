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
      ${return_code}    ${output}	  Run And Return Rc And Output   git clone ${RHODS_INSTALL_REPO}
      Log   ${output}    console=yes
      Should Be Equal As Integers	${return_code}	 0
      ${git_folder} =  Get Regexp Matches    ${output}	   Cloning into \'(.*?)\'    1
      Log   ${git_folder}[0]
      ${return_code}    ${output}    Run And Return Rc And Output   (cd ${git_folder}[0]; ./rhods uninstall <<< Y); wait $!; sleep 60   #robocop:disable
      Log    ${output}    console=yes
      Should Be Equal As Integers	${return_code}	 0
      ${return_code}    ${output}    Run And Return Rc And Output   (cd ${git_folder}[0]; ./rhods cleanup <<< Y); wait $!; sleep 60   #robocop:disable
      Log    ${output}    console=yes
      Should Be Equal As Integers	${return_code}	 0
      ${return_code}	  ${output}    Run And Return Rc And Output   rm -rf ${git_folder}[0]
      Log    ${output}    console=yes
      Should Be Equal As Integers	  ${return_code}	 0

RHODS Operator Should Be Uninstalled
  Verify RHODS Uninstallation
  Log  RHODS has been uninstalled  console=yes
