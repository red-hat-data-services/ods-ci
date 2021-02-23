#/bin/bash

PYTHON=${PYTHON:-"python3"}
VENV=${VENV:-"virtualenv"}

echo $CONSOLE_URL
echo $KUBEADMIN

if [[ -z "${CONSOLE_URL}" || -z "${KUBEADMIN}" || -z "${KUBEPWD}" ]]; then
  echo "CONSOLE_URL/KUBEADMIN/KUBEPWD environment variable should be set before running the scripts"
  exit 2
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

VENV_ROOT=${currentpath}/venv
#setup virtualenv
python3 -m venv ${VENV_ROOT}
source ${VENV_ROOT}/bin/activate
${VENV_ROOT}/bin/pip install -r requirements.txt

#run tests
tmp_dir=$(mktemp -d -t ods-ci-$(date +%Y-%m-%d-%H-%M)-XXXXXXXXXX)
mkdir $tmp_dir
./venv/bin/robot -d $tmp_dir -x xunit_test_result.xml -r test_report.html --variable CONSOLE_URL=$CONSOLE_URL --variable KUBEADMIN=$KUBEADMIN --variable KUBEPASSWD=$KUBEPWD tests/Tests/test.robot

esac
