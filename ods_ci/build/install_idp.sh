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

function generate_user_prefix(){
  GEN_PREFIX=""
  array=()
  for i in {a..z} {A..Z}; 
    do
    array[$RANDOM]=$i
  done
  GEN_PREFIX=$(printf %s ${array[@]::15} $'\n')
}

function generate_users_creds(){
  idp=$(jq --arg idpname $1 '.[][$idpname]' ods_ci/build/user_credentials.json)
  echo $idp;
  USERS_ARR=()
  PWS_ARR=()
  pw=$(echo $idp | jq -r '.pw')
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
              USERS_ARR+=($prefix)
              PWS_ARR+=($pw)
          else
              while [[ $i -le $no ]]; do
                  echo $prefix-$i
                  USERS_ARR+=($prefix-$i)
                  PWS_ARR+=(rand_pw)
                  ((i++))
              done
      fi
  done
  # echo ${#PWS_ARR[@]}
  # ldap_users_str=$(printf ,%s ${USERS_ARR[@]})
  # ldap_pws_str=$(printf ,%s ${PWS_ARR[@]})
  # # temporarily printing
  # echo    $ldap_users_str
  # echo    $ldap_pws_str
}

function set_htpasswd_users_and_login(){
  generate_users_creds  htpasswd
  HTP_USERS=$USERS_ARR
  htp_pw=$pw
  cluster_adm_user=$(jq -r --arg idpname htpasswd '.[][$idpname].cluster_admin_username' ods_ci/build/user_credentials.json)

  if [ "${USE_OCM_IDP}" -eq 1 ]
    then
        CLUSTER_NAME=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $2}')
        echo Cluster name is $CLUSTER_NAME
        ocm create idp -c "${CLUSTER_NAME}" -t htpasswd -n htpasswd --username $cluster_adm_user --password $htp_pw
        ocm create user htpasswd-user --cluster $CLUSTER_NAME --group=cluster-admins
    else
        htp_string=$(htpasswd -b -B -n $cluster_adm_user $htp_pw)
        # oc create secret generic htpasswd-password --from-literal=htpasswd="$htp_string" -n openshift-config
        OAUTH_HTPASSWD_JSON="$(cat ods_ci/configs/resources/oauth_htp_idp.json)"
        # oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders/-", "value": '"$OAUTH_HTPASSWD_JSON"'}]'
        sed -i "s/<rolebinding_name>/ods-ci-htp-admin/g" ods_ci/configs/templates/ca-rolebinding.yaml
        sed -i "s/<username>/$cluster_adm_user/g" ods_ci/configs/templates/ca-rolebinding.yaml
        # oc apply -f ods_ci/configs/templates/ca-rolebinding.yaml
  fi
  
  # login using htpasswd
  # perform_oc_logic  $OC_HOST  $cluster_adm_user  $htp_pw

  oc get secret htpass-secret -ojsonpath={.data.htpasswd} -n openshift-config | base64 --decode > ods_ci/build/users.htpasswd
  for htp_user in "${HTP_USERS[@]}"; do
    if [[ ! "$htp_user" =  "$cluster_adm_user" ]]
      then
        htpasswd -bB ods_ci/build/users.htpasswd $htp_user $htp_pw
    fi
  done
  oc create secret generic htpass-secret --from-file=htpasswd=ods_ci/build/users.htpasswd --dry-run=client -o yaml -n openshift-config | oc replace -f -


  # update test-variables.yml with admin creds
  export adm_user=$cluster_adm_user
  export adm_p=$htp_pw
  yq --inplace '.OCP_ADMIN_USER.AUTH_TYPE="htpasswd"' ods_ci/test-variables.yml
  yq --inplace '.OCP_ADMIN_USER.USERNAME=env(adm_user)' ods_ci/test-variables.yml
  yq --inplace '.OCP_ADMIN_USER.PASSWORD=env(adm_p)' ods_ci/test-variables.yml
}

