#!/bin/bash
user_list=""
password_list=""

function add_users_to_list(){
for i in {1..10}
  do
    user_list+="$1$i,"
    password_list+="${TEST_PASSWD},"
  done
}

add_users_to_list $LDAP_USER_ADMIN
add_users_to_list $LDAP_USER_USER
add_users_to_list $LDAP_USER_NOACCESS

oc create ns openldap
oc create secret generic openldap \
   -n openldap \
   --from-literal=adminpassword=adminpassword \
   --from-literal=passwords=${password_list%,} \
   --from-literal=users=${user_list%,}

LDAP_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
oc create secret generic ldap-bind-password --from-literal=bindPassword=adminpassword -n openshift-config || echo "ldap secret exists"
oc apply -f $LDAP_PATH/ldap.yaml
sleep 25s
