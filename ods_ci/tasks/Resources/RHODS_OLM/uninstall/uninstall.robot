*** Settings ***
Resource   ../install/oc_install.robot
Resource   oc_uninstall.robot

Library    Process

*** Keywords ***
Uninstalling RHODS Operator
  ${is_operator_installed} =  Is RHODS Installed
  IF  ${is_operator_installed}  Run Keywords
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
  Clone OLM Install Repo
  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t addon   #robocop:disable
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS
  Log To Console   ${output}

Uninstall RHODS In Self Managed Cluster
  [Documentation]  Uninstall rhods from self-managed cluster
  IF  "${INSTALL_TYPE}" == "CLi"
      Uninstall RHODS In Self Managed Cluster Using CLI
  ELSE IF  "${INSTALL_TYPE}" == "OperatorHub"
      Uninstall RHODS In Self Managed Cluster For Operatorhub
  ELSE
        FAIL    Provided install type is not supported
  END

Run and Watch Command
  [Arguments]    ${command}    ${timeout_min}=10    ${excpected_text}=${NONE}
  Log    Watching command output: ${command}   console=True
  @{args} =    Split String    ${command}
  ${process_log} =    Set Variable    ${OUTPUT DIR}/${args}[0].log
  Create File    ${process_log}
  Create File    ${process_log}.old
  ${process} =    Start Process    ${command}    shell=True    stdout=${process_log}    stderr=STDOUT    # robocop: disable
  Log    Shell process started in the background   console=True
  ${timeout_result} =    Wait Until Keyword Succeeds    ${timeout_min} min    10 s
  ...    Read Command Log    ${process}    ${process_log}
  ${proc_result} =	    Wait For Process    ${process}    timeout=3 secs
  Terminate Process    ${process}    kill=true
  Should Be Equal As Integers	    ${proc_result.rc}    0    msg=Error occured while running: ${command}
  Should Be True    ${timeout_result.rc} == 0
  Should Contain    ${process_log}    ${excpected_text}
  RETURN    ${proc_result.rc}

Read Command Log
  [Arguments]    ${process}    ${process_log}
  Log To Console    .    no_newline=true
  ${new_log_data} = 	Get File 	${process_log}
  ${old_log_data} = 	Get File 	${process_log}.old
  ${last_line_index} =    Get Line Count    ${old_log_data}
  @{new_lines} =    Split To Lines    ${new_log_data}    ${last_line_index}
  FOR    ${line}    IN    @{new_lines}
      Log To Console    ${line}
  END
  Create File    ${process_log}.old    ${new_log_data}
  Process Should Be Stopped	    ${process}

RHODS Operator Should Be Uninstalled
  Verify RHODS Uninstallation
  Log  RHODS has been uninstalled  console=yes

Uninstall RHODS In Self Managed Cluster Using CLI
  [Documentation]   UnInstall rhods on self-managedcluster using cli
  Clone OLM Install Repo
  #  ${return_code}    ${output}    Run And Return Rc And Output   cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t operator   #robocop:disable
  ${return_code}    Run and Watch Command    cd ${EXECDIR}/${OLM_DIR} && ./cleanup.sh -t operator    timeout_min=20
  Should Be Equal As Integers	${return_code}	 0   msg=Error detected while un-installing RHODS
  # Log To Console   ${output}

Uninstall RHODS In Self Managed Cluster For Operatorhub
  [Documentation]   Uninstall rhods on self-managed cluster for operatorhub installtion
  ${return_code}    ${output}    Run And Return Rc And Output   oc create configmap delete-self-managed-odh -n redhat-ods-operator
  Should Be Equal As Integers	${return_code}	 0   msg=Error creation deletion configmap
  ${return_code}    ${output}    Run And Return Rc And Output   oc label configmap/delete-self-managed-odh api.openshift.com/addon-managed-odh-delete=true -n redhat-ods-operator
  Should Be Equal As Integers	${return_code}	 0   msg=Error observed while adding label to configmap
  Verify Project Does Not Exists  redhat-ods-applications
  Verify Project Does Not Exists  redhat-ods-monitoring
  Verify Project Does Not Exists  rhods-notebooks
  ${return_code}    ${output}    Run And Return Rc And Output   oc delete namespace redhat-ods-operator
