# ODS-CI Container Image

A [Dockerfile](Dockerfile) is available for running tests in a container.
The latest build can be downloaded from: https://quay.io/odsci/ods-ci:latest

eg: podman pull quay.io/odsci/ods-ci:latest

```bash
## I assume you have yq.
## get oc from your own cluster

oc_url="$(yq  e '.OCP_CONSOLE_URL' ./test-variables.yml \
    | sed 's/console\-/downloads\-/g' )amd64/linux/oc.tar" ; echo $oc_url

curl -L ${oc_url} \
  -o - | tar xf - > ./oc

# Build the container (optional if you dont want to use the latest from quay.io/odsci)
podman build -t ods-ci:master -f build/Dockerfile .

# create the output directory
mkdir -p $PWD/test-output

user=$(yq  e '.OCP_ADMIN_USER.USERNAME' ./test-variables.yml)
pass=$(yq  e '.OCP_ADMIN_USER.PASSWORD' ./test-variables.yml)
auth=$(yq  e '.OCP_ADMIN_USER.AUTH_TYPE' ./test-variables.yml)
host=$(yq  e '.OCP_API_URL' ./test-variables.yml)

podman run --rm -it \
    --entrypoint oc \
    -v ${PWD}/kubeconfig:/tmp/.kube/config:Z \
    ods-ci:master \
    login "${host}" \
        --username "${user}" \
        --password "${pass}"

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
# Run a single test
podman run --rm -it \
    -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z \
    -v $PWD/test-output:/tmp/ods-ci/test-output:Z \
    -v $PWD/kubeconfig:/tmp/.kube/config:Z \
    -e RUN_SCRIPT_ARGS='--test-case tests/Tests/500__jupyterhub/test-jupyterlab-git-notebook.robot'  \
    ods-ci:master

```

### Running the ods-ci container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. You can use [this](./ods-ci.pod.yaml) PersistentVolumeClaim and Pod definition to deploy the ods-ci container.  NOTE: This example pod attaches a PVC to preserve the test artifacts directory between runs and mounts the test-variables.yml file from a Secret.

```
# Creates a Secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file test-variables.yml
```


### creating many loadtest users in OpenShift

```

bash launch.many.sh
```


<!--
```bash
oc get secrets htpasswd-secret -n openshift-config

htpasswd -c htpasswd.txt userone


podman run --rm -it \
    -v $PWD/user01.yml:/tmp/ods-ci/test-variables.yml:Z \
    -v $PWD/test-output:/tmp/ods-ci/test-output:Z \
    -v $PWD/kubeconfig:/tmp/.kube/config:Z \
    -e RUN_SCRIPT_ARGS='--test-case tests/Tests/500__jupyterhub/test-jupyterlab-git-notebook.robot'  \
    ods-ci:master




htpasswd -c -B -b htpasswd.txt admin-loadtest P@ss-loadtest123
for i in {001..100};
do
   htpasswd  -B -b htpasswd.txt fakeuser$i fakepass
done



function fakeuser(){
    mkdir -p ./test-output/fakeuser$1
    cp ./test-variables.yml ./test-output/fakeuser$1/var.yml
    cp ./kubeconfig ./test-output/fakeuser$1/kubeconfig
    export fake="fakeuser${1}"
    echo $fake
    yq e -i '
        .TEST_USER.USERNAME = strenv(fake)  |
        .TEST_USER.PASSWORD = "fakepass"
        ' ./test-output/fakeuser$1/var.yml

    # podman run --rm -d \
    podman run --rm -it \
        -v $PWD/test-output/fakeuser$1/var.yml:/tmp/ods-ci/test-variables.yml:Z \
        -v $PWD/test-output/fakeuser$1:/tmp/ods-ci/test-output:Z \
        -v $PWD/test-output/fakeuser$1/kubeconfig:/tmp/.kube/config:Z \
        -e RUN_SCRIPT_ARGS='--test-case tests/Tests/500__jupyterhub/test-jupyterlab-git-notebook.robot'  \
        ods-ci:master

}

for i in {006..010};
do
    fakeuser $i &
done



for i in {001..005};
do
    fakeuser $i
done
``` -->


