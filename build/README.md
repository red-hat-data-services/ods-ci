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
    --service-account (default: ""): if assigned, ODS-CI will try to log into the cluster using the given service account. ODS-CI automatically creates SERVICE_ACCOUNT.NAME and SERVICE_ACCOUNT.FULL_NAME global variables to be used in tests.
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

Examples of test execution using the container - with email report enabled
```bash
# example - send results by email using localhost
$ podman run --rm -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z
                  -v $PWD/test-output:/tmp/ods-ci/test-output:Z
                  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                  ods-ci:master
```
```bash
# example - send results by email using gmail smtp
$ podman run --rm -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z
  -v $PWD/test-output:/tmp/ods-ci/test-output:Z
  -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com  --email-server smtp.gmail.com:587 --email-server-user mymail@redhat.com  --email-server-pw <password>'
  -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
  ods-ci:master

*using gmail smtp, the sender email address will be overwritten by --email-server-user
**the container sends the entire result artifacts directory (i.e., images plus html/xml reports) only if the overall size is less than 20MB.
  Otherwise, it sends only the html and xml files.
```
****
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

### Deploy postfix smtp server
To use localhost as smtp server while running ods-ci container, you could leverage on a postfix container. One [example](./Dockerfile_smtpserver) is reported in this repo.
If you are running ods-ci container on your local machine, you could use [podman](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods) to run both the containers, like this:
```bash
podman run -d --pod new:<pod_name>  <postfix_imagename>:<image_label>
podman run --rm --pod=<pod_name>
                -v $PWD/test-variables.yml:/tmp/ods-ci/test-variables.yml:Z
                -v $PWD/test-output:/tmp/ods-ci/test-output:Z
                -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                ods-ci:master

```
If you are running ods-ci container on a cluster you could use the pod template [ods-ci.pod_with_postfix.yaml](./ods-ci.pod_with_postfix.yaml) from this repository.
Keep in mind that this solution is not working on OSD clusters as reported [here](https://access.redhat.com/solutions/880233).
