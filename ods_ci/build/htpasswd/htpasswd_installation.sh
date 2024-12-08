#!/bin/bash
HTPASSWD_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $HTPASSWD_PATH

touch users.txt
function generate_htpasswd_user(){
for i in {1..10}
  do
    htpasswd -b -B users.txt $1$i $2 
  done
}

generate_htpasswd_user $HTTP_USER_ADMIN $TEST_PASSWD
generate_htpasswd_user $HTTP_USER_USER $TEST_PASSWD
generate_htpasswd_user $HTTP_USER_NOACCESS $TEST_PASSWD
htpasswd -b -B users.txt $HTTP_CLUSTER_ADMIN $TEST_ADMIN_PASSWD

function generate_special_user(){
declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
for char in "${StringArray[@]}"; 
  do
    htpasswd -b -B users.txt $1$char $2 
  done
}

generate_special_user $HTTP_USER_SPECIAL $TEST_PASSWD

oc create secret generic htpasswd-secret --from-file=htpasswd=$HTPASSWD_PATH/users.txt -n openshift-config || echo "htpasswd secret exists"
rm $HTPASSWD_PATH/users.txt