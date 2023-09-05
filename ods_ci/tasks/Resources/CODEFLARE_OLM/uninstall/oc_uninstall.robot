*** Keywords ***
Verify CodeFlare Uninstallation
    Run Keyword And Expect Error  *Not Found*
    ...  Oc Get  kind=Subscription  namespace=openshift-operators
    ...      label_selector=app.kubernetes.io/name=codeflare-operator
    Verify Pod Does Not Exists  app.kubernetes.io/name=codeflare-operator

Verify Pod Does Not Exists
  [Arguments]  ${selector}
  Log  Checking pod with label selector: ${selector}
  ${pod_exists}=  Run Keyword and return status
  ...  Oc Get  kind=Pod  label_selector=${selector}
  IF  ${pod_exists}
  ...  Wait Until Pod Is Deleted  ${selector}  3600
  Log  Pod with label ${selector} deleted  console=yes

Wait Until Pod Is Deleted
  [Arguments]  ${selector}    ${timeout}
   FOR    ${counter}    IN RANGE    ${timeout}
        ${pod_exists}=  Run Keyword and return status
        ...  Oc Get  kind=Pod  label_selector=${selector}
        Exit For Loop If     not ${pod_exists}
   END
