# ODS-CI Container Image

A [Dockerfile](Dockerfile) is available for running tests in a container. Below you can read how to build and run ods-ci test suites container.

```bash
# Build the container (optional if you dont want to use the latest from quay.io/odsci)
$ podman build -t ods-ci:master -f build/Dockerfile .

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
$ podman run --rm -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z
                  -v $PWD/test-output:/tmp/ods-ci/test-output:Z
                  ods-ci:master
```
Additional arguments for container build
```bash
# oc CLI version to install
OC_VERSION (default: 4.10)
OC_CHANNEL (default: stable)

# example
podman build -t ods-ci:master -f build/Dockerfile .
             --build-arg OC_CHANNEL=latest
             --build-arg OC_VERSION=4.9

```
Additional arguments for container run
```
# env variables to control test execution
RUN_SCRIPT_ARGS:
  --skip-oclogin (default: false): script does not perform login using OC CLI
  --set-urls-variables (default: false): script gets automatically the cluster URLs (i.e., OCP Console, RHODS Dashboard, OCP API Server)
  --include: run only test cases with the given tags (e.g., --include Smoke --include XYZ)
  --exclude: do not run the test cases with the given tag (e.g., --exclude LongLastingTC)
  --test-variable: set a global RF variable
  --test-variables-file (default: test-variables.yml): set the RF file containing global variables to use in TCs
  --test-case: run only the test cases from the given robot file
  --test-artifact-dir: set the RF output directory to store log files

ROBOT_EXTRA_ARGS: it takes any robot framework arguments. Look at robot --help to see all the options (e.g., --log NONE, --dryrun )
```

Example of test execution using the container
```bash
# example
$ podman run --rm -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z
                  -v $PWD/test-output:/tmp/ods-ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='-l NONE'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                  ods-ci:master
```

### Running the ods-ci container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. You can use [this](./ods-ci.pod.yaml) PersistentVolumeClaim and Pod definition to deploy the ods-ci container.
Before deploying the pod:
- create the namespace/project "ods-ci"
- apply the rbac settings
- create a secret to store your "test-variables.yml" file

NOTE: This example pod attaches a PVC to preserve the test artifacts directory between runs and mounts the test-variables.yml file from a Secret.

```
# Apply rbac settings
oc apply -f ods_ci_rbac.yaml

# Creates a Secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file test-variables.yml
```
