#!/bin/bash
perform_oc_logic(){
  echo "----> Performing log in the cluster using oc CLI command"
  for i in {1..5}
    do
      oc login $1 --username $2 --password $3 || (echo "Login failed $i times. Trying again in 30 seconds (max 5 times)." && sleep 30)
    done
}

perform_ocm_login(){
  echo "---> Performing log in OCM"
  if [ -n "${OCM_TOKEN}" ]
    then
        echo "ocm envirnment: ${OCM_ENV}"
        if [ -n "${OCM_ENV}" ]; then \
                ocm login --token=${OCM_TOKEN} --url=${OCM_ENV} ;\
        else
                ocm login --token=${OCM_TOKEN}
        fi
    else
        echo -e "\033[0;33m OCM Token not set. Please run again and set the required token \033[0m"
        exit 0
  fi
}

function generate_rand_string(){
  sleep 2
  date +%s | sha256sum | base64 | head -c 32
}
function generates_ldap_creds(){
  users_string_adm=""
  users_string_usr=""
  users_string_noa=""
  users_string_special=""
  rand_string=""
  rand=$(generate_rand_string)
  echo Random pw: $rand
  # generate users and pw (admin, user, noaccess)
  for i in {1..20}
    do
      # remove user names generation with the default usernames present in the ldap.yaml. Change only the pw (74 users in total)
      users_string_adm+=,$1-adm$i
      users_string_usr+=,$1-usr$i
      users_string_noa+=,$1-noaccess$i
      rand_string+=,$rand
    done
  rand_string=$rand_string$rand_string$rand_string
  # generate users with special chars and pw
  declare -a StringArray=("." "^" "$" "*" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";")
  # declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
  for char in "${StringArray[@]}";
    do
      users_string_special+=,$1-special$char
      rand_string+=,$rand
    done
  users_string_final=$users_string_adm$users_string_usr$users_string_special$users_string_noa
  users_string_final=${users_string_final:1}
  rand_string=${rand_string:1}
  users_base64=$(echo -n $users_string_final | base64 -w 0)
  rand_base64=$(echo -n $rand_string | base64 -w 0)

  # update ldap.yaml with creds
  sed -i "s/<users_string>/$users_base64/g" configs/templates/ldap/ldap.yaml
  sed -i "s/<passwords_string>/$rand_base64/g" configs/templates/ldap/ldap.yaml
  rand=$(generate_rand_string)
  export RAND_ADMIN=$rand
  rand_base64=$(echo -n $rand | base64 -w 0)
  sed -i "s/<adminpassword>/$rand_base64/g" configs/templates/ldap/ldap.yaml

  # update test-variables.yml file with the test users' creds
  export PREFIX=$1
  export RAND_LDAP=$rand
  yq --inplace '.TEST_USER.AUTH_TYPE="ldap-provider-qe"' test-variables.yml
  yq --inplace '.TEST_USER.USERNAME=env(PREFIX)+"-adm1"' test-variables.yml
  yq --inplace '.TEST_USER.PASSWORD=env(RAND_LDAP)' test-variables.yml
  yq --inplace '.TEST_USER_2.AUTH_TYPE="ldap-provider-qe"' test-variables.yml
  yq --inplace '.TEST_USER_2.USERNAME=env(PREFIX)+"-adm2"' test-variables.yml
  yq --inplace '.TEST_USER_2.PASSWORD=env(RAND_LDAP)' test-variables.yml
  yq --inplace '.TEST_USER_3.AUTH_TYPE="ldap-provider-qe"' test-variables.yml
  yq --inplace '.TEST_USER_3.USERNAME=env(PREFIX)+"-adm3"' test-variables.yml
  yq --inplace '.TEST_USER_3.PASSWORD=env(RAND_LDAP)' test-variables.yml
  yq --inplace '.TEST_USER_4.AUTH_TYPE="ldap-provider-qe"' test-variables.yml
  yq --inplace '.TEST_USER_4.USERNAME=env(PREFIX)+"-adm4"' test-variables.yml
  yq --inplace '.TEST_USER_4.PASSWORD=env(RAND_LDAP)' test-variables.yml
  }

