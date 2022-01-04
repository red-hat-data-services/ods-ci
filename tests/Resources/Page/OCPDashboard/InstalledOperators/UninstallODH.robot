*** Keywords ***
Open Installed Operators Page
  Login to OCP Console
  Switch To Administrator Perspective
  Navigate to Installed Operators
  Installed Operators Should Be Open


Navigate to Installed Operators
  Menu.Navigate To Page  Operators  Installed Operators

Installed Operators Should Be Open
  Page Should Be Open  ${OCP_CONSOLE_URL}/k8s/
  Wait until page contains           Managed Namespaces           timeout=10

Uninstall ODH Operator
  Uninstall Operator  Red Hat OpenShift Data Science

ODH Operator Should Be Uninstalled
  Operator Should Be Uninstalled  Red Hat OpenShift Data Science

Login to OCP Console
    Open OCP Console
    LoginPage.Login To Openshift  ${OCP_ADMIN_USER.USERNAME}  ${OCP_ADMIN_USER.PASSWORD}  ${OCP_ADMIN_USER.AUTH_TYPE}

