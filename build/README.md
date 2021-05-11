# ODS-CI Container Image

A [Dockerfile](Dockerfile) is available for running tests in a container.

```bash
# Build the container
$ podman build -t ods-ci:master -f build/Dockerfile .

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
$ podman run --rm -v $PWD/test-variables.yml:/root/ods-ci/test-variables.yml:Z -v $PWD/test-output:/root/ods-ci/test-output:Z ods-ci:master
```

### Running the ods-ci container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. You can use [this](./ods-ci.pod.yaml) PersistentVolumeClaim and Pod definition to deploy the ods-ci container.  NOTE: This example pod attaches a PVC to preserve the test artifacts directory between runs and mounts the test-variables.yml file from a Secret.

```
# Creates a Secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file test-variables.yml
```
