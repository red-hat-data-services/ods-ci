*** Keywords ***
Uninstalling DataScienceCluster
  Run Keywords
  ...  Log  Uninstalling DataScienceCluster  console=yes  AND
  ...  Uninstall DataScienceCluster

DataScienceCluster Should Be Uninstalled
  Verify DataScienceCluster Uninstallation
  Log  DataScienceCluster has been uninstalled  console=yes

Uninstall DataScienceCluster
  Oc Delete  kind=DataScienceCluster
  ...        name=default
  ...        namespace=default
  Log  DataScienceCluster deleted

Verify DataScienceCluster Uninstallation
  Run Keyword And Expect Error  *Not Found*
  ...  Oc Get  kind=DataScienceCluster  namespace=default
  ...       field_selector=metadata.name=default
