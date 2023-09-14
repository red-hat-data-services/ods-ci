*** Settings ***
Documentation    RHODS CodeFlare operator uninstallation keywords
Resource   ../install/oc_install.robot
Resource   ../../../../tests/Resources/Common.robot
Resource   ../../../../tests/Resources/Page/Operators/ISVs.resource
Resource   oc_uninstall.robot

Library    Process


*** Keywords ***
Uninstalling CodeFlare Operator
    [Documentation]   Uninstalls the RHODS CodeFlare operator if it is installed
    ${is_operator_installed} =  Is CodeFlare Installed
    IF  ${is_operator_installed}
        Log  Uninstalling CodeFlare operator in ${cluster_type}  console=yes
        Uninstall CodeFlare
    END

Uninstall CodeFlare
    [Documentation]   Removes the RHODS CodeFlare operator subscription and CSV
    # needs to be deleted first to avoid getting stuck on CodeFlare finalizer
    ${return_code}    ${output}    Run And Return Rc And Output
    ...    oc delete mcads.codeflare.codeflare.dev mcad -n redhat-ods-applications --ignore-not-found
    Should Be Equal As Integers	${return_code}	 0   msg=Error deleting CodeFlare MCAD CR
    Uninstall ISV Operator From OperatorHub Via CLI     rhods-codeflare-operator    openshift-operators

CodeFlare Operator Should Be Uninstalled
    [Documentation]   Verifies and logs that the RHODS CodeFlare operator is uninstalled
    Verify CodeFlare Uninstallation
    Log  CodeFlare has been uninstalled  console=yes

Verify CodeFlare Uninstallation
    [Documentation]   Verifies that the RHODS CodeFlare operator is uninstalled
    Run Keyword And Expect Error  *Not Found*
    ...  Oc Get  kind=Subscription  namespace=openshift-operators
    ...  label_selector=app.kubernetes.io/name=codeflare-operator
    Verify Pod Does Not Exists  app.kubernetes.io/name=codeflare-operator

Verify Pod Does Not Exists
    [Documentation]   Verifies that a Pod with a label matching given selector does not exist
    [Arguments]  ${selector}
    Log  Checking pod with label selector: ${selector}
    ${pod_exists} =  Run Keyword and return status
    ...  Oc Get  kind=Pod  label_selector=${selector}
    IF  ${pod_exists}   Wait Until Pod Is Deleted  ${selector}  3600
    Log  Pod with label ${selector} deleted  console=yes

Wait Until Pod Is Deleted
    [Documentation]   Waits until the pod with a label matching given selector is deleted
    [Arguments]  ${selector}    ${timeout}
    FOR   ${counter}    IN RANGE    ${timeout}
          ${pod_exists} =  Run Keyword and return status
          ...  Oc Get  kind=Pod  label_selector=${selector}
          Exit For Loop If     not ${pod_exists}
    END
    IF  ${pod_exists}
    ...  Fail    Pod matching ${selector} has not been deleted after ${timeout} attempts!
