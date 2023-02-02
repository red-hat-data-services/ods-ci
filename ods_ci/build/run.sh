#!/bin/bash
echo RUN SCRIPT ARGS: "${RUN_SCRIPT_ARGS}"
echo ROBOT EXTRA ARGS: "${ROBOT_EXTRA_ARGS}"

if [ -n "${ROBOT_EXTRA_ARGS}" ]; then \
        ./ods_ci/run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}" ;\
else \
        ./ods_ci/run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS};\
fi

