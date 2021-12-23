# ODS-CI Container Image

A [Dockerfile](Dockerfile) is available for running tests in a container.
The latest build can be downloaded from: https://quay.io/odsci/ods-ci:latest

eg: podman pull quay.io/odsci/ods-ci:latest

```bash
# Build the container (optional if you dont want to use the latest from quay.io/odsci)
podman build -t ods-ci:master -f build/Dockerfile .

## I assume you have yq.
## get oc from your own cluster

oc_url="$(yq  e '.OCP_CONSOLE_URL' ./test-variables.yml \
    | sed 's/console\-/downloads\-/g' )amd64/linux/oc.tar" ; echo $oc_url

curl -L ${oc_url} \
  -o - | tar xf - > ./oc

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
