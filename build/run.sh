#!/bin/bash
echo run script args "${RUN_SCRIPT_ARGS}"
echo --extra-robot-args "${ROBOT_EXTRA_ARGS}"

if [ -n "${ROBOT_EXTRA_ARGS}" ]; then \
        ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS} --extra-robot-args "${ROBOT_EXTRA_ARGS}" ;\
else \
        ./run_robot_test.sh --skip-pip-install ${RUN_SCRIPT_ARGS};\
fi

