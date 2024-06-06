#!/bin/bash

SKIP_OC_LOGIN=false
SERVICE_ACCOUNT=""
SA_NAMESPACE="default"
SET_RHODS_URLS=false
TEST_CASE_FILE=ods_ci/tests/Tests
TEST_VARIABLES_FILE=ods_ci/test-variables.yml
TEST_VARIABLES=""
TEST_ARTIFACT_DIR="ods_ci/test-output"
EXTRA_ROBOT_ARGS=""
SKIP_INSTALL=0
TEST_INCLUDE_TAG=""
TEST_EXCLUDE_TAG=""
EMAIL_REPORT=false
EMAIL_TO=""
EMAIL_FROM=""
EMAIL_SERVER="localhost"
EMAIL_SERVER_USER="None"
EMAIL_SERVER_PW="None"
EMAIL_SERVER_SSL=false
EMAIL_SERVER_UNSECURE=false
OPEN_REPORT_IN_BROWSER=false
REPORT_BROWSER="firefox" # Default browser to open reports in
SUBFOLDER=false

currentpath=$(pwd)
readonly currentpath

basepath=$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")
readonly basepath

# Please keep this in sync with ./docs/RUN_ARGUMENTS.md file.
while [ "$#" -gt 0 ]; do
  case $1 in
    --skip-oclogin)
      shift
      SKIP_OC_LOGIN=$1
      shift
      ;;

    --service-account)
      shift
      SERVICE_ACCOUNT=$1
      shift
      ;;

    --sa-namespace)
      shift
      SA_NAMESPACE=$1
      shift
      ;;

    # Override/Add global variables specified in the test variables file
    --test-variable)
      shift
      TEST_VARIABLES="${TEST_VARIABLES} --variable $1"
      shift
      ;;

    --set-urls-variables)
      shift
      SET_RHODS_URLS=$1
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

    # Skip the dependency install during the execution of this script
    --skip-install)
      shift
      SKIP_INSTALL=1
      ;;

    --email-report)
      shift
      EMAIL_REPORT=$1
      shift
      ;;

    --email-from)
      shift
      EMAIL_FROM=$1
      shift
      ;;

    --email-to)
      shift
      EMAIL_TO=$1
      shift
      ;;

   --email-server)
      shift
      EMAIL_SERVER=$1
      shift
      ;;

   --email-server-user)
      shift
      EMAIL_SERVER_USER=$1
      shift
      ;;

   --email-server-pw)
      shift
      EMAIL_SERVER_PW=$1
      shift
      ;;

    --email-server-ssl)
      shift
      EMAIL_SERVER_SSL=$1
      shift
      ;;

    --email-server-unsecure)
      shift
      EMAIL_SERVER_UNSECURE=$1
      shift
      ;;

    # place test results in a timestamped subfolder or not
    # true: no subfolder, false: subfolder
    --no-output-subfolder)
      shift
      SUBFOLDER=$1
      shift
      ;;

    # If not `false`, then it opens reports in local browser after the tests run.
    # If `true`, then default browser `REPORT_BROWSER` is used.
    # You can override the default browser by specifying your own command as a value (e.g.: `--open-report nautilus`).
    --open-report)
      shift
      OPEN_REPORT_IN_BROWSER="${1}"
      shift
      ;;

    *)
      echo "Unknown command line switch: $1"
      exit 1
      ;;
  esac
done

if ${EMAIL_REPORT}
    then
      echo "Email Report is enabled"
      if [ -z "${EMAIL_FROM}" ] || [ -z "${EMAIL_TO}" ]
        then
          echo "--email-from and/or --email-to is missing. Please, set them or disable --email-report"
          exit 1
      fi
      echo "Test Execution results will be sent to ${EMAIL_TO} from ${EMAIL_FROM}"
fi
echo "${TEST_VARIABLES_FILE}"
if [[ ! -f "${TEST_VARIABLES_FILE}" ]]; then
  echo "Robot Framework test variable file (test-variables.yml) is missing"
  exit 1
fi

case "$(uname -s)" in
    Darwin)
         echo "MACOS"
         echo "setting driver  to $currentpath/Drivers/MACOS"
         PATH=$PATH:$currentpath/drivers/MACOS
         export PATH=$PATH
         echo "$PATH"
         ;;
    Linux)
       case "$(distro -j | jq '.id')" in
       "fedora"|"centos")
             ## Bootstrap script to setup drivers ##
             echo "setting driver  to $currentpath/Drivers/fedora"
             PATH=$PATH:$currentpath/drivers/fedora
             export PATH=$PATH
             echo "$PATH"
        ;;
        "ubuntu")
             echo "Ubuntu"
             echo "setting driver  to $currentpath/drivers/ubuntu"
             PATH=$PATH:$currentpath/drivers/ubuntu
             export PATH=$PATH
             echo "$PATH"
        ;;
        "opensuse project"|"suse linux"|"opensuse")
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


