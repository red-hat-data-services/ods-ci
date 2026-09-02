---
name: run-elyra-pipeline-test
description: Run and debug the Elyra pipelines-in-workbenches Robot test (0502__ide_elyra.robot) in ods-ci — prerequisites, test-variables.yml setup, how to launch the Smoke/ODS-2197 test, and how to diagnose common failures (auth, S3/Minio/DSPA pods, git clone in JupyterLab).
---

# Run the Elyra Pipeline Test (0502__ide_elyra.robot)

Test suite: `ods_ci/tests/Tests/0500__ide/0502__ide_elyra.robot`
Verifies a workbench (JupyterLab) can create and run an Elyra "Hello World" pipeline on Data Science Pipelines.

## 1. One-time environment prerequisites

- Linux + Chromium/Chrome (or Firefox) with a matching `chromedriver` (or `geckodriver`) in `$PATH` (e.g. `~/.local/bin`).
- `poetry` installed and in `$PATH`.
- `oc` CLI logged in to the target cluster (unless you run with `--service-account`).
- Cluster prerequisites (must be true before the test runs):
  - A working ODH/RHODS install with JupyterHub + DSP (pipelines) components enabled.
  - **Self-signed CAs trusted on the cluster** if you use Minio or an internal git bastion — both DSPA pods and the `git` client inside workbenches need the CA (routes/Minio TLS cert, git server TLS cert). Without this: DSPA pods fail to reach 7 running, and in-workbench git clones fail with SSL errors.
  - For Minio-based S3: a bucket reachable from the cluster (e.g. an in-cluster Minio deployment, see `ods_ci/tests/Resources/Files/minio/minio.yaml`).

## 2. Create the variables file

```bash
cd ods_ci
cp test-variables.yml.example test-variables.yml
```

Required keys and what to put (placeholder values in the example MUST be replaced):

| Key | Value / notes |
|-----|---------------|
| `BROWSER` | `NAME: chrome` + OPTIONS (headless flags for containers) |
| `OCP_CONSOLE_URL`, `ODH_DASHBOARD_URL`, `OCP_API_URL` | your cluster URLs |
| `TEST_USER`, `TEST_USER_3`, `OCP_ADMIN_USER` | real cluster users + correct `AUTH_TYPE` (see below) |
| `S3` | real `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`, `AWS_DEFAULT_ENDPOINT` (e.g. Minio endpoint), `AWS_DEFAULT_REGION`, and the bucket must exist — the suite creates a data connection to bucket `ods-ci-ds-pipelines` |
| `PRODUCT` | `RHODS` (default) or `ODH` (then also set ODH namespaces: `APPLICATIONS_NAMESPACE: opendatahub`, `MONITORING_NAMESPACE: opendatahub`, `OPERATOR_NAMESPACE: openshift-operators`, `NOTEBOOKS_NAMESPACE: opendatahub`, `OPERATOR_NAME: opendatahub-operator`) |
| `OPERATOR_NAME`, `*_NAMESPACE` | match the cluster |
| `COMPONENTS` | components enabled in the DSC CR |
| `GIT_HTTPS_URL` | **optional**. Base URL (no trailing slash) of the git server the workbench can reach. If set, the test clones `${GIT_HTTPS_URL}/ods-ci-notebooks-main.git`. If unset, it clones `https://github.com/redhat-rhods-qe/ods-ci-notebooks-main`. The cloned repo must contain `notebooks/500__jupyterhub/pipelines/v2/elyra/run-pipelines-on-data-science-pipelines/hello-generic-world.pipeline`. |

### AUTH_TYPE values

`AUTH_TYPE` is clicked literally as a link on the "Log in with …" page. Use:

- the **exact visible link text** on your login page (e.g. `HTPasswd`, `My Company`) — for clusters with an auth-type chooser, or
- `oidc` — for SSO clusters (Keycloak by default, or set `OIDC_PROVIDER: entra` for Entra ID).

