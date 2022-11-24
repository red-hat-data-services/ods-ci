*** Keywords ***
Uninstalling RHODS Operator
  ${is_operator_installed} =  Is RHODS Installed
  Run Keyword If  ${is_operator_installed}  Run Keywords
  ...  Log  Uninstalling RHODS operator in ${cluster_type}  console=yes  AND
  ...  Uninstall RHODS

Uninstall RHODS
  IF  "${cluster_type}" == "managed"
    Uninstall RHODS In OSD
  ELSE IF  "${cluster_type}" == "selfmanaged"
    Uninstall RHODS In Self Managed Cluster
  ELSE
    Fail  Kindly provide supported cluster type
  END

Uninstall RHODS In OSD
  ${return_code}	  Run And Return Rc    git clone https://gitlab.cee.redhat.com/data-hub/olminstall.git rhodsolm
  Should Be Equal As Integers	${return_code}	 0
  Set Test Variable     ${filename}    rhodsolm
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${filename} && ./cleanup.sh   #robocop:disable
  Should Be Equal As Integers	${return_code}	 0
  Log To Console   ${output}

Uninstall RHODS In Self Managed Cluster
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
