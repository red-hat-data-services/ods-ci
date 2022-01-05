#/bin/bash

# todo:
## create one true cluster admin
## create X fake users
## load-test + aggregation of results
## remove all pvcs.
## remove all users.

fakeadmin=$(yq  e '.OCP_ADMIN_USER.USERNAME' ./test-variables.yml)
fakeadminpass=$(yq  e '.OCP_ADMIN_USER.PASSWORD' ./test-variables.yml)

fakeadmin="${fakeadmin:-fakeadmin}"
fakeadminpass="${fakeadminpass:-fakeadminpass}"


fakeuser="${fakeuser:-fakeuser}"
fakeuserpass=$(yq  e '.TEST_USER.PASSWORD' ./test-variables.yml)
fakeuserpass="${fakeuserpass:-fakepass}"

#debug
#set | grep fake

# htpasswd -c -B -b htpasswd.txt ${fakeuser}001 ${fakeadminpass} > /dev/null 2>&1
htpasswd -c -B -b htpasswd.txt ${fakeadmin} ${fakeadminpass} > /dev/null 2>&1
for i in {001..200};
do
   htpasswd  -B -b htpasswd.txt ${fakeuser}$i ${fakeuserpass} > /dev/null 2>&1
done

export KUBECONFIG=./kubeconfig
# update the content of the secret:
oc create secret generic htpasswd-secret \
    --from-file=htpasswd=htpasswd.txt \
    --dry-run=client -o yaml -n openshift-config \
    | oc apply -f -

# oc apply -f - <<EOF
# ---
# apiVersion: config.openshift.io/v1
# kind: OAuth
# metadata:
#   name: cluster
# spec:
#   identityProviders:
#   - name: fakeusers
#     mappingMethod: claim
#     type: HTPasswd
#     htpasswd:
#       fileData:
#         name: fakeusers-htpass-secret
# EOF



  # identityProviders:
  # - name: fakeusers
  #   mappingMethod: claim
  #   type: HTPasswd
  #   htpasswd:
  #     fileData:
  #       name: fakeusers-htpass-secret


#debug
#cat htpasswd.txt


# oc create secret generic htpass-secret --from-file=htpasswd=htpasswd.txt -n openshift-config

function runfakeuser(){
    mkdir -p ./test-output/${fakeuser}$1
    cp ./test-variables.yml ./test-output/${fakeuser}$1/var.yml
    cp ./kubeconfig ./test-output/${fakeuser}$1/kubeconfig
    export fake="${fakeuser}${1}"
    export fakeuserpass="${fakeuserpass}"
    #echo $fake
    yq e -i '
        .TEST_USER.USERNAME = strenv(fake)  |
        .TEST_USER.PASSWORD = strenv(fakeuserpass)
        ' ./test-output/${fakeuser}$1/var.yml

    # podman run --rm -d \
    # podman run --rm -it \
    podman run --rm  \
        -v $PWD/test-output/${fakeuser}$1/var.yml:/tmp/ods-ci/test-variables.yml:Z \
        -v $PWD/test-output/${fakeuser}$1:/tmp/ods-ci/test-output:Z \
        -v $PWD/test-output/${fakeuser}$1/kubeconfig:/tmp/.kube/config:Z \
        -e RUN_SCRIPT_ARGS='--test-case tests/Tests/500__jupyterhub/test-jupyterlab-git-notebook.robot'  \
        ods-ci:master

}

runfakeuser 001

exit

for i in {001..001};
do
    runfakeuser $i
done

exit


## remember to clean out all the PVCs at the end.
# for i in {001..040};
# do
#     oc -n rhods-notebooks get pvc jupyterhub-nb-fakeuser$i-pvc
#     oc -n rhods-notebooks delete pvc jupyterhub-nb-fakeuser$i-pvc
# done

