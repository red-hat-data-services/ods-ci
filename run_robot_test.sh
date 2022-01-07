#/bin/bash

TEST_CASE_FILE=tests/Tests
TEST_VARIABLES_FILE=test-variables.yml
TEST_VARIABLES=""
TEST_ARTIFACT_DIR="test-output"
EXTRA_ROBOT_ARGS=""
SKIP_PIP_INSTALL=0
TEST_INCLUDE_TAG=""
TEST_EXCLUDE_TAG=""

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

    # Specify included tags
    # Example: sanityANDinstall sanityORinstall installNOTsanity
    --include)
      shift
      TEST_INCLUDE_TAG="${TEST_INCLUDE_TAG} --include $1"
      shift
      ;;
    # Specify excluded tags
    --exclude)
      shift
      TEST_EXCLUDE_TAG="${TEST_EXCLUDE_TAG} --exclude $1"
      shift
      ;;
    # Additional arguments to pass to the robot cli
    --extra-robot-args)
      shift
      EXTRA_ROBOT_ARGS=$1
      shift
      ;;

    # Skip the pip install during the execution of this script
    --skip-pip-install)
      shift
      SKIP_PIP_INSTALL=1
      ;;

    *)
      echo "Unknown command line switch: $1"
      exit 1
      ;;
  esac
done

if [[ ! -f "${TEST_VARIABLES_FILE}" ]]; then
  echo "Robot Framework test variable file (${TEST_VARIABLES_FILE}) is missing"
  exit 1
fi

currentpath=`pwd`
case "$(uname -s)" in
    Darwin)
         echo "INFO: MACOS"
         echo "INFO: setting driver  to $currentpath/Drivers/MACOS"
         PATH=$PATH:$currentpath/drivers/MACOS
         export PATH=$PATH

         ;;
    Linux)
       case "$(lsb_release --id --short)" in
       "Fedora"|"CentOS")
             ## Bootstrap script to setup drivers ##
             echo "INFO: setting driver  to $currentpath/Drivers/fedora"
             PATH=$PATH:$currentpath/drivers/fedora
             export PATH=$PATH

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
        ;;
      * )
          echo "Not yet supported OS, but shouldn't be hard for you to fix :) "
          echo "Please add the driver, test and submit PR"
          exit 1
        ;;
esac

## if we have yq installed
if command -v yq &> /dev/null
then
    echo "INFO: we found a yq executable"

    ## get the user, pass and API hostname for OpenShift
    oc_user=$(yq  e '.OCP_ADMIN_USER.USERNAME' ${TEST_VARIABLES_FILE})
    oc_pass=$(yq  e '.OCP_ADMIN_USER.PASSWORD' ${TEST_VARIABLES_FILE})
    oc_host=$(yq  e '.OCP_API_URL' ${TEST_VARIABLES_FILE})

    ## do an oc login here
    oc login "${oc_host}" --username "${oc_user}" --password "${oc_pass}" --insecure-skip-tls-verify=true

    ## no point in going further if the login is not working
    retVal=$?
    if [ $retVal -ne 0 ]; then
        echo "The oc login command seems to have failed"
        echo "Please review the content of ${TEST_VARIABLES_FILE}"
        exit $retVal
    fi
    oc cluster-info
    printf "\nconnected as openshift user ' $(oc whoami) '\n"
    echo "since the oc login was successful, continuing."
else
    echo "we did not find yq, so not trying the oc login"
fi


#TODO: Make this optional so we are not creating/updating the virtualenv everytime we run a test
VENV_ROOT=${currentpath}/venv


#setup virtualenv, but only if necessary.
if [ -d "${VENV_ROOT}" ]
then
    echo "Directory ${VENV_ROOT} exists. No need to create v-env"
else
    echo "Directory ${VENV_ROOT} does not exist. running the venv command"
    python3 -m venv ${VENV_ROOT}
fi

source ${VENV_ROOT}/bin/activate

if [[ ${SKIP_PIP_INSTALL} -eq 0 ]]; then
  ${VENV_ROOT}/bin/pip install -r requirements.txt
fi

#Create a unique directory to store the output for current test run
if [[ ! -d "${TEST_ARTIFACT_DIR}" ]]; then
  mkdir ${TEST_ARTIFACT_DIR}
fi
case "$(uname -s)" in
    Darwin)
        TEST_ARTIFACT_DIR=$(mktemp -d  ${TEST_ARTIFACT_DIR} -t ${TEST_ARTIFACT_DIR}/ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
         ;;
    Linux)
        TEST_ARTIFACT_DIR=$(mktemp -d -p ${TEST_ARTIFACT_DIR} -t ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
        ;;
esac

chmod 755 ${TEST_ARTIFACT_DIR}

./venv/bin/robot ${TEST_EXCLUDE_TAG} ${TEST_INCLUDE_TAG} -d ${TEST_ARTIFACT_DIR} -x xunit_test_result.xml -r test_report.html ${TEST_VARIABLES} --variablefile ${TEST_VARIABLES_FILE} --exclude TBC ${EXTRA_ROBOT_ARGS} ${TEST_CASE_FILE}

## make the directory easy to read
chmod  644 ${TEST_ARTIFACT_DIR}/*
