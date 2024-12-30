#!/bin/bash

export SET_ENVIRONMENT=1
export USE_OCM_IDP=0
export RUN_SCRIPT_ARGS="skip-oclogin true --set-urls-variables true"
export ROBOT_EXTRA_ARGS="-i Smoke --dryrun"

TEST_CASE_FILE="tests/Tests"
TEST_VARIABLES_FILE="test-variables.yml"

oc_wait_for_pods() {
    local ns="${1}"
    local pods

    for i in {1..60}; do
        echo "Waiting for pods in '${ns}' in state Running or Completed"
        pods=$(oc get pod -n "${ns}" | grep -v "Running\|Completed" | tail -n +2)
        echo "${pods}"
        if [[ -z "${pods}" ]]; then
            echo "All pods in '${ns}' are in state Running or Completed"
            break
        fi
        sleep 20
    done
    if [[ -n "${pods}" ]]; then
        echo "ERROR: Some pods in '${ns}' are not in state Running or Completed"
        echo "${pods}"
        exit 1
    fi
}

echo "Install IDP users and map them to test config file"
./build/install_idp.sh

echo "Update test config file..."
AWS_SHARED_CREDENTIALS_FILE="${CLUSTER_PROFILE_DIR}/.awscred"
AWS_ACCESS_KEY_ID=$(cat $AWS_SHARED_CREDENTIALS_FILE | grep aws_access_key_id | tr -d ' ' | cut -d '=' -f 2)
AWS_SECRET_ACCESS_KEY=$(cat $AWS_SHARED_CREDENTIALS_FILE | grep aws_secret_access_key | tr -d ' ' | cut -d '=' -f 2)
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY

yq -i '.OCP_API_URL=env(OC_HOST)' "${TEST_VARIABLES_FILE}"
yq -i '.OCP_CONSOLE_URL=env(OCP_CONSOLE)' "${TEST_VARIABLES_FILE}"
yq -i '.ODH_DASHBOARD_URL=env(RHODS_DASHBOARD)' "${TEST_VARIABLES_FILE}"
yq -i '.BROWSER.NAME="firefox"' "${TEST_VARIABLES_FILE}"
yq -i '.S3.AWS_ACCESS_KEY_ID=env(AWS_ACCESS_KEY_ID)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.AWS_SECRET_ACCESS_KEY=env(AWS_SECRET_ACCESS_KEY)' "${TEST_VARIABLES_FILE}"
# TODO: Consume S3 endpoint URL from test-variables file?

echo "Performing oc login with cluster admin"
username=$(yq eval '.OCP_ADMIN_USER.USERNAME' "${TEST_VARIABLES_FILE}")
password=$(yq eval '.OCP_ADMIN_USER.PASSWORD' "${TEST_VARIABLES_FILE}")
oc login "$OC_HOST" --username "${username}" --password "${password}" --insecure-skip-tls-verify=true
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "The oc login command seems to have failed"
    echo "Please review the content of $TEST_VARIABLES_FILE"
    exit "$retVal"
fi

if [[ -z "${TEST_SUITE}" ]]; then
  echo "Define TEST_SUITE"
  exit 1
fi

if [[ -z "${ARTIFACT_DIR}" ]]; then
  echo "Define ARTIFACT_DIR"
  ARTIFACT_DIR="/tmp"
fi

# Wait for operator pods to be up and running
oc_wait_for_pods "redhat-ods-applications"

poetry run robot --include ${TEST_SUITE} \
                  --exclude "AutomationBug" \
                  --exclude "ProductBug" \
                  --exclude "ExcludeOnRHOAI" \
                  --exclude "Resources-*" \
                  -d ${ARTIFACT_DIR} \
                  -x xunit_test_result.xml \
                  -r test_report.html \
                  --variablefile ${TEST_VARIABLES_FILE} ${TEST_CASE_FILE}