# automatically get cluster URLs if already log into or running in a pod
if ${SET_RHODS_URLS}
    then
        echo "INFO: getting RHODS URLs from the cluster as per --set-urls-variables"
        ocp_console=$(oc whoami --show-console)
        # ocp_console="https://$(oc get route console -n openshift-console -o jsonpath='{.spec.host}{"\n"}')"
        rhods_dashboard="https://$(oc get route rhods-dashboard -n redhat-ods-applications -o jsonpath='{.spec.host}{"\n"}')"
        api_server=$(oc whoami --show-server)
        prom_server="https://$(oc get route prometheus -n redhat-ods-monitoring -o jsonpath='{.spec.host}{"\n"}')"
        prom_token="$(oc create token prometheus -n redhat-ods-monitoring --duration 6h)"
        TEST_VARIABLES="${TEST_VARIABLES} --variable OCP_CONSOLE_URL:${ocp_console} --variable ODH_DASHBOARD_URL:${rhods_dashboard} --variable RHODS_PROMETHEUS_URL:${prom_server} --variable RHODS_PROMETHEUS_TOKEN:${prom_token}"
        echo "OCP Console URL set to: ${ocp_console}"
        echo "RHODS Dashboard URL set to: ${rhods_dashboard}"
        echo "RHODS API Server URL set to: ${api_server}"
        echo "RHODS Prometheus URL set to: ${prom_server}"
fi

## if we have yq installed
if command -v yq &> /dev/null
    then
        echo "INFO: we found a yq executable"
        if ! ${SKIP_OC_LOGIN}
            then
                echo "INFO: OC Login enabled"

                ## get the user, pass and API hostname for OpenShift
                if ${SET_RHODS_URLS}
                    then
                        oc_host=${api_server}
                    else
                        oc_host=$(yq -er '.OCP_API_URL' "${TEST_VARIABLES_FILE}") || {
                            echo "Couldn't find '.OCP_API_URL' variable in provided '${TEST_VARIABLES_FILE}'."
                            echo "Please either provide it or use '--skip-oclogin true' (don't forget to login to the testing cluster manually then)."
                            exit 1
                        }
                fi


                if [ -z "${SERVICE_ACCOUNT}" ]
                    then
                        echo "Performing oc login using username and password"
                        oc_user=$(yq -er '.OCP_ADMIN_USER.USERNAME' "${TEST_VARIABLES_FILE}") || {
                            echo "Couldn't find '.OCP_ADMIN_USER.USERNAME' variable in provided '${TEST_VARIABLES_FILE}'."
                            echo "Please either provide it or use '--skip-oclogin true' (don't forget to login to the testing cluster manually then)."
                            exit 1
                        }
                        oc_pass=$(yq -er '.OCP_ADMIN_USER.PASSWORD' "${TEST_VARIABLES_FILE}") || {
                            echo "Couldn't find '.OCP_ADMIN_USER.PASSWORD' variable in provided '${TEST_VARIABLES_FILE}'."
                            echo "Please either provide it or use '--skip-oclogin true' (don't forget to login to the testing cluster manually then)."
                            exit 1
                        }
                        oc login "${oc_host}" --username "${oc_user}" --password "${oc_pass}" --insecure-skip-tls-verify=true
                        retVal=$?
                    else
                        echo "Performing oc login using service account"
                        sa_token=$(oc create token "${SERVICE_ACCOUNT}" -n "${SA_NAMESPACE}" --duration 6h)
                        oc login --token="$sa_token" --server="${oc_host}" --insecure-skip-tls-verify=true
                        retVal=$?
                        sa_fullname=$(oc whoami)
                        TEST_VARIABLES="${TEST_VARIABLES} --variable SERVICE_ACCOUNT.NAME:${SERVICE_ACCOUNT} --variable SERVICE_ACCOUNT.FULL_NAME:${sa_fullname}"

                fi

                ## no point in going further if the login is not working
                if [ $retVal -ne 0 ]; then
                    echo "The oc login command seems to have failed"
                    echo "Please review the content of ${TEST_VARIABLES_FILE}"
                    exit "${retVal}"
                fi

                oc cluster-info
                printf "\nconnected as openshift user ' %s '\n" "$(oc whoami)"
                echo "since the oc login was successful, continuing."
            else
                echo "skipping OC login as per parameter --skip-oclogin"
        fi
    else
        echo "we did not find yq, so not trying the oc login"
