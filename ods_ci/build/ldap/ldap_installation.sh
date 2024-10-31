#!/bin/bash
LDAP_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
oc create secret generic ldap-bind-password --from-literal=bindPassword=adminpassword -n openshift-config || echo "ldap secret exists"
oc create ns openldap

LDAP_USERS=""
LDAP_PASSWORDS=""

function add_ldap_users(){
for i in {1..20}
  do
    LDAP_USERS+="$1$i,"
    LDAP_PASSWORDS+="${TEST_PASSWD},"
  done
}

add_ldap_users ldap-$RAND-admin
add_ldap_users ldap-$RAND-user
add_ldap_users ldap-$RAND-noaccess

function add_special_user(){
declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "|" "@" ";" "<" ">")
for char in "${StringArray[@]}"; 
  do
    LDAP_USERS+="$1$char,"
    LDAP_PASSWORDS+="${TEST_PASSWD},"
  done
}
add_special_user ldap-$RAND-special

LDAP_USERS=${LDAP_USERS::-1}
LDAP_PASSWORDS=${LDAP_PASSWORDS::-1}
LDAP_ADMIN_PASS="adminpass-$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 6)"

echo "LDAP_USERS: $LDAP_USERS"
echo "LDAP_PASSWORDS: $LDAP_PASSWORDS"
ENCODED_USERS=$(echo -n $LDAP_USERS | base64 -w 0)
ENCODED_PASSWORDS=$(echo -n $LDAP_PASSWORDS | base64 -w 0)
ENCODED_ADMINPASS=$(echo -n $LDAP_ADMIN_PASS | base64 -w 0)

sed -i'' -e "s|FOO_USER|$ENCODED_USERS|g" $LDAP_PATH/ldap.yaml
sed -i'' -e "s/FOO_PASSWORD/$ENCODED_PASSWORDS/g" $LDAP_PATH/ldap.yaml
sed -i'' -e "s/FOO_ADMIN/$ENCODED_ADMINPASS/g" $LDAP_PATH/ldap.yaml

oc apply -f $LDAP_PATH/ldap.yaml

sleep 60s
