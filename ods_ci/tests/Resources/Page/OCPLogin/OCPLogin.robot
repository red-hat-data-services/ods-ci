*** Keywords ***
Login To OCP
  Login To Openshift
  ...  ${OCP_ADMIN_USER.USERNAME}
  ...  ${OCP_ADMIN_USER.PASSWORD}  
  ...  ${OCP_ADMIN_USER.AUTH_TYPE}