fi

if [[ ${SKIP_INSTALL} -eq 0 ]]; then
  # look for pre-created poetry .venv
  virtenv="${HOME}/.local/ods-ci/.venv"
  if [[ -d "${virtenv}" ]]; then
    echo "Using a pre-created virtual environment in '${virtenv}' for poetry to save time."
    poetry config --local virtualenvs.in-project true
    ln --symbolic "${virtenv}" "${basepath}/../.venv"
  else
    echo "Pre-created virtual environment has not been found in '${virtenv}'. All dependencies will be installed from scratch."
  fi
  # ensure python 3.11
  python=$(poetry env info --executable)
  if [[ -n "${python}" ]] && ${python} -c 'import sys; sys.exit(0 if sys.version_info[0:2] == (3, 11) else 1)'; then
    echo "Python '${python}' will be used"
  else
    echo "Python '${python}' is not of the correct version"
    python311=$(which python3.11)
    if [[ -n "${python311}" ]]; then
      echo "Configuring poetry to use Python ${python311}"
      poetry env use "${python311}"
    else
      echo "[ERROR] Python 3.11 was not found!"
      echo "Install Python 3.11 on your machine. On Fedora, do 'sudo dnf install -y python3.11-devel'"
      echo "then run 'poetry env use /path/to/python3.11' and then try running robot again"
      exit 1
    fi
  fi

  poetry install --no-interaction --sync || {
      echo "[ERROR] poetry environment setup failed, aborting the execution!"
      exit 1
  }
fi
# shellcheck disable=SC1091
source "$(poetry env info --path)/bin/activate"

#Create a unique directory to store the output for current test run
if [[ ! -d "${TEST_ARTIFACT_DIR}" ]]; then
  mkdir -p "${TEST_ARTIFACT_DIR}"
fi
if ! ${SUBFOLDER}; then
  case "$(uname -s)" in
    Darwin)
        # shellcheck disable=SC2046
        TEST_ARTIFACT_DIR=$(mktemp -d  "${TEST_ARTIFACT_DIR}" -t "${TEST_ARTIFACT_DIR}"/ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
         ;;
    Linux)
        # shellcheck disable=SC2046
        TEST_ARTIFACT_DIR=$(mktemp -d -p "${TEST_ARTIFACT_DIR}" -t ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
        ;;
  esac
fi


robot ${TEST_EXCLUDE_TAG} ${TEST_INCLUDE_TAG} -d ${TEST_ARTIFACT_DIR} -x xunit_test_result.xml -r test_report.html ${TEST_VARIABLES} --variablefile ${TEST_VARIABLES_FILE} --exclude TBC ${EXTRA_ROBOT_ARGS} ${TEST_CASE_FILE}
# shellcheck disable=SC2116
exit_status=$(echo $?)
echo "${exit_status}"

# send test artifacts by email
if ${EMAIL_REPORT}
  then
     tar cvzf rf_results.tar.gz "${TEST_ARTIFACT_DIR}" &> /dev/null
     size=$(du -k rf_results.tar.gz | cut -f1)
     if [ "${size}" -gt 20000 ]
        then
            echo "Test results artifacts are too large for email"
            rm rf_results.tar.gz
            tar cvzf rf_results.tar.gz $(find "${TEST_ARTIFACT_DIR}" -regex  '.*\(xml\|html\)$') &> /dev/null
     fi
     poetry run python3 ods_ci/utils/scripts/Sender/send_report.py send_email_report -s "${EMAIL_FROM}" -r "${EMAIL_TO}" -b "ODS-CI: Run Results" \
                        -v "${EMAIL_SERVER}" -a "rf_results.tar.gz" -u "${EMAIL_SERVER_USER}" -p "${EMAIL_SERVER_PW}" \
                        -l "${EMAIL_SERVER_SSL}" -d "${EMAIL_SERVER_UNSECURE}"
fi


if test "${OPEN_REPORT_IN_BROWSER}" != "false"
  then
    if test "${OPEN_REPORT_IN_BROWSER}" != "true"
      then
        REPORT_BROWSER="${OPEN_REPORT_IN_BROWSER}"
    fi

    ${REPORT_BROWSER} "${TEST_ARTIFACT_DIR}" &
fi

deactivate
exit "${exit_status}"
