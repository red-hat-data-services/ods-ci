import base64
import json
import os
import subprocess
import time
from json import JSONDecodeError

import requests
from robotlibcore import keyword


class DataSciencePipelinesAPI:
    # init should not have a call to external system, otherwise dry-run will fail
    def __init__(self):
        self.route = ""
        self.sa_token = None

    @keyword
    def wait_until_openshift_pipelines_operator_is_deployed(self):
        """
        when creating at the first time, it can take like 1 minute to have the pods ready
        """
        deployment_count = 0
        count = 0
        while deployment_count != 1 and count < 30:
            deployments = []
            response, _ = self.run_oc(
                f"oc get deployment -n openshift-operators openshift-pipelines-operator -o json"
            )
            try:
                response = json.loads(response)
                if (
                    response["metadata"]["name"] == "openshift-pipelines-operator"
                    and "readyReplicas" in response["status"]
                    and response["status"]["readyReplicas"] == 1
                ):
                    deployments.append(response)
            except JSONDecodeError:
                pass
            deployment_count = len(deployments)
            time.sleep(1)
            count += 1
        pipeline_run_crd_count = 0
        count = 0
        while pipeline_run_crd_count < 1 and count < 60:
            # https://github.com/opendatahub-io/odh-dashboard/issues/1673
            # It is possible to start the Pipeline Server without pipelineruns.tekton.dev CRD
            pipeline_run_crd_count = self.count_pods("oc get crd pipelineruns.tekton.dev", 1)
            time.sleep(1)
            count += 1
        assert pipeline_run_crd_count == 1
        return self.count_running_pods(
            f"oc get pods -n openshift-operators -l name=openshift-pipelines-operator -o json",
            "openshift-pipelines-operator",
            "Running",
            1,
        )

    @keyword
    def login_and_wait_dsp_route(
        self,
        user,
        pwd,
        project,
        route_name="ds-pipeline-pipelines-definition",
        timeout=120,
    ):
        print("Fetch token")
        basic_value = f"{user}:{pwd}".encode("ASCII")
        basic_value = base64.b64encode(basic_value).decode("ASCII")
        response = requests.get(
            self.retrieve_auth_url(),
            headers={"Authorization": f"Basic {basic_value}"},
            verify=False,
            allow_redirects=False,
        )
        url_with_token = response.headers["Location"]
        access_token_key = "access_token="
        idx_token = url_with_token.index(access_token_key) + len(access_token_key)
        token = url_with_token[idx_token:]
        idx_token = token.index("&")
        self.sa_token = token[:idx_token]

        print("Fetch the dsp route")
        self.route = ""
        count = 0
        while self.route == "" and count < 60:
            self.route, _ = self.run_oc(
                f"oc get route -n {project} {route_name} --template={{{{.spec.host}}}}"
            )
            time.sleep(1)
            count += 1

        assert self.route != "", "Route must not be empty"
        print(f"Waiting for Data Science Pipeline route to be ready to avoid firing false alerts: {self.route}")
        time.sleep(45)
        status = -1
        count = 0
        while status != 200 and count < timeout:
            response, status = self.do_get(
                f"https://{self.route}/apis/v1beta1/runs",
                headers={"Authorization": f"Bearer {self.sa_token}"},
            )
            # 503 -> service not deployed
            # 504 -> service not ready
            # if you need to debug, try to print also the response
            print(f"({count}): Data Science Pipeline HTTP Status: {status}")
            if status != 200:
                time.sleep(30)
                count += 30
        return status

    @keyword
    def remove_pipeline_project(self, project):
        print(
            f"We are removing the project({project}) because we could run the test multiple times"
        )
        self.run_oc(f"oc delete project {project} --wait=true --force=true")
        print("Wait because it could be in Terminating status")
        count = 0
        while count < 30:
            project_status, error = self.run_oc(
                f"oc get project {project} --template={{{{.status.phase}}}}"
            )
            print(f"Project status: {project_status}")
            print(f"Error message: {error}")
            if project_status == "":
                break
            time.sleep(1)
            count += 1

    @keyword
    def create_pipeline(self, url_test_pipeline_run_yaml):
        print("Creating a pipeline from data science pipelines stack")
        test_pipeline_run_yaml, _ = self.do_get(url_test_pipeline_run_yaml)
        filename = "test_pipeline_run_yaml.yaml"
        with open(filename, "w", encoding="utf-8") as f:
            f.write(test_pipeline_run_yaml)
        with open(filename, "rb") as f:
            response, _ = self.do_upload(
                f"https://{self.route}/apis/v1beta1/pipelines/upload",
                files={"uploadfile": f},
                headers={"Authorization": f"Bearer {self.sa_token}"},
            )
        os.remove(filename)
        pipeline_json = json.loads(response)
        pipeline_id = pipeline_json["id"]
        response, status = self.do_get(
            f"https://{self.route}/apis/v1beta1/pipelines/{pipeline_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 200
        assert json.loads(response)["name"] == filename
        return pipeline_id

    @keyword
    def create_run(self, pipeline_id):
        print("Creating the run from uploaded pipeline")
        response, status = self.do_post(
            f"https://{self.route}/apis/v1beta1/runs",
            headers={
                "Authorization": f"Bearer {self.sa_token}",
                "Content-Type": "application/json",
            },
            json={
                "name": "test-pipeline-run",
                "pipeline_spec": {"pipeline_id": f"{pipeline_id}"},
            },
        )
        assert status == 200
        run_json = json.loads(response)
        run_id = run_json["run"]["id"]

        response, status = self.do_get(
            f"https://{self.route}/apis/v1beta1/runs/{run_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 200

        return run_id

    @keyword
    def check_run_status(self, run_id, timeout=160):
        run_status = None
        count = 0
        run_finished_ok = False
        while not run_finished_ok and count < timeout:
            response, status = self.do_get(
                f"https://{self.route}/apis/v1beta1/runs/{run_id}",
                headers={"Authorization": f"Bearer {self.sa_token}"},
            )
            try:
                run_json = json.loads(response)
                if "run" in run_json and "status" in run_json["run"]:
                    run_status = run_json["run"]["status"]
            except JSONDecodeError:
                print(response, status)
                pass
            print(f"Checking run status: {run_status}")
            if run_status == 'Failed':
                break
            # https://github.com/tektoncd/pipeline/blob/main/docs/pipelineruns.md#monitoring-execution-status
            if run_status == "Completed" or run_status == "Succeeded":
                run_finished_ok = True
                break
            time.sleep(1)
            count += 1
        return run_finished_ok

    @keyword
    def delete_runs(self, run_id):
        print("Deleting the runs")

        response, status = self.do_delete(
            f"https://{self.route}/apis/v1beta1/runs/{run_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 200
        response, status = self.do_get(
            f"https://{self.route}/apis/v1beta1/runs/{run_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 404

    @keyword
    def delete_pipeline(self, pipeline_id):
        print("Deleting the pipeline")
        response, status = self.do_delete(
            f"https://{self.route}/apis/v1beta1/pipelines/{pipeline_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 200
        response, status = self.do_get(
            f"https://{self.route}/apis/v1beta1/pipelines/{pipeline_id}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
        )
        assert status == 404

    @keyword
    def add_role_to_user(self, name, user, project):
        output, error = self.run_oc(
            f"oc policy add-role-to-user {name} {user} -n {project} --role-namespace={project}"
        )
        print(output, "->", error)

    @keyword
    def do_http_request(self, url):
        assert self.route != "", "Login First"
        response = requests.get(
            f"http://{self.route}/{url}",
            headers={"Authorization": f"Bearer {self.sa_token}"},
            verify=False,
        )
        assert response.status_code == 200
        return response.url

    def count_pods(self, oc_command, pod_criteria, timeout=30):
        oc_command = f'{oc_command} --no-headers'
        pod_count = 0
        count = 0
        while pod_count != pod_criteria and count < timeout:
            bash_str, _ = self.run_oc(oc_command)
            # | wc -l is returning an empty string
            pod_count = sum(1 for line in bash_str.split('\n') if line.strip())
            if pod_count >= pod_criteria:
                break
            time.sleep(1)
            count += 1
        return pod_count

    def count_running_pods(
        self, oc_command, name_startswith, status_phase, pod_criteria, timeout=30
    ):
        pod_count = 0
        count = 0
        while pod_count != pod_criteria and count < timeout:
            pods = []
            response, _ = self.run_oc(oc_command)
            try:
                response = json.loads(response)
                items = response["items"]
                for item in items:
                    if item["metadata"]["name"].startswith(name_startswith):
                        if item["status"]["phase"] == status_phase:
                            pods.append(item)
            except JSONDecodeError:
                pass
            pod_count = len(pods)
            # we can stop the iteration to save time
            if pod_count >= pod_criteria:
                break
            time.sleep(1)
            count += 1
        return pod_count

    def retrieve_auth_url(self):
        response, _ = self.run_oc("oc cluster-info")
        host_begin_index = response.index("://") + 3
        response = response[host_begin_index:]
        host = response[: response.index(":")]
        # host[4:] means that we need to remove '.api' from the url
        return f"https://oauth-openshift.apps.{host[4:]}/oauth/authorize?response_type=token&client_id=openshift-challenging-client"

    def get_default_storage(self):
        result, _ = self.run_oc("oc get storageclass -A -o json")
        result = json.loads(result)
        for storage_class in result['items']:
            if 'annotations' in storage_class['metadata']:
                if storage_class['metadata']['annotations']['storageclass.kubernetes.io/is-default-class'] == 'true':
                    break
        return storage_class['metadata']['name']

    def run_oc(self, command):
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return self.byte_to_str(output), error

    def do_get(self, url, headers=None):
        response = requests.get(url, headers=headers, verify=False)
        return self.byte_to_str(response.content), response.status_code

    def do_post(self, url, headers, json):
        response = requests.post(url, headers=headers, json=json, verify=False)
        return self.byte_to_str(response.content), response.status_code

    def do_upload(self, url, files, headers=None):
        response = requests.post(url, headers=headers, files=files, verify=False)
        return self.byte_to_str(response.content), response.status_code

    def do_delete(self, url, headers):
        response = requests.delete(url, headers=headers, verify=False)
        return self.byte_to_str(response.content), response.status_code

    def byte_to_str(self, content):
        return content.decode("utf-8", "ignore")
