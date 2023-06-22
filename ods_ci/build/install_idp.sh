#!/bin/bash
perform_oc_logic(){
  echo "----> Performing log in the cluster using oc CLI command"
  for i in {1..7}
    do
      oc login $1 --username $2 --password $3 || (echo "Login failed $i times. Trying again in 30 seconds (max 7 times)." && sleep 30)
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
  date +%s | sha256sum | base64 | head -c 64
}

function generate_users_creds_strings(){
  idp=$(jq --arg idpname $1 '.[][$idpname]' user_credentials.json)
  echo $idp;
  users_string=""
  pw_string=""
  pw=$(echo $idp | jq '.pw' | tr -d '[],"')
  if [[ "$pw" =  "<GEN_RAMDOM_PW>" ]]
      then
          pw=$(generate_rand_string)
            if [ "${RETURN_PW}" -eq 1 ]
              then
                  echo Random $1 pasword: $pw
            fi
  fi
  prefixes=$(echo $idp | jq --raw-output '.prefixes[]')
  prefixes=($prefixes)
  for prefix in "${prefixes[@]}"; do
      echo $prefix
      no=$(echo $idp | jq --arg pref $prefix  '.no_user_per_prefix[$pref]')
      echo $no
      i=1
      if [[ $no -eq 1 ]]
          then
              users_string+=,$prefix
              pw_string+=,$pw
          else
              while [[ $i -le $no ]]; do
                  users_string+=,$prefix-$i
                  pw_string+=,rand_pw
                  ((i++))
              done
      fi
  done
  USERS_STRING=${users_string:1}
  PW_STRING=${pw_string:1}
  # temporarily printing
  echo    $USERS_STRING
  echo    $PW_STRING
}

function_set_users_test_variables(){
  # get the mapping as input
  export PREFIX=$1
  yq --inplace '.TEST_USER.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER.USERNAME=env(PREFIX)+"-adm1"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER.PASSWORD=env(RAND_LDAP)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_2.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_2.USERNAME=env(PREFIX)+"-adm2"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_2.PASSWORD=env(RAND_LDAP)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_3.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_3.USERNAME=env(PREFIX)+"-adm3"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_3.PASSWORD=env(RAND_LDAP)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_4.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_4.USERNAME=env(PREFIX)+"-adm4"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_4.PASSWORD=env(RAND_LDAP)' ods_ci/test-variables.yml

  # update test-variables.yml with admin creds
  yq --inplace '.OCP_ADMIN_USER.AUTH_TYPE="htpasswd"' ods_ci/test-variables.yml
  yq --inplace '.OCP_ADMIN_USER.USERNAME="htpasswd-user"' ods_ci/test-variables.yml
  export RAND_STRING=$rand_string
  yq --inplace '.OCP_ADMIN_USER.PASSWORD=env(RAND_STRING)' ods_ci/test-variables.yml
}

function set_htpasswd_users(){
  generate_users_creds_strings  htpasswd

  if [ "${USE_OCM_IDP}" -eq 1 ]
    then
        CLUSTER_NAME=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $2}')
        echo Cluster name is $CLUSTER_NAME
        ocm create idp -c "${CLUSTER_NAME}" -t htpasswd -n htpasswd --username htpasswd-user --password $rand_string
        ocm create user htpasswd-user --cluster $CLUSTER_NAME --group=cluster-admins
    else
        htp_string=$(htpasswd -b -B -n htpasswd-user $rand_string)
        oc create secret generic htpasswd-password --from-literal=htpasswd="$htp_string" -n openshift-config
        OAUTH_HTPASSWD_JSON="$(cat ods_ci/configs/resources/oauth_htp_idp.json)"
        oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders/-", "value": '"$OAUTH_HTPASSWD_JSON"'}]'
        sed -i "s/<rolebinding_name>/ods-ci-htp-admin/g" ods_ci/configs/templates/ca-rolebinding.yaml
        sed -i "s/<username>/htpasswd-user/g" ods_ci/configs/templates/ca-rolebinding.yaml
        oc apply -f ods_ci/configs/templates/ca-rolebinding.yaml
  fi


}

