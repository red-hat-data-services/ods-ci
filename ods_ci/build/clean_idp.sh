#!/bin/bash
perform_oc_logic(){
  echo "----> Performing log in the cluster using oc CLI command"
  oc login $1 --username $2 --password $3 || (echo "Login failed. Please check the credentials you provided." && sleep 30)
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

function delete_users(){
  for i in {1..20}
    do
      oc delete user $1$i
    done
  }
function delete_special_users(){
  declare -a StringArray=("." "^" "$" "*" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";")
  for char in "${StringArray[@]}";
    do
      oc delete user $1$char
    done
  }

function remove_user_from_dedicated_admins(){
  for i in {1..20}
    do
      ocm delete user $1$i --cluster $CLUSTER_NAME --group=dedicated-admins
    done
}

uninstall_identity_provider(){
  echo "---> Uninstalling the IDPs previously installed by ODS-CI"

  echo $OC_HOST
  if [ "${USE_OCM_IDP}" -eq 1 ]
    then
      CLUSTER_NAME=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $2}')
      echo Cluster name is $CLUSTER_NAME
      ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')
  fi
  # login using admin user
  perform_oc_logic  $OC_HOST  $ADMIN_USERNAME  $ADMIN_PASS

  # add users to RHODS groups
  oc delete group rhods-admins
  oc delete group rhods-users
  oc delete group rhods-noaccess

  if [ "${USE_OCM_IDP}" -eq 1 ]
    then
      remove_user_from_dedicated_admins  ldap-adm
  fi
  delete_users  ldap-adm
  delete_users  ldap-usr
  delete_users  ldap-noaccess
  delete_special_users  ldap-special

  # delete user identities from OCP cluster
  oc get identity -oname | xargs oc delete

  # delete htpasswd and LDAp idp
  # delete ldap deployment and idp
  # oc wait --for=delete $(oc get namespace openldap)
  oc delete -f ods_ci/configs/templates/ldap/ldap.yaml
  if [ "${USE_OCM_IDP}" -eq 1 ]
    then
      ocm delete idp -c "${CLUSTER_NAME}" ldap-provider-qe
      ocm delete user htpasswd-user --cluster $CLUSTER_NAME --group=cluster-admins
      ocm delete idp -c "${CLUSTER_NAME}" htpasswd
    else
      oc delete secret ldap-bind-password -n openshift-config
      ldap_idx=$(oc get oauth cluster -o json | jq '.spec.identityProviders | map(.name == "ldap-provider-qe") | index(true)')
      oc patch oauth cluster --type json -p "[{'op': 'remove', 'path': '/spec/identityProviders/$ldap_idx'}]"
      # oc patch oauth cluster --type json -p '[{"op": "add", "path": "/spec/identityProviders", "value": []}]'
      htp_idx=$(oc get oauth cluster -o json | jq '.spec.identityProviders | map(.name == "htpasswd") | index(true)')
      oc patch oauth cluster --type json -p "[{'op': 'remove', 'path': '/spec/identityProviders/$htp_idx'}]"
      oc delete secret htpasswd-password -n openshift-config
      delete_users  htpasswd-user
      oc delete clusterrolebinding ods-ci-htp-admin
  fi
  # wait for IdP to disappear in the login page
  echo "sleeping 120sec to wait for IDPs to disappear in the OCP login page..."

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
                  found=1                 
              fi
            done < <(ocm get /api/clusters_mgmt/v1/clusters/$ocm_clusterid/identity_providers)
            if  [ -z $found ]
              then
                echo -e "\033[0;33m LDAP and/or htpasswd Identity not found. Skipping removal of IDPs \033[0m"
                exit 0
              else 
                echo -e "\033[0;33m LDAP and/or htpasswd Identity providers found. Going to remove IDPs \033[0m"
            fi
      else
            CURRENT_IDP_LIST=$(oc get oauth cluster -o json | jq -e '.spec.identityProviders')
            if [[ -z "${CURRENT_IDP_LIST}" ]] || [[  "${CURRENT_IDP_LIST}" == "null" ]]; then
              echo -e "\033[0;33m LDAP and/or htpasswd Identity not found. Skipping removal of IDPs \033[0m"
              exit 0
            elif [[ "${CURRENT_IDP_LIST}" == *"ldap"* ]] || [[  "${CURRENT_IDP_LIST}" == *"htpasswd"* ]]; then
              echo -e "\033[0;33m LDAP and/or htpasswd Identity providers found. Going to remove IDPs \033[0m"
            else
              echo -e "\033[0;33m Only IDPs different from LDAP and HTPassword are installed. Skipping removal. Check the cluster \033[0m"
              exit 0
            fi
  fi
}

function check_uninstallation(){
  echo "---> Looking for LDAP and HTPASSWD already present in the cluster..."
  if [ "${USE_OCM_IDP}" -eq 1 ]
      then
            ocm_clusterid=$(ocm list clusters  --no-headers --parameter search="api.url = '${OC_HOST}'" | awk '{print $1}')
            echo $ocm_clusterid
            while read -r line; do
              if [[ $line == *"ldap"* ]] || [[ $line == *"htpasswd"* ]] ; then
                  echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are still installed. Please check the cluster \033[0m"
                  found=1 
                  exit 0
              fi
            done < <(ocm get /api/clusters_mgmt/v1/clusters/$ocm_clusterid/identity_providers)
            if  [ -z $found ]
              then
                echo -e "\033[0;33m LDAP and/or htpasswd Identity providers have been deleted from the cluster \033[0m"
              else 
                echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are still installed. Please check the cluster \033[0m"
            fi
      else
            CURRENT_IDP_LIST=$(oc get oauth cluster -o json | jq -e '.spec.identityProviders')
            if [[ -z "${CURRENT_IDP_LIST}" ]] || [[  "${CURRENT_IDP_LIST}" == "null" ]]; then
              echo -e "\033[0;33m No oauth identityProvider exists. LDAP and/or htpasswd Identity providers have been deleted from the cluster \033[0m"
            elif [[ "${CURRENT_IDP_LIST}" == *"ldap"* ]] || [[  "${CURRENT_IDP_LIST}" == *"htpasswd"* ]]; then
              echo -e "\033[0;33m LDAP and/or htpasswd Identity providers are still installed. Please check the cluster \033[0m"
            else
              echo -e "\033[0;33m LDAP and/or htpasswd Identity providers have been deleted, but other different IDPs are installed. Check the cluster \033[0m"
            fi
  fi
}

while [ "$#" -gt 0 ]; do
  case $1 in
    --host)
      shift
      OC_HOST=$1
      shift
      ;;
    
    --use-ocm)
      shift
      USE_OCM_IDP=$1
      shift
      ;;

    --ocm-token)
      shift
      OCM_TOKEN=$1
      shift
      ;;

    --ocm-env)
      shift
      OCM_ENV=$1
      shift
      ;;

    --cluster-admin-user)
      shift
      ADMIN_USERNAME=$1
      shift
      ;;

    --cluster-admin-password)
      shift
      ADMIN_PASS=$1
      shift
      ;;

    *)
      echo "Unknown command line switch: $1"
      exit 1
      ;;
  esac
done


# printf "Insert cluster admin user's password:"
# read -s ADMIN_PASS
if [ "${USE_OCM_IDP}" -eq 1 ]
      then
          perform_ocm_login
fi
check_installation
uninstall_identity_provider
check_uninstallation