function set_ldap_users(){
  generate_users_creds  ldap
  LDAP_USERS=("${USERS_ARR[@]}")  
  LDAP_PWS=("${PWS_ARR[@]}")  
  ldap_users_str=$(printf ,%s ${LDAP_USERS[@]})
  ldap_pws_str=$(printf ,%s ${LDAP_PWS[@]})
  ldap_pw=$pw
  declare -a StringArray=("." "^" "$" "*" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";")
  # declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
  for char in "${StringArray[@]}";
    do
      users_string_special+=,ldap-special$char
      pw_string+=,$ldap_pw
    done
  ldap_users_str=$ldap_users_str$users_string_special
  ldap_pws_str=$ldap_pws_str$pw_string
  ldap_users_str=${ldap_users_str:1}
  ldap_pws_str=${ldap_pws_str:1}
  users_base64=$(echo -n $ldap_users_str | base64 -w 0)
  rand_base64=$(echo -n $ldap_pws_str | base64 -w 0)

  echo $users_base64
  echo $rand_base64

  # update ldap.yaml with creds
  sed -i "s/<users_string>/$users_base64/g" ods_ci/configs/templates/ldap/ldap.yaml
  sed -i "s/<passwords_string>/$rand_base64/g" ods_ci/configs/templates/ldap/ldap.yaml
  rand=$(generate_rand_string)
  export RAND_ADMIN=$rand
  rand_base64=$(echo -n $rand | base64 -w 0)
  sed -i "s/<adminpassword>/$rand_base64/g" ods_ci/configs/templates/ldap/ldap.yaml

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

  echo    $USERS_STRING
  echo    $PW_STRING

  test_user=$(jq -r --arg idpname ldap '.[][$idpname].TEST_USER' ods_ci/build/user_credentials.json)
  test_user_2=$(jq -r --arg idpname ldap '.[][$idpname].TEST_USER_2' ods_ci/build/user_credentials.json)
  test_user_3=$(jq -r --arg idpname ldap '.[][$idpname].TEST_USER_3' ods_ci/build/user_credentials.json)
  test_user_4=$(jq -r --arg idpname ldap '.[][$idpname].TEST_USER_4' ods_ci/build/user_credentials.json)

  export ldap_pw=$ldap_pw
  export username=$test_user
  yq --inplace '.TEST_USER.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER.USERNAME=env(username)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER.PASSWORD=env(ldap_pw)' ods_ci/test-variables.yml
  export username=$test_user_2
  yq --inplace '.TEST_USER_2.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_2.USERNAME=env(username)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_2.PASSWORD=env(ldap_pw)' ods_ci/test-variables.yml
  export username=$test_user_3
  yq --inplace '.TEST_USER_3.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_3.USERNAME=env(username)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_3.PASSWORD=env(ldap_pw)' ods_ci/test-variables.yml
  export username=$test_user_4
  yq --inplace '.TEST_USER_4.AUTH_TYPE="ldap-provider-qe"' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_4.USERNAME=env(username)' ods_ci/test-variables.yml
  yq --inplace '.TEST_USER_4.PASSWORD=env(ldap_pw)' ods_ci/test-variables.yml

}

function create_groups_and_assign_users(){
  oc adm groups new rhods-admins
  oc adm groups new rhods-users
  oc adm groups new rhods-noaccess
  oc adm groups new dedicated-admins
  for prefix in "${prefixes[@]}"; do
    groups=$(jq --arg idpname ldap --arg pref $prefix '.[][$idpname].groups_map[$pref][]' ods_ci/build/user_credentials.json)
    groups=($groups)
    for group in "${groups[@]}"; do
      if [[ $group == *"dedicated-admins"* ]]; then
          if [ "${USE_OCM_IDP}" -eq 1 ]
              then
                  add_users_to_dedicated_admins ldap-adm
                  continue
          fi
      fi
      # echo $group
      add_users_to_groups $group ldap-adm
    done
  done
}


function add_users_to_groups(){
  for user in "${LDAP_USERS[@]}"; do
    if [[ $user == *"$2"* ]]; then
      oc adm groups add-users $1 $2
      # echo  add-users $1 $2
    fi
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
  for user in "${LDAP_USERS[@]}"; do
    if [[ $user == *"$2"* ]]; then
      ocm create user $user --cluster $CLUSTER_NAME --group=dedicated-admins
    fi
  done
}

function install_identity_provider(){
  echo "---> Installing the required IDPs"
  echo "host: $OC_HOST"
  set_htpasswd_users_and_login
  set_ldap_users
   
  # add users to RHODS groups
  create_groups_and_assign_users
  
  # add_special_users_to_groups rhods-users  ldap-special

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
# check_installation
install_identity_provider
