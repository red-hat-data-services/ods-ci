#!/bin/bash

PROVIDER_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
TEST_VARIABLES_FILE="test-variables.yml"

HTTP_USER_PREFIX="http-interop-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4)"
LDAP_USER_PREFIX="ldap-interop-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4)"
HTTP_USER_ADMIN=$HTTP_USER_PREFIX-"admin"
HTTP_USER_USER=$HTTP_USER_PREFIX-"user"
HTTP_USER_NOACCESS=$HTTP_USER_PREFIX-"noaccess"
HTTP_USER_SPECIAL=$HTTP_USER_PREFIX-"special"
LDAP_USER_ADMIN=$LDAP_USER_PREFIX-"admin"
LDAP_USER_USER=$LDAP_USER_PREFIX-"user"
LDAP_USER_NOACCESS=$LDAP_USER_PREFIX-"noaccess"
HTTP_CLUSTER_ADMIN=$HTTP_USER_PREFIX-"cluster-admin-user"
TEST_PASSWD="rhods-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 4)"
TEST_ADMIN_PASSWD="rhods-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 6)"

export HTTP_USER_ADMIN
export HTTP_USER_USER
export HTTP_USER_NOACCESS
export HTTP_USER_SPECIAL
export LDAP_USER_ADMIN
export LDAP_USER_USER
export LDAP_USER_NOACCESS
export HTTP_CLUSTER_ADMIN
export TEST_PASSWD
export TEST_ADMIN_PASSWD

install_htpasswd_identity_provider(){

# Test if any oauth identityProviders exists. If not, initialize the identityProvider list
CURRENT_IDP_LIST=$(oc get oauth cluster -o json | jq -e '.spec.identityProviders')
if [[ -z "${CURRENT_IDP_LIST}" ]] || [[  "${CURRENT_IDP_LIST}" == "null" ]]; then
  echo 'No oauth identityProvider exists. Initializing oauth .spec.identityProviders = []'
  oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders", "value": []}]'
fi

$PROVIDER_PATH/htpasswd/htpasswd_installation.sh
# Patch in the HTPASSWD identityProviders
oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders/-", "value": {"name":"htpasswd-cluster-admin","mappingMethod":"claim","type":"HTPasswd","htpasswd":{"fileData":{"name":"htpasswd-secret"}}}}]'
}

install_ldap_identity_provider(){

# Test if any oauth identityProviders exists. If not, initialize the identityProvider list
CURRENT_IDP_LIST=$(oc get oauth cluster -o json | jq -e '.spec.identityProviders')
if [[ -z "${CURRENT_IDP_LIST}" ]] || [[  "${CURRENT_IDP_LIST}" == "null" ]]; then
  echo 'No oauth identityProvider exists. Initializing oauth .spec.identityProviders = []'
  oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders", "value": []}]'
fi

# Patch in the LDAP identityProviders
oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders/-", "value": {"ldap":{"attributes":{"email":[],"id":["dn"],"name":["cn"],"preferredUsername":["uid"]},"insecure":true,"bindDN":"cn=admin,dc=example,dc=org","bindPassword":{"name":"ldap-bind-password"},"url":"ldap://openldap.openldap.svc.cluster.local:1389/dc=example,dc=org?uid"},"mappingMethod":"claim","name":"ldap-provider-qe","type":"LDAP"}}]'

$PROVIDER_PATH/ldap/ldap_installation.sh
}

add_groups_users() {
# create groups
oc adm groups new rhods-admins
oc adm groups new rhods-users
oc adm groups new rhods-noaccess
oc adm groups new dedicated-admins
# add users to groups
function add_users_to_groups(){
for i in {1..10}
  do
    oc adm groups add-users $1 $2$i 
  done
}
add_users_to_groups rhods-admins $HTTP_USER_ADMIN
add_users_to_groups rhods-users $HTTP_USER_USER
add_users_to_groups rhods-noaccess $HTTP_USER_NOACCESS
add_users_to_groups rhods-admins $LDAP_USER_ADMIN
add_users_to_groups dedicated-admins $LDAP_USER_ADMIN
add_users_to_groups rhods-users $LDAP_USER_USER
add_users_to_groups rhods-noaccess $LDAP_USER_NOACCESS
oc adm groups add-users dedicated-admins $HTTP_CLUSTER_ADMIN

oc adm groups add-users rhods-admins kubeadmin
oc adm policy add-cluster-role-to-group view rhods-admins
oc adm policy add-cluster-role-to-group cluster-admin dedicated-admins

oc describe oauth.config.openshift.io/cluster
}

function htpasswd_installation(){
  chk_htpasswd=1

  while read -r line; do

    if [[ $line == *"cluster-admin"* ]]; then
        echo -e "\033[0;33m Htpasswd Identity provider is installed. Skipping installation \033[0m"
        chk_htpasswd=0
        break
    fi
  done < <(oc get oauth -o yaml)

  if [[ $chk_htpasswd == 1 ]]; then
    install_htpasswd_identity_provider
  fi
}

