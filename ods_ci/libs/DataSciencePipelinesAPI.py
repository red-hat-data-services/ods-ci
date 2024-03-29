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
        self.sleep_time = 45

    @keyword
    def login_and_wait_dsp_route(
        self,
        user,
        pwd,
        project,
        route_name="ds-pipeline-dspa",
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
            self.route, _ = self.run_oc(f"oc get route -n {project} {route_name} --template={{{{.spec.host}}}}")
            time.sleep(1)
            count += 1

        assert self.route != "", "Route must not be empty"
        print(f"Waiting for Data Science Pipeline route to be ready to avoid firing false alerts: {self.route}")
        time.sleep(self.sleep_time)
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
                time.sleep(self.sleep_time)
                count += self.sleep_time
        return status

    @keyword
    def remove_pipeline_project(self, project):
        print(f"We are removing the project({project}) because we could run the test multiple times")
        self.run_oc(f"oc delete project {project} --wait=true --force=true")
        print("Wait because it could be in Terminating status")
        count = 0
        while count < 30:
            project_status, error = self.run_oc(f"oc get project {project} --template={{{{.status.phase}}}}")
            print(f"Project status: {project_status}")
            print(f"Error message: {error}")
            if project_status == "":
                break
            time.sleep(1)
            count += 1

    @keyword
    def add_role_to_user(self, name, user, project):
        output, error = self.run_oc(f"oc policy add-role-to-user {name} {user} -n {project} --role-namespace={project}")
        print(output, "->", error)

    @keyword
    def do_http_request(self, url):
        assert self.route != "", "Login First"
        response = requests.get(
            f"http://{self.route}/{url}", headers={"Authorization": f"Bearer {self.sa_token}"}, verify=self.get_cert()
        )
        assert response.status_code == 200
        return response.url

    def count_pods(self, oc_command, pod_criteria, timeout=30):
        oc_command = f"{oc_command} --no-headers"
        pod_count = 0
        count = 0
        while pod_count != pod_criteria and count < timeout:
            bash_str, _ = self.run_oc(oc_command)
            # | wc -l is returning an empty string
            pod_count = sum(1 for line in bash_str.split("\n") if line.strip())
            if pod_count >= pod_criteria:
                break
            time.sleep(1)
            count += 1
        return pod_count

    def count_running_pods(self, oc_command, name_startswith, status_phase, pod_criteria, timeout=30):
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
        for storage_class in result["items"]:
            if "annotations" in storage_class["metadata"]:
                if storage_class["metadata"]["annotations"]["storageclass.kubernetes.io/is-default-class"] == "true":
                    return storage_class["metadata"]["name"]
        return None

    @keyword
    def get_openshift_server(self):
        return self.run_oc("oc whoami --show-server=true")[0].replace("\n", "")

    def get_openshift_token(self):
        return self.run_oc("oc whoami --show-token=true")[0].replace("\n", "")

    def run_oc(self, command):
        process = subprocess.Popen(command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        return self.byte_to_str(output), error

    def do_get(self, url, headers=None, skip_ssl=False):
        if skip_ssl:
            response = requests.get(url, headers=headers, verify=False)
        else:
            response = requests.get(url, headers=headers, verify=self.get_cert())
        return self.byte_to_str(response.content), response.status_code

    def do_post(self, url, headers, json):
        response = requests.post(url, headers=headers, json=json, verify=self.get_cert())
        return self.byte_to_str(response.content), response.status_code

    def do_upload(self, url, files, headers=None):
        response = requests.post(url, headers=headers, files=files, verify=self.get_cert())
        return self.byte_to_str(response.content), response.status_code

    def do_delete(self, url, headers):
        response = requests.delete(url, headers=headers, verify=self.get_cert())
        return self.byte_to_str(response.content), response.status_code

    def byte_to_str(self, content):
        return content.decode("utf-8", "ignore")

    def get_secret(self, project, name):
        secret_json, _ = self.run_oc(f"oc get secret -n {project} {name} -o json")
        assert len(secret_json) > 0
        return json.loads(secret_json)

    def get_cert(self):
        cert_json = self.get_secret("openshift-ingress-operator", "router-ca")
        cert = cert_json["data"]["tls.crt"]
        decoded_cert = base64.b64decode(cert).decode("utf-8")

        file_name = "/tmp/kfp-cert"
        cert_file = open(file_name, "w")
        cert_file.write(decoded_cert)
        cert_file.close()
        return file_name
