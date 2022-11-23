*** Settings ***
Documentation    Perform and verify Managed Starburst OLM tasks
Metadata         Managed Starburst OLM Version    1.0.0
Resource         ../Resources/RHODS_OLM/RHODS_OLM.resource
Library          OpenShiftLibrary
Library          OperatingSystem
Library          String
Library          ../../libs/Helpers.py

***Variables***
${cluster_type}          ROSA
${operator_version}      ${EMPTY}


*** Tasks ***
Install Managed Starburst
  [Tags]  install
  Check Managed Starburst Addon Is Not Installed
  Install Managed Starburst Addon    license=""    cluster_name=""
  RHODS Operator Should Be Installed
  [Teardown]   Install Teardown


*** Keywords ***
Check Managed Starburst Addon Is Not Installed
    ${is_operator_installed} =  Is Managed Starburst Installed
    IF    ${is_operator_installed}
        Fail    msg=Managed Starburst Addon is already installed        
    END
