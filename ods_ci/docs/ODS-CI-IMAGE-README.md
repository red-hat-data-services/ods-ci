# ODS-CI Container Image

## Important Note
    With the switch to Poetry, the project directory structure has changed. You are now require to launch these commands from the root of the ods-ci repo, but the paths have to take into account the relative subfolder ods_ci. The examples shown here already deal with this new subfolder, but take care of double checking your paths if writing commands manually.

A [Dockerfile](../build/Dockerfile) is available for running tests in a container. Below you can read how to build and run ods-ci test suites container.

****
# Build

```bash
# Build the container (optional if you dont want to use the tags from quay.io/repository/modh/ods-ci)
$ podman build -t ods-ci:<mytag> -f ods_ci/build/Dockerfile .

# Mount a file volume to provide a test-variables.yml file at runtime
# Mount a volume to preserve the test run artifacts
$ podman run --rm -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                  ods-ci:<mytag>
```
Additional arguments for container build
* OC_VERSION (default: 4.13): version of OC CLI to download
* OC_CHANNEL (default: stable): release channel to download OC CLI from,e.g, latest, candidate, etc
```bash
podman build -t ods-ci:main -f ods_ci/build/Dockerfile .
             --build-arg OC_CHANNEL=latest
             --build-arg OC_VERSION=4.12
```

****
# Run
## Arguments to control container run:

* ```RUN_SCRIPT_ARGS```: it takes the run arguments to pass to ods-ci robot wrapper script ```run_robot_test.sh```. All the details in the dedicated document file [RUN_ARGUMENTS.md](./RUN_ARGUMENTS.md)

