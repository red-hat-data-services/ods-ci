#/bin/bash

if [[ ! -f "test-variables.yml" ]]; then
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

#run tests

#TODO: Make the tmpdir name unique when run <1min after previous run
tmp_dir=$(mktemp -d -t ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
#TODO: Configure the "tmp_dir" creation so that we can have a "latest" link
mkdir $tmp_dir
./venv/bin/robot -d $tmp_dir -x xunit_test_result.xml -r test_report.html --variablefile test-variables.yml tests/Tests/test.robot

esac
