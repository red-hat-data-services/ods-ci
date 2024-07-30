# Model Registry ODS-CI Testing
This README is intended to demonstrate how to run the Model Registry ODS-CI Robot Framework tests in a local environment.
## Requirements
Before proceeding please ensure you have read and followed this document [Link Text](../../../../README.md)
## Local Deployment of Model Registry Secure DB Test
This test applies the SecuredDB version of model regisrty to an Istio/ODH/ModelMesh cluster.
To review and run it locally you will need the following:

- Have an existing openshift cluster with Red Hat Athorino, OpenDataHub and Red Hat Openshift Service Mesh operators installed.

- Be oc logged into to your cluster

- Create and prepare the test-variables.yml file by using the template file test-variables.yml.example file. The following will need to be set.

  OCP_CONSOLE_URL: "https://console-openshift-console.<YOUR_DOMAIN>.com/"
  
  ODH_DASHBOARD_URL: "https://odh-dashboard-opendatahub.<YOUR_DOMAIN>.com/"

- Set the following local files
  
  ods_ci/run_robot_test.sh  line 25 SUBFOLDER to be set to true.

  ods_ci/tests/Tests/1300__model_registry/1302_model_registry_model_serving.robot.  In the test case [Tags] (line 45), leave 4 spaces after OpenDataHub and put **_<YOUR_NAME>_** as a local tag to be picked up by the run command.

- run the following command from directory ods-ci/ods_ci 

  ```bash
  run_robot_test.sh --test-variable PRODUCT:ODH --test-variable APPLICATIONS_NAMESPACE:opendatahub --test-variable MONITORING_NAMESPACE:opendatahub --test-variable OPERATOR_NAMESPACE:openshift-operators --test-variable NOTEBOOKS_NAMESPACE:opendatahub --extra-robot-args '--variablefile test-variables-odh-overwrite.yml' --include <YOUR_NAME> --skip-oclogin
  ```
