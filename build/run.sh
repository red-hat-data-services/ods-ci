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
        echo "-----| SET_ENVIRONMENT option is enabled. ODS-CI is going to configure the test environment for you..|-----"
        ./install_idp.sh
  fi
fi
echo "-----| ODS-CI is start running the tests...|-----"
exit 0
./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}"


