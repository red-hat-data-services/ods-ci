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
## Running the ods-ci container image from terminal

**Example 1** of test execution using the container
```bash
# example
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='-l NONE'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                  ods-ci:1.24.0
```

### Additional arguments for container run:
```
# env variables to control test execution
RUN_SCRIPT_ARGS:
  --skip-oclogin (default: false): script does not perform login using OC CLI
    --service-account (default: ""): if assigned, ODS-CI will try to log into the cluster using the given service account.
            ODS-CI automatically creates SERVICE_ACCOUNT.NAME and SERVICE_ACCOUNT.FULL_NAME global variables to be used in tests.
    --sa-namespace (default: "default"): the namespace where the service account is created
  --set-urls-variables (default: false): script gets automatically the cluster URLs (i.e., OCP Console, RHODS Dashboard, OCP API Server)
  --include: run only test cases with the given tags (e.g., --include Smoke --include XYZ)
  --exclude: do not run the test cases with the given tag (e.g., --exclude LongLastingTC)
  --test-variable: set a global RF variable
  --test-variables-file (default: test-variables.yml): set the RF file containing global variables to use in TCs
  --test-case: run only the test cases from the given robot file
  --test-artifact-dir: set the RF output directory to store log files
  --email-report (default: false): send the test run artifacts via email
    --email-from: (mandatory if email report is true) set the sender email address
    --email-to: (mandatory if email report is true) set the email address which will receive the result artifacts
    --email-server (default: localhost): set the smtp server to use, e.g., smtp.gmail.com:465 (the port specification is not mandatory, the default value is 587)
    --email-server-user: (optional, depending on the smtp server) username to access smtp server
    --email-server-pw: (optional, depending on the smtp server) password to access smtp server
    --email-server-ssl (default: false): if true, it forces the usage of encrypted connection (TLS)
    --email-server-unsecure (default: false): no encryption applied, using SMTP unsecure connection

* The container uses STARTTLS protocol by default if --email-server-ssl and --email-server-unsecure are set to false

ROBOT_EXTRA_ARGS: it takes any robot framework arguments. Look at robot --help to see all the options (e.g., --log NONE, --dryrun )

SET_ENVIRONMENT (default:0): it enables/disables the installation of Identity providers (HTPassword and LDAP) in the cluster. If 1, the IDPs are going to be installed before running the tests

If SET_ENVIRONMENT = 1:
- OC_HOST: it contains the OpenShift API URL of the test cluster where the Identity Providers are going to be installed and tests are going to be executed.
- USE_OCM_IDP (default: 1): it sets the IDP creation script to use either OCM (OpenShift Cluster Manager) CLI and APIs or OC CLI to create the IDPs in the cluster. If it is sets to 0, OC CLI is used.
  If USE_OCM_IDP = 1:
    - OCM_TOKEN: it contains the authorization token to allow ODS-CI to install IDPs in the test cluster using OCM
    - OCM_ENV (default: stage): it contains the OCM environment name, e.g., stage vs production
```

**Example 2** test execution using the container with email report enabled: localhost as email server
```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                  ods-ci:1.24.0
```
**Example 3** test execution using the container with email report enabled: gmail as email server

```bash
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
  -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com  --email-server smtp.gmail.com:587 --email-server-user mymail@redhat.com  --email-server-pw <password>'
  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
  ods-ci:1.24.0

# *using gmail smtp, the sender email address will be overwritten by --email-server-user
# **the container sends the entire result artifacts directory (i.e., images plus html/xml reports) only if the overall size is less than 20MB.
#  Otherwise, it sends only the html and xml files.
```
****
## Running the ods-ci container image in OpenShift

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
