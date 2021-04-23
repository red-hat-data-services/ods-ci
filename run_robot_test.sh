#/bin/bash

TEST_CASE_FILE=tests/Tests/test.robot
TEST_VARIABLES_FILE=test-variables.yml
TEST_VARIABLES=""
TEST_ARTIFACT_DIR="test-output"
EXTRA_ROBOT_ARGS=""

while [ "$#" -gt 0 ]; do
  case $1 in
    # Override/Add global variables specified in the test variables file
    --test-variable)
      shift
      TEST_VARIABLES="${TEST_VARIABLES} --variable $1"
      shift
      ;;

    # Specify the test variable file
    --test-variables-file)
      shift
      TEST_VARIABLES_FILE=$1
      shift
      ;;

    # Specify test case to run
    --test-case)
      shift
      TEST_CASE_FILE=$1
      shift
      ;;

    # Specify directory to store artifacts and reports from each test run
    --test-artifact-dir)
      shift
      TEST_ARTIFACT_DIR=$1
      shift
      ;;

    # Additional arguments to pass to the robot cli
    --extra-robot-args)
      shift
      EXTRA_ROBOT_ARGS=$1
      shift
      ;;

    *)
      echo "Unknown command line switch: $1"
      exit 1
      ;;
  esac
done

if [[ ! -f "${TEST_VARIABLES_FILE}" ]]; then
  echo "Robot Framework test variable file (test-variables.yml) is missing"
  exit 1
fi

currentpath=`pwd`
case "$(uname -s)" in
Linux)
   case "$(lsb_release --id --short)" in
   "Fedora"|"CentOS")
         ## Bootstrap script to setup drivers ##
         echo "setting driver  to $currentpath/Drivers/fedora"
         PATH=$PATH:$currentpath/drivers/fedora
         export PATH=$PATH
         echo $PATH
    ;;
    "Ubuntu")
         echo "Not yet supported, but shouldn't be hard for you to fix :) "
         echo "Please add the driver, test and submit PR"
         exit 1
    ;;
    "openSUSE project"|"SUSE LINUX"|"openSUSE")
         echo "Not yet supported, but shouldn't be hard for you to fix :) "
         echo "Please add the driver, test and submit PR"
         exit 1
    ;;
    esac

#TODO: Make this optional so we are not creating/updating the virtualenv everytime we run a test
VENV_ROOT=${currentpath}/venv
#setup virtualenv
python3 -m venv ${VENV_ROOT}
source ${VENV_ROOT}/bin/activate
${VENV_ROOT}/bin/pip install -r requirements.txt

#Create a unique directory to store the output for current test run
if [[ ! -d "${TEST_ARTIFACT_DIR}" ]]; then
  mkdir ${TEST_ARTIFACT_DIR}
fi

#TODO: Configure the "tmp_dir" creation so that we can have a "latest" link
TEST_ARTIFACT_DIR=$(mktemp -d -p ${TEST_ARTIFACT_DIR} -t ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)

#run tests
./venv/bin/robot -d ${TEST_ARTIFACT_DIR} -x xunit_test_result.xml -r test_report.html ${TEST_VARIABLES} --variablefile ${TEST_VARIABLES_FILE} ${TEST_CASE_FILE} ${EXTRA_ROBOT_ARGS}

esac
