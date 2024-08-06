# Model Registry ODS-CI Testing
This README is intended to demonstrate how to run the Model Registry ODS-CI Robot Framework tests in a local environment.
## Requirements
Before proceeding please ensure you have read and followed this document [Robot Framework Installation](../../../../README.md)
## Local Deployment of Model Registry Secure DB Test
This test applies the SecuredDB version of model regisrty to an Istio/ODH/ModelMesh cluster.
To review and run it locally you will need the following:

- Have an existing openshift cluster with Red Hat Athorino, OpenDataHub and Red Hat Openshift Service Mesh operators installed.

- Be oc logged into to your cluster

- Install identity providers

  If your cluster wasn't installed from the QE Jenkins pipeline you will need to install the LDAP and HTPASSWD identity providers.

  Clone this git repository [https://gitlab.cee.redhat.com/ods/ods-install.git](https://gitlab.cee.redhat.com/ods/ods-install.git)

  From the root of the repository run this command
  ```bash
  ./odstest --install-identity-providers
  ```

- Create and prepare the test-variables.yml file by using the template file test-variables.yml.example file. The following will need to be set.

  OCP_CONSOLE_URL: "https://console-openshift-console.<YOUR_DOMAIN>.com/"
  
  ODH_DASHBOARD_URL: "https://odh-dashboard-opendatahub.<YOUR_DOMAIN>.com/"

  You can obtain your Domain by running this command

  ```bash
  oc get ingresses.config/cluster -o jsonpath='{.spec.domain}'
  ```

- run the following command from directory ods-ci/ods_ci 

  ```bash
  sh run_robot_test.sh --no-output-subfolder true --test-variable PRODUCT:ODH --test-variable APPLICATIONS_NAMESPACE:opendatahub --test-variable MONITORING_NAMESPACE:opendatahub --test-variable OPERATOR_NAMESPACE:openshift-operators --test-variable NOTEBOOKS_NAMESPACE:opendatahub --extra-robot-args '--variablefile test-variables-odh-overwrite.yml' --include MRMS1302 --skip-oclogin
  ```
