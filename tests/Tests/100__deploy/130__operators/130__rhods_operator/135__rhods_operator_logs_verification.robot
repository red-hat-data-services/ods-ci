*** Settings ***
Documentation   135 - RHODS_OPERATOR_LOGS_VERIFICATION
...             Verify that rhods operator log is clean and doesn't contain any error regarding resource kind
...
...             = Variables =
...             | Namespace                | Required |        RHODS Namespace/Project for RHODS operator POD |
...             | REGEX_PATTERN            | Required |        Regular Expression Pattern to match the erro msg in capture log|

Library        Collections
Library        OpenShiftCLI
Library        OperatingSystem
Library        String

*** Variables ***
${namespace}           redhat-ods-operator
${regex_pattern}       level=([Ee]rror).*

*** Test Cases ***
Verify RHODS Operator log
   [Tags]  ODS-1007   Sanity
   #Get the POD name
   ${data}       Run keyword   OpenShiftCLI.Get   kind=Pod     namespace=${namespace}   label_selector=name=rhods-operator
   #Capture the logs based on containers
   ${val}        Run   oc logs --tail=1000000 ${data[0]['metadata']['name']} -n ${namespace} -c rhods-operator
   #To check if command has been suessfully executed and the logs has been captured
   Run Keyword IF    len($val)==${0} or "error:" in $val     FAIL   Either OC command has not been executed sucessfully or Logs is not present
   #Filter the error msg from the log captured
   ${match_list} 	 Get Regexp Matches   ${val}     ${regex_pattern}
   #Remove if any duplicate entry are present
   ${entry_msg}      Remove Duplicates      ${match_list}
   ${length}         Get Length   ${entry_msg}
   #Verify if captured logs has any error entry if yes fail the TC
   Run Keyword If   ${length} != ${0}    FAIL    There are some error entry present in opeartor logs '${entry_msg}'
   ...       ELSE   Log   Operator log looks clean