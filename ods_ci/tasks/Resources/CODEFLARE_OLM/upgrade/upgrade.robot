*** Keywords ***
Upgrading CodeFlare Operator ${operator_version}
  ${is_operator_installed} =  Is CodeFlare Installed
  IF  ${is_operator_installed}
    ${old_version} =  Get CodeFlare Version
    Set Global Variable  ${CODEFLARE_VERSION}  ${old_version}
    Log  Upgrading CodeFlare  console=yes
    Upgrade CodeFlare  ${operator_version}
  ELSE
    Fail  CodeFlare is not installed
  END

CodeFlare Operator Should Be Upgraded
  Verify CodeFlare Upgrade
  Compare CodeFlare Versions
  Log  CodeFlare has been upgraded  console=yes

Compare CodeFlare Versions
  ${new_version} =  Get CodeFlare Version
  ${CODEFLARE_VERSION_EXISTS} =  Run Keyword And Return Status
  ...  Variable Should Exist  ${CODEFLARE_VERSION}
  IF  ${CODEFLARE_VERSION_EXISTS}
    Should Not Be Equal  ${new_version}  ${CODEFLARE_VERSION}
  ELSE
    Fail  CodeFlare upgrade has failed
  END
  Set Global Variable  ${CODEFLARE_VERSION}  ${new_version}