function set_ldap_users(){
  generate_users_creds_strings  ldap
  
  declare -a StringArray=("." "^" "$" "*" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";")
  # declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
  for char in "${StringArray[@]}";
    do
      users_string_special+=,ldap-special$char
      rand_string+=,$rand
    done
  USERS_STRING=$USERS_STRING$users_string_special
  PW_STRING=$PW_STRING$rand_string

  users_base64=$(echo -n $USERS_STRING | base64 -w 0)
  rand_base64=$(echo -n $PW_STRING | base64 -w 0)

  # update ldap.yaml with creds
  sed -i "s/<users_string>/$users_base64/g" ods_ci/configs/templates/ldap/ldap.yaml
  sed -i "s/<passwords_string>/$rand_base64/g" ods_ci/configs/templates/ldap/ldap.yaml
  rand=$(generate_rand_string)
  export RAND_ADMIN=$rand
  rand_base64=$(echo -n $rand | base64 -w 0)
  sed -i "s/<adminpassword>/$rand_base64/g" ods_ci/configs/templates/ldap/ldap.yaml

  ldap    $USERS_STRING
  echo    $PW_STRING


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

function add_users_to_dedicated_admins(){
  for i in {1..20}
    do
      ocm create user $1$i --cluster $CLUSTER_NAME --group=dedicated-admins
    done
}

install_identity_provider(){
  echo "---> Installing the required IDPs"

  set_ldap_users
  set_htpasswd_users
  function_set_users_test_variables

  # create htpasswd idp and user
  echo $OC_HOST
  # fetch cluster admin user from json
  # to do




  # login using htpasswd
  perform_oc_logic  $OC_HOST  htpasswd-user  $rand_string

  # create ldap deployment
  oc apply -f ods_ci/configs/templates/ldap/ldap.yaml
  if [ "${USE_OCM_IDP}" -eq 1 ]
      then
          ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')
          # configure the jinja template for adding ldap idp in OCM
          rand_admin=$(echo $RAND_ADMIN | base64 -d)
          sed -i "s/{{ LDAP_BIND_PASSWORD }}/$RAND_ADMIN/g" ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja
          sed -i "s/{{ LDAP_BIND_DN }}/cn=admin,dc=example,dc=org/g" ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja
          sed -i 's/{{ LDAP_URL }}/ldap:\/\/openldap.openldap.svc.cluster.local:1389\/dc=example,dc=org?uid/g' ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja
          ocm post /api/clusters_mgmt/v1/clusters/${ocm_clusterid}/identity_providers --body=ods_ci/utils/scripts/ocm/templates/create_ldap_idp.jinja
      else
          oc create secret generic ldap-bind-password --from-literal=bindPassword="$RAND_ADMIN" -n openshift-config
          OAUTH_LDAP_JSON="$(cat ods_ci/configs/resources/oauth_ldap_idp.json)"
          oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders/-", "value": '"$OAUTH_LDAP_JSON"'}]'
  fi
  # add users to RHODS groups
  oc adm groups new rhods-admins
  oc adm groups new rhods-users
  oc adm groups new rhods-noaccess
  oc adm groups new dedicated-admins

  add_users_to_groups rhods-admins ldap-adm
  if [ "${USE_OCM_IDP}" -eq 1 ]
      then
          add_users_to_dedicated_admins ldap-adm
      else
          add_users_to_groups dedicated-admins ldap-adm
  fi

  add_users_to_groups rhods-users ldap-usr
  add_users_to_groups rhods-noaccess ldap-noaccess
  add_special_users_to_groups rhods-users  ldap-special

  # wait for IdP to appear in the login page
  echo "sleeping 120sec to wait for IDPs to appear in the OCP login page..."
  sleep 120
}

function check_installation(){
  echo "---> Looking for LDAP and HTPASSWD already present in the cluster..."
  if [ "${USE_OCM_IDP}" -eq 1 ]
      then
            ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')
            echo $ocm_clusterid
            while read -r line; do
              if [[ $line == *"ldap"* ]] || [[ $line == *"htpasswd"* ]] ; then
                  echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are already installed. Skipping installation \033[0m"
                  exit 0
              fi
            done < <(ocm get /api/clusters_mgmt/v1/clusters/$ocm_clusterid/identity_providers)
      else
            CURRENT_IDP_LIST=$(oc get oauth cluster -o json | jq -e '.spec.identityProviders')
            if [[ -z "${CURRENT_IDP_LIST}" ]] || [[  "${CURRENT_IDP_LIST}" == "null" ]]; then
              echo 'No oauth identityProvider exists. Initializing oauth .spec.identityProviders = []'
              oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders", "value": []}]'
            elif [[ "${CURRENT_IDP_LIST}" == *"ldap"* ]] || [[  "${CURRENT_IDP_LIST}" == *"htpasswd"* ]]; then
              echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are already installed. Skipping installation \033[0m"
              exit 0
            else
              echo -e "\033[0;33m IDPs different from LDAP and/or htpasswd Identity providers are installed. Installation will continue...Check the cluster \033[0m"
              #exit 0
            fi
  fi
}

if [ "${USE_OCM_IDP}" -eq 1 ]
      then
          perform_ocm_login
fi
check_installation
install_identity_provider
