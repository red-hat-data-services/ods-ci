*** Keywords ***
Installing CodeFlare Operator ${image_url}
  ${is_operator_installed} =  Is CodeFlare Installed
  IF  not ${is_operator_installed}  Run Keywords
  ...  Log  Installing CodeFlare operator in ${cluster_type}  console=yes  AND
  ...  Set Test Variable  ${RHODS_OSD_INSTALL_REPO}  AND
  ...  Install CodeFlare

CodeFlare Operator Should Be installed
  Verify CodeFlare Installation
  ${version} =  Get CodeFlare Version
  Set Global Variable  ${CODEFLARE_VERSION}  ${version}
  Log  CodeFlare has been installed  console=yes

Install Teardown
  [Documentation]   Remove cloned git repository
  [Arguments]       ${dir}=${OLM_DIR}
  ${status} =   Run Keyword And Return Status    Directory Should Exist   ${EXECDIR}/${dir}
  IF  "${INSTALL_TYPE}" != "OperatorHub"
      ${status} =   Run Keyword And Return Status    Directory Should Exist   ${EXECDIR}/${dir}
      IF    ${status}
            ${return_code} =	  Run And Return Rc  rm -rf ${EXECDIR}/${dir}
            Should Be Equal As Integers	  ${return_code}	 0
      ELSE
            Log     Mentioned directory ${dir} is not present. Kindly verify if provided folder name is correct   level=WARN   console=yes
      END
  ELSE
            Log To Console    CodeFlare Operator installation tool is uninstalled successfully.
  END
