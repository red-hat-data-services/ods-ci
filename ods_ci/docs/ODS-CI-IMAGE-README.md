# ODS-CI Container Image

## Important Note
    With the switch to Poetry, the project directory structure has changed. You are now require to launch these commands from the root of the ods-ci repo, but the paths have to take into account the relative subfolder ods_ci. The examples shown here already deal with this new subfolder, but take care of double checking your paths if writing commands manually.

A [Dockerfile](ods_ci/build/Dockerfile) is available for running tests in a container. Below you can read how to build and run ods-ci test suites container.

****
# Build

```bash
# Build the container (optional if you dont want to use the tags from quay.io/repository/modh/ods-ci)
$ podman build -t ods-ci:<mytag> -f ods_ci/build/Dockerfile .

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  ods-ci:<mytag>
```
Additional arguments for container build
```bash
# oc CLI version to install
OC_VERSION (default: 4.10)
OC_CHANNEL (default: stable)

# example
podman build -t ods-ci:master -f ods_ci/build/Dockerfile .
             --build-arg OC_CHANNEL=latest
             --build-arg OC_VERSION=4.12
```

****
# Run
## Arguments to control container run:

* RUN_SCRIPT_ARGS: it takes the run arguments to pass to ods-ci robot wrapper script ```run_robot_test.sh```. All the details in the dedicated document file [RUN_ARGUMENTS.md](ods_ci/docs/RUN_ARGUMENTS.md)

* ROBOT_EXTRA_ARGS: it takes any robot framework arguments. Look at robot --help to see all the options (e.g., --log NONE, --dryrun ) or at official [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html) 

* SET_ENVIRONMENT (default: 0): it enables/disables the installation of Identity providers (HTPassword and LDAP) in the cluster. If 1, the IDPs are going to be installed before running the tests

  * If SET_ENVIRONMENT = 1:
    - OC_HOST: it contains the OpenShift API URL of the test cluster where the Identity Providers are going to be installed and tests are going to be executed.
    - USE_OCM_IDP (default: 1): it sets the IDP creation script to use either OCM (OpenShift Cluster Manager) CLI and APIs or OC CLI to create the IDPs in the cluster. If it is sets to 0, OC CLI is used.
    * If USE_OCM_IDP = 1:
      - OCM_TOKEN: it contains the authorization token to allow ODS-CI to install IDPs in the test cluster using OCM
      - OCM_ENV (default: stage): it contains the OCM environment name, e.g., stage vs production

## Running the ODS-CI container image from terminal

**Example 1** of test execution using the container - minimum configuration
```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --include Smoke'
                  ods-ci:1.24.0
```

**Example 2** of test execution using the container - adding some ```ROBOT_EXTRA_ARGS```
```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='-L DEBUG --dryrun'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --include Smoke'
                  ods-ci:1.24.0
```

**Example 3** test execution using the container with email report enabled - localhost as email server
```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --include Smoke'
                  ods-ci:1.24.0
```
**Example 4** test execution using the container with email report enabled - gmail as email server

```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com  --email-server smtp.gmail.com:587 --email-server-user mymail@redhat.com  --email-server-pw <password>'
  -e RUN_SCRIPT_ARGS='--skip-oclogin false --include Smoke'
  ods-ci:1.24.0

# *using gmail smtp, the sender email address will be overwritten by --email-server-user
# **the container sends the entire result artifacts directory (i.e., images plus html/xml reports) only if the overall size is less than 20MB.
#  Otherwise, it sends only the html and xml files.
```
****
## Running the ODS-CI container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. You can use [this](ods_ci/build/ods-ci.pod.yaml) PersistentVolumeClaim and Pod definition to deploy the ods-ci container.
Before deploying the pod:
- create the namespace/project "ods-ci"
- apply the rbac settings
- create a secret to store your "test-variables.yml" file

NOTE: This example pod attaches a PVC to preserve the test artifacts directory between runs and mounts the test-variables.yml file from a Secret.

```
# Apply rbac settings
oc apply -f ods_ci_rbac.yaml

# Creates a Secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file ods_ci/test-variables.yml
```

### Deploy postfix smtp server
To use localhost as smtp server while running ods-ci container, you could leverage on a postfix container. One [example](./Dockerfile_smtpserver) is reported in this repo.
If you are running ods-ci container on your local machine, you could use [podman](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods) to run both the containers, like this:
```bash
podman run -d --pod new:<pod_name>  <postfix_imagename>:<image_label>
podman run --rm --pod=<pod_name>
                -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                ods-ci:master

```
If you are running ods-ci container on a cluster you could use the pod template [ods-ci.pod_with_postfix.yaml](./ods-ci.pod_with_postfix.yaml) from this repository.
Keep in mind that this solution is not working on OSD clusters as reported [here](https://access.redhat.com/solutions/880233).
