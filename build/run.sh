#!/bin/bash
echo RUN SCRIPT ARGS: "${RUN_SCRIPT_ARGS}"
echo ROBOT EXTRA ARGS: "${ROBOT_EXTRA_ARGS}"
echo SET TEST ENVIRONMENT: "${SET_ENVIRONMENT}"

# feature requested for MPS pipeline onboarding
if [ "${SET_ENVIRONMENT}" -eq 1 ]; then \
  if [ -z "${OC_HOST}" ]
      then
        echo -e "\033[0;33m You must set the OC_HOST env variable to automatically set the Test Environment for ODS-CI \033[0m"
        exit 0
      else
        echo "-----| SET_ENVIRONMENT option is enabled. ODS-CI is going to configure the test environment for you..|-----\n"
        oc_host_no_port=$(echo $OC_HOST | sed 's/:[0-9]\+//g')
        export RHODS_URL=${oc_host_no_port//api/rhods-dashboard-redhat-ods-applications}
        export OCP_CONSOLE_URL=${oc_host_no_port//api/console-openshift-console}
        ./install_idp.sh
        yq --inplace '.OCP_CONSOLE_URL=env(OCP_CONSOLE_URL)' test-variables.yml
        yq --inplace '.ODH_DASHBOARD_URL=env(RHODS_URL)' test-variables.yml
        yq --inplace '.OCP_API_URL=env(OC_HOST)' test-variables.yml
  fi
fi
echo "-----| ODS-CI is start running the tests...|-----\n"
exit 0
./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}"


