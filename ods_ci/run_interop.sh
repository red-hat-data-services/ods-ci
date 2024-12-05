TEST_CASE_FILE=tests/Tests
TEST_VARIABLES_FILE=test-variables.yml

echo "Install IDP users and map them to test config file"
./build/install_idp_interop.sh

if [[ -z "${TEST_SUITE}" ]]; then
  echo "Define TEST_SUITE"
  exit 1
fi

if [[ -z "${ARTIFACT_DIR}" ]]; then
  echo "Define ARTIFACT_DIR"
  ARTIFACT_DIR=/tmp
fi

poetry run robot --include $TEST_SUITE -d ${ARTIFACT_DIR} -x xunit_test_result.xml -r test_report.html --variablefile ${TEST_VARIABLES_FILE} ${TEST_CASE_FILE}