Never leave the `foo-auth` / `adm-auth` placeholders.

## 3. Run the test

```bash
cd ods_ci
sh run_robot_test.sh --test-case tests/Tests/0500__ide/0502__ide_elyra.robot --include Smoke
```

- `--include Smoke` runs only the 10-min Smoke test (`ODS-2197`). Without it, the whole file runs including the `Tier1` templated cases (40 min each).
- Report: `ods_ci/test-output/test_report.html` (and `log.html`).
- Dry-run (syntax only, no execution):
  ```bash
  poetry run robot --dryrun --variablefile test-variables.yml tests/Tests/0500__ide/0502__ide_elyra.robot
  ```

## 4. Diagnosing failures

### `Variable '${PRODUCT}' does not exist`
`test-variables.yml` missing, empty, or not loaded. The wrapper passes it via `--variablefile` relative to `ods_ci/`. Fix the file, don't chase this error otherwise.

### Teardown: `Variable '${PROJECT_TO_DELETE}' not found`
Cascade of a failed suite setup (the variable is set during `Elyra Pipelines Suite Setup`). Fix the setup error first.

### `Element with locator 'link:...' not found` during login
Wrong `AUTH_TYPE` (see table above). Check the actual login page.

### `Verify Pipeline Server Deployments … DSPA requires at least 7 pods running`
Not an S3 test issue — it's just `oc get pods -n <project> -l component=data-science-pipelines | wc -l`. Investigate:
```bash
oc get pods -n <project> -l component=data-science-pipelines -o wide
oc logs <failing-pod> -n <project>
```
Typical causes: untrusted S3/Minio TLS cert (import the CA on the cluster), PVC issues, or the threshold/label being out of date for the ODH version installed.

### "Could not find path: …hello-generic-world.pipeline" in JupyterLab
The clone in the workbench failed (folder is empty), so the path doesn't exist. The clone error is surfaced by the `Get Git Clone Error Message` keyword in `ods_ci/tests/Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot` — check its text in the test log. Causes:
- workbench can't reach the git host (no egress / wrong `GIT_HTTPS_URL`)
- git TLS cert not trusted inside the workbench (import CA on cluster, roll `jupyterhub-nb-*` pods)
- repo layout/branch doesn't contain that file path
- **stale UI selectors** in `Get Git Clone Error Message` / `Clone Repo` — the JupyterLab version in the Data Science image matters. Known-good selectors (current JupyterLab `jp-toast` widget):
  - toast "Show" button: `xpath://button[contains(@class,"jp-toast-button") and @title="Show"]`
  - dialog error text: `//div[contains(@class,"jp-Dialog-body")]`
  - dialog Dismiss button: `//div/div/button[@class="jp-Dialog-button jp-mod-accept jp-mod-warn jp-mod-styled"]`

### `Variable '${GIT_HTTPS_URL}'` errors
The test uses `Get Variable Value`, so the variable is optional. If your local copy of the test fails on it, the file is out of date — update from this repo's version.

## 5. Key files

| File | Purpose |
|------|---------|
| `ods_ci/tests/Tests/0500__ide/0502__ide_elyra.robot` | The test suite |
| `ods_ci/tests/Resources/Page/ODH/JupyterHub/JupyterLabLauncher.robot` | `Clone Git Repository And Open`, `Get Git Clone Error Message` (UI selectors live here) |
| `ods_ci/tests/Resources/CLI/DataSciencePipelines/DataSciencePipelinesBackend.resource` | DSPA deployment checks, pipeline server creation |
| `ods_ci/tests/Resources/Page/LoginPage.robot` | OCP login flows (`AUTH_TYPE`, `oidc`) |
| `ods_ci/tests/Resources/Files/minio/minio.yaml` | in-cluster Minio deployment template |
| `ods_ci/test-variables.yml.example` | variables template |
| `ods_ci/docs/RUN_ARGUMENTS.md` | `run_robot_test.sh` options |