function add_users_to_groups(){
  for i in {1..20}
    do
      oc adm groups add-users $1 $2$i
    done
  }
function add_special_users_to_groups(){
  declare -a StringArray=("." "^" "$" "*" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";")
  # declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
  for char in "${StringArray[@]}";
    do
      oc adm groups add-users $1 $2$char
    done
  }


install_identity_provider(){
  echo "---> Installing the required IDPs"

  generates_ldap_creds  robot

  # create htpasswd idp and user
  echo $OC_HOST
  CLUSTER_NAME=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $2}')
  echo Cluster name is $CLUSTER_NAME
  rand_string=$(generate_rand_string)
  echo Random htp pasword: $rand_string
  ocm create idp -c "${CLUSTER_NAME}" -t htpasswd -n htpasswd --username htpasswd-user --password $rand_string
  ocm create user htpasswd-user --cluster $CLUSTER_NAME --group=cluster-admins

  # update test-variables.yml with admin creds
  yq --inplace '.OCP_ADMIN_USER.AUTH_TYPE="htpasswd"' test-variables.yml
  yq --inplace '.OCP_ADMIN_USER.USERNAME="htpasswd-user"' test-variables.yml
  export RAND_STRING=$rand_string
  yq --inplace '.OCP_ADMIN_USER.PASSWORD=env(RAND_STRING)' test-variables.yml

  # get cluster id
  # ext_clusterid=$(oc get clusterversion -o json | jq .items[].spec.clusterID | sed 's/"//g')
  # ocm_clusterid=$(ocm describe cluster ${ext_clusterid} --json | jq -r '.id')
  ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')

  # login using htpasswd
  perform_oc_logic  $OC_HOST  htpasswd-user  $rand_string

  # create ldap deployment
  oc apply -f configs/templates/ldap/ldap.yaml

  # configure the jinja template for adding ldap idp in OCM
  rand_admin=$(echo $RAND_ADMIN | base64 -d)
  sed -i "s/{{ LDAP_BIND_PASSWORD }}/$RAND_ADMIN/g" utils/scripts/ocm/templates/create_ldap_idp.jinja
  sed -i "s/{{ LDAP_BIND_DN }}/cn=admin,dc=example,dc=org/g" utils/scripts/ocm/templates/create_ldap_idp.jinja
  sed -i 's/{{ LDAP_URL }}/ldap:\/\/openldap.openldap.svc.cluster.local:1389\/dc=example,dc=org?uid/g' utils/scripts/ocm/templates/create_ldap_idp.jinja
  ocm post /api/clusters_mgmt/v1/clusters/${ocm_clusterid}/identity_providers --body=utils/scripts/ocm/templates/create_ldap_idp.jinja

  # add users to RHODS groups
  oc adm groups new rhods-admins
  oc adm groups new rhods-users
  oc adm groups new rhods-noaccess
  oc adm groups new dedicated-admins

  add_users_to_groups rhods-admins robot-adm
  add_users_to_groups dedicated-admins robot-adm
  add_users_to_groups rhods-users robot-usr
  add_users_to_groups rhods-noaccess robot-noaccess
  add_special_users_to_groups rhods-users  robot-special

  # wait for IdP to appear in the login page
  echo "sleeping 90sec to wait for IDPs to appear in the OCP login page..."
  sleep 90
}

function check_installation(){
  echo "---> Looking for LDAP and HTPASSWD already present in the cluster..."
  ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')
  echo $ocm_clusterid
  while read -r line; do
    if [[ $line == *"ldap-provider-qe"* ]] || [[ $line == *"htpasswd"* ]] ; then
        echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are already installed. Skipping installation \033[0m"
        exit 0
    fi
  done < <(ocm get /api/clusters_mgmt/v1/clusters/$ocm_clusterid/identity_providers)
}

perform_ocm_login
check_installation
install_identity_provider