function ldap_installation(){
  chk_ldap=1
  while read -r line; do
    if [[ $line == *"ldap-provider-qe"* ]]; then
	    echo -e "\033[0;33m LDAP Identity provider is installed. Skipping installation \033[0m"
	    chk_ldap=0
        break
    fi
  done < <(oc get oauth -o yaml)
  if [[ $chk_ldap == 1 ]]; then
    install_ldap_identity_provider
  fi
}

function update_testConfig(){
    echo "Update test config file..."

    AWS_SHARED_CREDENTIALS_FILE="${CLUSTER_PROFILE_DIR}/.awscred"
    AWS_ACCESS_KEY_ID=$(cat $AWS_SHARED_CREDENTIALS_FILE | grep aws_access_key_id | tr -d ' ' | cut -d '=' -f 2)
    AWS_SECRET_ACCESS_KEY=$(cat $AWS_SHARED_CREDENTIALS_FILE | grep aws_secret_access_key | tr -d ' ' | cut -d '=' -f 2)

    LDAP_USER_ADMIN1=$LDAP_USER_ADMIN"1"
    LDAP_USER_ADMIN2=$LDAP_USER_ADMIN"2"
    LDAP_USER_USER2=$LDAP_USER_USER"2"
    LDAP_USER_USER9=$LDAP_USER_USER"9"

    export LDAP_USER_ADMIN1
    export LDAP_USER_ADMIN2
    export LDAP_USER_USER2
    export LDAP_USER_USER9
    export AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY

    yq -i '.OCP_ADMIN_USER.AUTH_TYPE="htpasswd-cluster-admin"' $TEST_VARIABLES_FILE
    yq -i '.OCP_ADMIN_USER.USERNAME=env(HTTP_CLUSTER_ADMIN)' $TEST_VARIABLES_FILE
    yq -i '.OCP_ADMIN_USER.PASSWORD=env(TEST_ADMIN_PASSWD)' $TEST_VARIABLES_FILE

    yq -i '.TEST_USER.AUTH_TYPE="ldap-provider-qe"' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER.USERNAME=env(LDAP_USER_ADMIN1)' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER.PASSWORD=env(TEST_PASSWD)' $TEST_VARIABLES_FILE
  
    yq -i '.TEST_USER_2.AUTH_TYPE="ldap-provider-qe"' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_2.USERNAME=env(LDAP_USER_ADMIN2)' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_2.PASSWORD=env(TEST_PASSWD)' $TEST_VARIABLES_FILE
  
    yq -i '.TEST_USER_3.AUTH_TYPE="ldap-provider-qe"' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_3.USERNAME=env(LDAP_USER_USER2)' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_3.PASSWORD=env(TEST_PASSWD)' $TEST_VARIABLES_FILE
  
    yq -i '.TEST_USER_4.AUTH_TYPE="ldap-provider-qe"' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_4.USERNAME=env(LDAP_USER_USER9)' $TEST_VARIABLES_FILE
    yq -i '.TEST_USER_4.PASSWORD=env(TEST_PASSWD)' $TEST_VARIABLES_FILE

    yq -i '.OCP_API_URL=env(OC_HOST)' $TEST_VARIABLES_FILE
    yq -i '.OCP_CONSOLE_URL=env(OCP_CONSOLE)' $TEST_VARIABLES_FILE
    yq -i '.ODH_DASHBOARD_URL=env(RHODS_DASHBOARD)' $TEST_VARIABLES_FILE
    yq -i '.BROWSER.NAME="firefox"' $TEST_VARIABLES_FILE
    yq -i '.S3.AWS_ACCESS_KEY_ID=env(AWS_ACCESS_KEY_ID)' $TEST_VARIABLES_FILE
    yq -i '.S3.AWS_SECRET_ACCESS_KEY=env(AWS_SECRET_ACCESS_KEY)' $TEST_VARIABLES_FILE
    
    echo "OCP Console URL set to: $OCP_CONSOLE"
    echo "RHODS API Server URL set to: $OC_HOST"
    echo "RHODS Dashboard URL set to: $RHODS_DASHBOARD"
}

htpasswd_installation
ldap_installation
add_groups_users
update_testConfig
sleep 120

echo "Performing oc login using username and password"
oc login "$OC_HOST" --username $HTTP_CLUSTER_ADMIN --password $TEST_ADMIN_PASSWD --insecure-skip-tls-verify=true
retVal=$?
if [ $retVal -ne 0 ]; then
    echo "The oc login command seems to have failed"
    echo "Please review the content of $TEST_VARIABLES_FILE"
    exit "$retVal"
fi

