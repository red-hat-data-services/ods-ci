import importlib
import json
import os
import sys
import tempfile
import time

from DataSciencePipelinesAPI import DataSciencePipelinesAPI
from kfp import compiler
from kfp.client import Client
from robotlibcore import keyword


class DataSciencePipelinesKfp:
    base_image = (
        "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"
    )

    # init should not have a call to external system, otherwise dry-run will fail
    def __init__(self):
        self.client = None
        self.api = None

    def get_client(self, user, pwd, project, route_name="ds-pipeline-dspa"):
        if self.client is None:
            self.api = DataSciencePipelinesAPI()
            self.api.login_and_wait_dsp_route(user, pwd, project, route_name)
            self.client = Client(
                host=f"https://{self.api.route}/",
                existing_token=self.api.sa_token,
                ssl_ca_cert=self.api.get_cert(),
            )
        return self.client, self.api

    def get_bucket_name(self, api, project):
        bucket_name, _ = api.run_command(f"oc get dspa -n {project} dspa -o json")
        objectStorage = json.loads(bucket_name)["spec"]["objectStorage"]
        if "minio" in objectStorage:
            return objectStorage["minio"]["bucket"]
        else:
            return objectStorage["externalStorage"]["bucket"]

    def import_souce_code(self, path):
        module_name = os.path.basename(path).replace("-", "_")
        spec = importlib.util.spec_from_loader(module_name, importlib.machinery.SourceFileLoader(module_name, path))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        sys.modules[module_name] = module
        return module

    @keyword
    def setup_client(self, user, pwd, project):
        # force a new client
        self.client = None
        self.get_client(user, pwd, project)

    @keyword
    def import_run_pipeline(self, pipeline_url, pipeline_params):
        print(f"pipeline_params({type(pipeline_params)}): {pipeline_params}")
        print(f"downloading: {pipeline_url}")
        test_pipeline_run_yaml, _ = self.api.do_get(pipeline_url)
        pipeline_file = "/tmp/test_pipeline_run_yaml.yaml"
        with open(pipeline_file, "w", encoding="utf-8") as f:
            f.write(test_pipeline_run_yaml)
        print(f"{pipeline_url} content stored at {pipeline_file}")
        print("create a run from pipeline")
        response = self.client.create_run_from_pipeline_package(pipeline_file=pipeline_file, arguments=pipeline_params)
        print(response)
        return response.run_id

    @keyword
    def check_run_status(self, run_id, timeout=160):
        count = 0
        while count < timeout:
            response = self.client.get_run(run_id)
            run_status = response.state
            print(f"Checking run status: {run_status}")
            if run_status == "FAILED":
                break
            if run_status == "SUCCEEDED":
                break
            time.sleep(1)
            count += 1
        return run_status  # pyright: ignore [reportPossiblyUnboundVariable]

    @keyword
    def delete_run(self, run_id):
        response = self.client.delete_run(run_id)
        # means success
        assert len(response) == 0

    @keyword
    def create_run_from_pipeline_func(
        self,
        user,
        pwd,
        project,
        source_code,
        fn,
        pipeline_params={},
        current_path=None,
        route_name="ds-pipeline-dspa",
        pip_index_url=None,
        pip_trusted_host=None,
    ):
        print(f"pipeline_params: {pipeline_params}")
        client, api = self.get_client(user, pwd, project, route_name)
        mlpipeline_minio_artifact_secret = api.get_secret(project, "ds-pipeline-s3-dspa")
        bucket_name = self.get_bucket_name(api, project)
        # the current path is from where you are running the script
        # sh ods_ci/run_robot_test.sh
        # the current_path will be ods-ci
        if current_path is None:
            current_path = os.getcwd()
        my_source = self.import_souce_code(f"{current_path}/tests/Resources/Files/pipeline-samples/v2/{source_code}")
        pipeline_func = getattr(my_source, fn)

        # pipeline_params
        # there are some special keys to retrieve argument values dynamically
        # in pipeline v2, we must match the parameters names
        if "mlpipeline_minio_artifact_secret" in pipeline_params:
            pipeline_params["mlpipeline_minio_artifact_secret"] = str(mlpipeline_minio_artifact_secret["data"])
        if "bucket_name" in pipeline_params:
            pipeline_params["bucket_name"] = bucket_name
        if "openshift_server" in pipeline_params:
            pipeline_params["openshift_server"] = self.api.get_openshift_server()
        if "openshift_token" in pipeline_params:
            pipeline_params["openshift_token"] = self.api.get_openshift_token()
        print(f"pipeline_params modified with dynamic values: {sorted(pipeline_params.keys())}")

        # create_run_from_pipeline_func will compile the code
        # if you need to see the yaml, for debugging purpose, call: TektonCompiler().compile(pipeline, f'{fn}.yaml')
        with tempfile.TemporaryDirectory() as tmpdir:
            pipeline_package_path = os.path.join(tmpdir, "pipeline.yaml")
            compiler.Compiler().compile(
                pipeline_func=pipeline_func,
                package_path=pipeline_package_path,
            )

            if pip_index_url is not None:
                assert pip_trusted_host is not None
                with open(pipeline_package_path, "r") as file:
                    file_content = file.read()
                file_content = file_content.replace(
                    "python3 -m pip install",
                    f"python3 -m pip install --index-url {pip_index_url} --trusted-host {pip_trusted_host}",
                )
                with open(pipeline_package_path, "w") as file:
                    file.write(file_content)

            result = client.create_run_from_pipeline_package(
                pipeline_file=pipeline_package_path, arguments=pipeline_params
            )
        # easy to debug and double check failures
        print(result)
        return result.run_id
