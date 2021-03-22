*** Keywords ***
Open Installed Operators
  Open OCP Console 
  Login To OCP
  Navigate to Installed Operators
  Installed Operators Should Be Open

Navigate to Installed Operators
  Navigate To Page  Operators  Installed Operators

Installed Operators Should Be Open
  Page Should Be Open  ${OCP_CONSOLE_URL}k8s/

Uninstall ODH Operator
  Uninstall Operator  Red Hat OpenShift Data Science

ODH Operator Should Be Uninstalled
  Operator Should Be Uninstalled  Red Hat OpenShift Data Science