* ```ROBOT_EXTRA_ARGS```: it takes any robot framework arguments. Look at robot --help to see all the options (e.g., ```--log NONE```, ```--dryrun```) or at official [Robot Framework User Guide](https://robotframework.org/robotframework/latest/RobotFrameworkUserGuide.html) 

* ```SET_ENVIRONMENT``` (default: 0): it enables/disables the installation of Identity providers (HTPassword and LDAP) in the cluster. If 1, the IDPs are going to be installed before running the tests

  * If ```SET_ENVIRONMENT``` = 1:
    - ```OC_HOST```: it contains the OpenShift API URL of the test cluster where the Identity Providers are going to be installed and tests are going to be executed.
    - ```USE_OCM_IDP``` (default: 1): it sets the IDP creation script to use either OCM (OpenShift Cluster Manager) CLI and APIs or OC CLI to create the IDPs in the cluster. If it is sets to 0, OC CLI is used.
      - If ```USE_OCM_IDP``` = 1:
        - ```OCM_TOKEN```: it contains the authorization token to allow ODS-CI to install IDPs in the test cluster using OCM
        - ```OCM_ENV```: it contains the OCM environment name, e.g., staging vs production. If not set, OCM CLI assumes it is production.
    * ```RETURN_PW``` (default:1): 
      - if ```RETURN_PW``` = 1: CLI will prints the user password and cluster admin username. It's recommended to use for Debug purposes only, where the CLI output is not made publicly available.
    * ```ods_ci/configs/templates/user_config.json```: this JSON file is necessary to instruct the image about desired user configuration. Check the dedicated section below.
  

## User Configuration JSON File
As mentioned in the previous paragraph, if you enable automatic IDP creation you need to either pass a custom configuration file or use the default one.

You find field description inline in the below JSON file. Before reading it, there are a couple of notes:
1. the install scripts assumes  you want to install a LDAP and HTPASSWD identity provider. 
2. it assumes that the cluster-admin user is from HTP identity provider.
3. it asusmes the users in test-variables.yml are mapped to LDAP users only.

```json
{
    "idp":{
        "ldap": {
            // prefix is the first part of the usernames, e.g., professor-xyzxyzxyzxyz10
            "prefixes": [
                "professor-",
                "student-",
                "operator-"
            ],
            // suffix is the part(s) after the prefix: it accepts:
            // - "incremental": adds a numeric suffix after the prefix, the range is [1, "n_users"]
            // - "incremental_with_rand_base": it adds a randomly generate portion before the numeric suffix. The number of random chars is controled by "rand_length" attribute
            // - "custom": it adds to the suffix a custom suffix extracted from the passed "list" attribute. The number of users is controled by the length of the given list.
            // - "custom_with_rand_base": t adds a randomly generate portion before the custom suffix. The number of random chars is controled by "rand_length" attribute.
            "suffixes": {
                "professor-": {
                    "type": "incremental",
                    "rand_length": null,
                    "n_users": 5
                },
                "student-": {
                    "type": "incremental_with_rand_base",
                    "rand_length": 20,
                    "n_users": 20
                }
            },
            // this is the pw for ldap users. If it is sets to "<GEN_RANDOM_PW>" it generates an alphanumeric random password.
            "pw": "<GEN_RAMDOM_PW>",
            // this is the mapping to the users in test-variables.yml file, which are used by automated tests. if you used random generated suffix, you can use the placeholder "<RAND_BASE>" to let script handling it.
            "TEST_USER": "professor-<RAND_BASE>11",
            "TEST_USER_2": "student-<RAND_BASE>2",
            "TEST_USER_3": "student-<RAND_BASE>3",
            "TEST_USER_4":  "student-<RAND_BASE>4",
            // all the user with the same prefix will be added to the mapped group.
            "groups_map":{
                "professor-": [
                    "professors"
                ],
                "student-": [
                    "users"
                ]
            }
        },
        "htpasswd": {
            "prefixes": [
                "operator-"
            ],
            "suffixes": {
                "operator-": {
                    "type": "custom_with_rand_base",
                    "rand_length": 20,
                    "list": ["A","B","C"]
                }
            },
            "pw": "<GEN_RAMDOM_PW>",
            // assignes cluster admin permissions to one of the given htp users
            "cluster_admin_username":   "operator-<RAND_BASE>B"
        }
    }
}
```

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
```
**NOTES**
* using gmail smtp, the sender email address will be overwritten by ```--email-server-user```
* the container sends the entire result artifacts directory (i.e., images plus html/xml reports) only if the overall size is less than 20MB.
  Otherwise, it sends only the html and xml files.
****
## Running the ODS-CI container image in OpenShift

After building the container, you can deploy the container in a pod running on OpenShift. See [ods-ci_pod.yaml](./ods-ci_pod.yaml) as example.


*Pre-req task*
- login to a test cluster with ```oc login ...``` command. See [official documentation](https://docs.openshift.com/online/pro/cli_reference/get_started_cli.html) for more details
- create the namespace/project "ods-ci"
- create the service account by applying the rbac settings. See [this](./ods-ci_rbac.yaml)
- create a secret to store your "test-variables.yml" file. Refer to main [README.md](ods_ci/README.md) to get your test-variables.yml file.
- [optional] create a pull secret to fetch the ods-ci image from your registry if it is private. Ensure to patch the SA created at the previous step in order to add the pull secret name
- [optional] create a PVC to store test artifacts. It is embedded in the sample [ods-ci_pod.yaml](./ods-ci_pod.yaml). If you don't want it, you can modify the YAML file as per your need


**Example 1** steps to run ods-ci pod in a OpenShift cluster
```bash
# create service account
oc apply -f ods_ci_rbac.yaml -n ods-ci

# create a secret with test variables that can be mounted in ODS-CI container
oc create secret generic ods-ci-test-variables --from-file ods_ci/test-variables.yml -n ods-ci

# Optional: create a secret with user_config.json that can be mounted in ODS-CI container
oc create secret generic ods-ci-user-config --from-file ods_ci/user_config.json -n ods-ci

# Optional: create registry pull secret and patch SA
oc create secret docker-registry  ods-ci-pull-secret --docker-server='quay.io' --docker-username='my-username'  --docker-password='my-pw' --docker-email='my-email@email.com' -n ods-ci

oc patch serviceaccount rhods-test-runner -p '{"imagePullSecrets": [{"name": "ods-ci-pull-secret"}]}' -n ods-ci

# deploy ods-ci pod and its PVC
oc apply -f ods-ci_pod.yaml -n ods-ci
```

**Example 2**
test execution using the container in a OpenShift pod - minimum configuration, extracted from [ods-ci_pod.yaml](./ods-ci_pod.yaml)
```yaml
      image: quay.io/modh/ods-ci:latest
      imagePullPolicy: Always
      name: ods-ci-testrun
      env:
        - name: RUN_SCRIPT_ARGS
          value: "--test-variables-file /tmp/ods-ci-test-variables/test-variables.yml --skip-oclogin true --set-urls-variables true --include Smoke"
        - name: ROBOT_EXTRA_ARGS
          value: "--L DEBUG --dryrun"
      volumeMounts:
        - name: ods-ci-test-variables
          mountPath: /tmp/ods-ci-test-variables
        - mountPath: /tmp/ods-ci/ods_ci/test-output
          name: ods-ci-test-output
```
**Example 3** test execution using the container in a OpenShift pod - install IDP with OCM CLI/APIs, extracted from [ods-ci_pod_ocm_idp.yaml](./ods-ci_pod_ocm_idp.yaml)
```yaml
      image: quay.io/modh/ods-ci:latest
      imagePullPolicy: IfNotPresent
      name: ods-ci-testrun
      serviceAccountName: rhods-test-runner
      env:
        - name: OC_HOST
          value: "https://api.mycluster.abcd.domain.org:1234"
        - name: SET_ENVIRONMENT
          value: "1"
        - name: OCM_ENV
          value: "staging"                    
        - name: OCM_TOKEN
          value: "my-ocm-token"
        - name: RUN_SCRIPT_ARGS
          value: "--skip-oclogin false --set-urls-variables true"
        - name: ROBOT_EXTRA_ARGS
          value: "-i Smoke --dryrun"
      volumeMounts:
        - mountPath: /tmp/ods-ci/ods_ci/configs/templates/user_config.json
          name: ods-ci-user-config
          subPath: user_config.json
        - mountPath: /tmp/ods-ci/test-output
          name: ods-ci-test-output
```

**Example 4** test execution using the container in a OpenShift pod - install IDP without OCM CLI/APIs, extracted from [ods-ci_pod_oc_idp.yaml](./ods-ci_pod_oc_idp.yaml)
```yaml
      image: quay.io/modh/ods-ci:latest
      imagePullPolicy: IfNotPresent
      name: ods-ci-testrun
      serviceAccountName: rhods-test-runner
      env:
        # Use this environment variable to pass args to the ods-ci run script in the container
        - name: OC_HOST
          value: "https://api.mycluster.abcd.domain.org:1234"
        - name: SET_ENVIRONMENT
          value: "1"
        - name: OCM_ENV
          value: "staging"                    
        - name: OCM_TOKEN
          value: "my-ocm-token"
        - name: RUN_SCRIPT_ARGS
          value: "--skip-oclogin false --set-urls-variables true"
        - name: ROBOT_EXTRA_ARGS
          value: "-i Smoke --dryrun"
```
**NOTE**: when letting the container install the IDPs, the container automatically modifies the test-variables.yml.example to set the user login credentials. We suggest not to overwrite the test-variables.yaml like done in Example 2 (i.e., ```--test-variables-file /tmp/ods-ci-test-variables/test-variables.yml```). 
You could provide other variable files or single variables using the robot arguments, like below. Although, the solution below has not been tested. If you fall under this use case, please contact ods-qe@redhat.com
```yaml
      image: quay.io/modh/ods-ci:latest
      imagePullPolicy: IfNotPresent
      name: ods-ci-testrun
      serviceAccountName: rhods-test-runner
      env:
        - name: OC_HOST
          value: "https://api.mycluster.abcd.domain.org:1234"
        - name: SET_ENVIRONMENT
          value: "1"
        - name: OCM_ENV
          value: "staging"                    
        - name: OCM_TOKEN
          value: "my-ocm-token"
        - name: RUN_SCRIPT_ARGS
          value: "--skip-oclogin false --set-urls-variables true"
        - name: ROBOT_EXTRA_ARGS
          value: "-i Smoke --dryrun --variablefile /tmp/ods-ci-test-variables/second-test-variables.yml --variable MYVAR:myvalue"
      volumeMounts:
        - mountPath: /tmp/ods-ci/test-output
          name: ods-ci-test-output
        - mountPath: /tmp/ods-ci-test-variables
          name: ods-ci-test-variables
```


### Deploy postfix smtp server
To use localhost as smtp server while running ods-ci container, you could leverage on a postfix container. One [example](ods_ci/build/Dockerfile_smtpserver) is reported in this repo.
If you are running ods-ci container on your local machine, you could use [podman](https://developers.redhat.com/blog/2019/01/15/podman-managing-containers-pods) to run both the containers, like this:
```bash
podman run -d --pod new:<pod_name>  <postfix_imagename>:<image_label>
podman run --rm --pod=<pod_name>
                -v $PWD/ods_ci/test-variables.yml:/tmp/ods-ci/ods_ci/test-variables.yml:Z
                -v $PWD/ods_ci/test-output:/tmp/ods-ci/ods_ci/test-output:Z
                -e ROBOT_EXTRA_ARGS='--email-report true --email-from myresults@redhat.com --email-to mymail@redhat.com'
                -e RUN_SCRIPT_ARGS='--skip-oclogin false --set-urls-variables true --include Smoke'
                ods-ci:1.24.0

```
If you are running ods-ci container on a cluster you could use the pod template [ods-ci.pod_with_postfix.yaml](./ods-ci_pod_with_postfix.yaml) from this repository. Based on your case, you may need to merge [ods-ci.pod_with_postfix.yaml](./ods-ci_pod_with_postfix.yaml) with one of the yaml used in the above examples pod definitions.


**NOTE**: Keep in mind that this solution is not working on OSD clusters as reported [here](https://access.redhat.com/solutions/880233).
