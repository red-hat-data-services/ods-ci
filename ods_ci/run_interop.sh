#!/bin/bash

export SET_ENVIRONMENT=1
export USE_OCM_IDP=0
export RUN_SCRIPT_ARGS="skip-oclogin true --set-urls-variables true"
export ROBOT_EXTRA_ARGS="-i Smoke --dryrun"

if [[ -z "${TEST_SUITE}" ]]; then
  echo "Error: TEST_SUITE not set. Please define it. Exiting.."
  exit 1
fi

if [[ -z "${ARTIFACT_DIR}" ]]; then
  echo "ARTIFACT_DIR is empty. Using  default value /tmp."
  ARTIFACT_DIR="/tmp"
fi

run_tests() {
  echo "Running $1 testing"
  
  TEST_CASE_FILE="tests/Tests"
  TEST_VARIABLES_FILE="test-variables.yml"
  TEST_SUITE=$1

  poetry run robot --include ${TEST_SUITE} --exclude "ExcludeOnRHOAI" --exclude "AutomationBug" --exclude "ProductBug" -d ${ARTIFACT_DIR}/${TEST_SUITE} -x xunit_test_result.xml -r test_report.html --variablefile ${TEST_VARIABLES_FILE} ${TEST_CASE_FILE} || true
}

if [[ ${TEST_SUITE} == "PostUpgrade" ]]; then
  echo "Retrieve test config file..."
  cp ${SHARED_DIR}/${TEST_VARIABLES_FILE} ${TEST_VARIABLES_FILE}
  run_tests ${TEST_SUITE} 
  
  echo "Running Smoke testing after upgrade"
  run_tests "Smoke"
  exit 0
fi

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
yq -i '.BROWSER.NAME="headlesschrome"' "${TEST_VARIABLES_FILE}"
yq -i '.S3.AWS_ACCESS_KEY_ID=env(AWS_ACCESS_KEY_ID)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.AWS_SECRET_ACCESS_KEY=env(AWS_SECRET_ACCESS_KEY)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_1.NAME=env(NAME_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_1.REGION=env(REGION_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_1.ENDPOINT=env(ENDPOINT_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_2.NAME=env(NAME_2)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_2.REGION=env(REGION_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_2.ENDPOINT=env(ENDPOINT_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_3.NAME=env(NAME_3)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_3.REGION=env(REGION_2)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_3.ENDPOINT=env(ENDPOINT_2)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_4.NAME=env(NAME_4)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_4.REGION=env(REGION_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_4.ENDPOINT=env(ENDPOINT_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_5.NAME=env(NAME_5)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_5.REGION=env(REGION_1)' "${TEST_VARIABLES_FILE}"
yq -i '.S3.BUCKET_5.ENDPOINT=env(ENDPOINT_1)' "${TEST_VARIABLES_FILE}"

echo "Wait for the IDP users to sync"
sleep 100

echo "Performing oc login with IDP user"
username=$(yq eval '.TEST_USER.USERNAME' "${TEST_VARIABLES_FILE}")
password=$(yq eval '.TEST_USER.PASSWORD' "${TEST_VARIABLES_FILE}")
oc login "$OC_HOST" --username "${username}" --password "${password}" --insecure-skip-tls-verify=true
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "The oc login command seems to have failed"
    echo "Please review the content of $TEST_VARIABLES_FILE"
    exit "$retVal"
fi

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

if [[ ${TEST_SUITE} == "PreUpgrade" ]]; then
  echo "Save test config file..."
  cp ${TEST_VARIABLES_FILE} ${SHARED_DIR}/${TEST_VARIABLES_FILE}
  run_tests ${TEST_SUITE}
  exit 0
else
  run_tests ${TEST_SUITE}
fi
