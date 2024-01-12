#!/bin/bash
echo RUN SCRIPT ARGS: "${RUN_SCRIPT_ARGS}"
echo ROBOT EXTRA ARGS: "${ROBOT_EXTRA_ARGS}"
echo SET TEST ENVIRONMENT: "${SET_ENVIRONMENT}"
echo -- USE OCM to install IDPs: "${USE_OCM_IDP}"

# feature requested for MPS pipeline onboarding
if [ "${SET_ENVIRONMENT}" -eq 1 ]; then \
  if [ -z "${OC_HOST}" ]
      then
        echo -e "\033[0;33m You must set the OC_HOST env variable to automatically set the Test Environment for ODS-CI \033[0m"
        exit 0
      else
        if [ "${USE_OCM_IDP}" -eq 0 ]
          then
            actual_host="$(oc whoami --show-server)"
            if [ -z "${RUN_FROM_CONTAINER}" ]  && [ "${actual_host}" != "${OC_HOST}" ]
              then
                  echo "-----| USE_OCM_IDP option is disabled, but you are connected to a different cluster than ${OC_HOST}. To prevent you to change IDPs of the wrong cluster, ODS-CI stops here...|-----"
                  exit 0
            fi
        fi
        echo "-----| SET_ENVIRONMENT option is enabled. ODS-CI is going to configure the test environment for you..|-----"
        ./ods_ci/build/install_idp.sh
  fi
fi
echo "-----| ODS-CI is starting the tests run...|-----"
./ods_ci/run_robot_test.sh --skip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}"


