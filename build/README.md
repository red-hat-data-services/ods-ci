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
podman build -t ods-ci:v2 -f build/Dockerfile .

# create the output directory
mkdir -p $PWD/test-output

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
# Run a single test
podman run --rm -it \
    -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z \
    -v $PWD/test-output:/tmp/ods-ci/test-output:Z \
    -e RUN_SCRIPT_ARGS='--test-case tests/Tests/500__jupyterhub/test-jupyterlab-git-notebook.robot'  \
    ods-ci:master




```

### Running the ods-ci container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. You can use [this](./ods-ci.pod.yaml) PersistentVolumeClaim and Pod definition to deploy the ods-ci container.  NOTE: This example pod attaches a PVC to preserve the test artifacts directory between runs and mounts the test-variables.yml file from a Secret.

```
# Creates a Secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file test-variables.yml
```


### creating many loadtest users in podman

```
bash launch.many.podman.sh
```

## OpenShift.

### Push the image to quay

```bash
podman login quay.io
podman tag localhost/ods-ci:master quay.io/egranger/ods-ci:v1
podman push                        quay.io/egranger/ods-ci:v1
podman tag localhost/ods-ci:v2 quay.io/egranger/ods-ci:v2
podman push                    quay.io/egranger/ods-ci:v2
```

### Create project in openshift

```
oc create ns loadtest

```

#### create secret

```bash
oc -n loadtest delete secret ods-ci-test-variables
oc -n loadtest create secret generic ods-ci-test-variables --from-file test-variables.yml
```


### define 1 pod

```bash
oc -n loadtest delete -f ./build/ods-ci.job.yaml ; oc -n loadtest apply -f ./build/ods-ci.job.yaml

```

### define x jobs

### keeping the results around
