#!/bin/bash
HTPASSWD_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

cd $HTPASSWD_PATH

touch users.txt
function generate_htpasswd_user(){
for i in {1..20}
  do
    htpasswd -b -B users.txt $1$i $2 
  done
}

generate_htpasswd_user htpasswd-$RAND-admin $TEST_PASSWD
generate_htpasswd_user htpasswd-$RAND-user $TEST_PASSWD
generate_htpasswd_user htpasswd-$RAND-noaccess $TEST_PASSWD
htpasswd -b -B users.txt htpasswd-$RAND-cluster-admin-user $TEST_ADMIN_PASSWD

function generate_special_user(){
declare -a StringArray=("." "^" "$" "*" "+" "?" "(" ")" "[" "]" "{" "}" "\\" "|" "@" ";" "<" ">")
for char in "${StringArray[@]}"; 
  do
    htpasswd -b -B users.txt $1$char $2 
  done
}

generate_special_user htpasswd-$RAND-special $TEST_PASSWD

oc create secret generic htpasswd-secret --from-file=htpasswd=$HTPASSWD_PATH/users.txt -n openshift-config || echo "htpasswd secret exists"
rm $HTPASSWD_PATH/users.txt