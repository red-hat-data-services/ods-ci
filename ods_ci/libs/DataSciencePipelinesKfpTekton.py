import base64
import importlib
import json
import os
import sys
from DataSciencePipelinesAPI import DataSciencePipelinesAPI
from robotlibcore import keyword
from urllib3.exceptions import MaxRetryError, SSLError


class DataSciencePipelinesKfpTekton:

    base_image = 'registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61'

    # init should not have a call to external system, otherwise dry-run will fail
    def __init__(self):
        self.client = None
        self.api = None

    def get_client(self, user, pwd, project, route_name):
        if self.client is None:
            self.api = DataSciencePipelinesAPI()
            self.api.login_and_wait_dsp_route(user, pwd, project, route_name)

            # initialize global environment variables
            # https://github.com/kubeflow/kfp-tekton/issues/1345
            default_image = DataSciencePipelinesKfpTekton.base_image
            os.environ["DEFAULT_STORAGE_CLASS"] = self.api.get_default_storage()
            os.environ["TEKTON_BASH_STEP_IMAGE"] = default_image
            os.environ["TEKTON_COPY_RESULTS_STEP_IMAGE"] = default_image
            os.environ["CONDITION_IMAGE_NAME"] = default_image
            import kfp_tekton

            # the following fallback it is to simplify the test development
            try:
                # we assume it is a secured cluster
                # ssl_ca_cert came from /path/to/python/lib/python3.x/site-packages/certifi/cacert.pem
                # that certificate is "Mozilla's carefully curated collection of root certificates"
                self.client = kfp_tekton.TektonClient(
                    host=f"https://{self.api.route}/", existing_token=self.api.sa_token
                )
            except MaxRetryError as e:
                # we assume it is a cluster with self-signed certs
                if type(e.reason) == SSLError:
                    # try to retrieve the certificate
                    self.client = kfp_tekton.TektonClient(
                        host=f"https://{self.api.route}/",
                        existing_token=self.api.sa_token,
                        ssl_ca_cert=self.get_cert(self.api),
                    )
        return self.client, self.api

    def get_cert(self, api):
        cert_json = self.get_secret(api, 'openshift-ingress-operator', 'router-ca')
        cert = cert_json["data"]["tls.crt"]
        decoded_cert = base64.b64decode(cert).decode("utf-8")

        file_name = "/tmp/kft-cert"
        cert_file = open(file_name, "w")
        cert_file.write(decoded_cert)
        cert_file.close()
        return file_name

    def get_secret(self, api, project, name):
        secret_json, _ = api.run_oc(
            f"oc get secret -n {project} {name} -o json"
        )
        return json.loads(secret_json)

    def import_souce_code(self, path):
        module_name = os.path.basename(path).replace("-", "_")
        spec = importlib.util.spec_from_loader(
            module_name, importlib.machinery.SourceFileLoader(module_name, path)
        )
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        sys.modules[module_name] = module
        return module

    @keyword
    def kfp_tekton_create_run_from_pipeline_func(
        self, user, pwd, project, route_name, source_code, fn, current_path=None
    ):
        client, api = self.get_client(user, pwd, project, route_name)
        mlpipeline_minio_artifact_secret = self.get_secret(api, project, 'mlpipeline-minio-artifact')
        # the current path is from where you are running the script
        # sh ods_ci/run_robot_test.sh
        # the current_path will be ods-ci
        if current_path is None:
            current_path = os.getcwd()
        my_source = self.import_souce_code(
            f"{current_path}/ods_ci/tests/Resources/Files/pipeline-samples/{source_code}"
        )
        pipeline = getattr(my_source, fn)

        # create_run_from_pipeline_func will compile the code
        # if you need to see the yaml, for debugging purpose, call: TektonCompiler().compile(pipeline, f'{fn}.yaml')
        result = client.create_run_from_pipeline_func(
            pipeline_func=pipeline, arguments={
                'mlpipeline_minio_artifact_secret': mlpipeline_minio_artifact_secret
            }
        )
        # easy to debug and double check failures
        print(result)
        return result

    # we are calling DataSciencePipelinesAPI because of https://github.com/kubeflow/kfp-tekton/issues/1223
    # Waiting for a backport https://github.com/kubeflow/kfp-tekton/pull/1234
    @keyword
    def kfp_tekton_wait_for_run_completion(
        self, user, pwd, project, route_name, run_result, timeout=160
    ):
        _, api = self.get_client(user, pwd, project, route_name)
        return api.check_run_status(run_result.run_id, timeout=timeout)

