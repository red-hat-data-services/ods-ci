import importlib
import json
import os
import sys
import tempfile
import time
from typing import Any

import kfp_server_api
from DataSciencePipelinesAPI import DataSciencePipelinesAPI
from kfp import compiler
from kfp.client import Client
from robotlibcore import keyword


class DataSciencePipelinesKfp:
    # init should not have a call to external system, otherwise dry-run will fail
    def __init__(self):
        self.client = None
        self.api = None

    def get_client(self, user, pwd, project, route_name="ds-pipeline-dspa"):
        if self.client is None:
            self.api = DataSciencePipelinesAPI(sleep_time=1)
            self.api.login_and_wait_dsp_route(user, pwd, project, route_name)
            self.client = Client(
                host=f"https://{self.api.route}/",
                existing_token=self.api.sa_token,
                ssl_ca_cert=self.api.get_cert(),
            )
        return self.client, self.api

    @keyword
    def setup_client(self, user, pwd, project, force_reset=False):
        """
        Initializes the KFP SKD client when needed or when force_reset=True
        """
        if force_reset:
            self.client = None
        self.get_client(user, pwd, project)

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
    def create_experiment(self, name: str, description: str | None = None, namespace: str | None = None):
        """
        Creates a pipeline experiment and returns experiment_id.
        If the experiment already exists also return experiment_id
        """
        response = self.client.create_experiment(name, description, namespace)
        return response.experiment_id

    @keyword
    def get_experiment(
        self, experiment_id: str | None = None, experiment_name: str | None = None, namespace: str | None = None
    ) -> kfp_server_api.V2beta1Experiment:
        """Gets details of an experiment.

        Either ``experiment_id`` or ``experiment_name`` is required.

        Args:
            experiment_id: ID of the experiment.
            experiment_name: Name of the experiment.
            namespace: Kubernetes namespace to use. Used for multi-user deployments.
                For single-user deployments, this should be left as ``None``.

        Returns:
            ``V2beta1Experiment`` object.
        """
        response = self.client.get_experiment(experiment_id, experiment_name, namespace)
        return response

    @keyword
    def get_default_experiment_id(self, namespace: str | None = None):
        response = self.get_experiment(experiment_name="Default", namespace=namespace)
        return response.experiment_id

    @keyword
    def upload_pipeline(self, pipeline_package_path, pipeline_name, description, namespace):
        """Uploads a pipeline.

        Args:
            pipeline_package_path: Local path to the pipeline package.
            pipeline_name: Name of the pipeline to be shown in the UI.
            description: Description of the pipeline to be shown in the UI.
            namespace: Optional. Kubernetes namespace where the pipeline should
                be uploaded. For single user deployment, leave it as None; For
                multi user, input a namespace where the user is authorized.

        Returns:
             pipeline_id
             pipeline_version_id
        """
        response = self.client.upload_pipeline(pipeline_package_path, pipeline_name, description, namespace)
        pipeline_id = response.pipeline_id
        pipeline_version_id = self.get_last_pipeline_version(pipeline_id)
        return pipeline_id, pipeline_version_id

    @keyword
    def upload_pipeline_version(
        self,
        pipeline_package_path: str,
        pipeline_version_name: str,
        pipeline_id: str | None = None,
        pipeline_name: str | None = None,
        description: str | None = None,
    ):
        """
        Creates a pipeline version of the pipeline (located by pipeline_id or pipeline_name). Pipeline should exist
        :param pipeline_package_path:
        :param pipeline_version_name:
        :param pipeline_id:
        :param pipeline_name:
        :param description:
        :return:
            pipeline_version_id
        """
        response = self.client.upload_pipeline_version(
            pipeline_package_path, pipeline_version_name, pipeline_id, pipeline_name, description
        )
        pipeline_version_id = response.pipeline_version_id
        return pipeline_version_id

    @keyword
    def get_last_pipeline_version(self, pipeline_id: str) -> str | None:
        """
        Returns pipeline_version_id of the latest version of pipeline_id  (or None if there is no version)
        """
        response = self.list_pipeline_versions(pipeline_id=pipeline_id, page_size=1, sort_by="created_at desc")
        if response.pipeline_versions is None:
            return None
        if len(response.pipeline_versions) > 0:
            return response.pipeline_versions[0].pipeline_version_id
        else:
            return None

    @keyword
    def get_all_pipeline_versions(self, pipeline_id: str):
        """
        Returns a list of all pipeline versions of a pipeline. When needed, this function goes through pagination
        in order to get all the pipeline versions
        """
        all_versions = []
        next_page_token = ""
        while next_page_token is not None:
            response = self.list_pipeline_versions(
                pipeline_id=pipeline_id, page_token=next_page_token, page_size=10, sort_by="created_at desc"
            )
            next_page_token = response.next_page_token
            if response.pipeline_versions is not None:
                all_versions.extend(response.pipeline_versions)
        return all_versions

    @keyword
    def list_pipeline_versions(
        self, pipeline_id: str, page_token: str = "", page_size: int = 10, sort_by: str = "", filter: str | None = None
    ):
        """Lists pipeline versions.

        :param pipeline_id: ID of the pipeline for which to list versions.
        :param page_token:  Page token for obtaining page from paginated response.
        :param page_size:   Size of the page.
        :param sort_by:     Sort string of format ``'[field_name]', '[field_name] desc'``. For example, ``'display_name desc'``.
        :param filter:      filter: A url-encoded, JSON-serialized Filter protocol buffer
                (see `filter.proto message <https://github.com/kubeflow/pipelines/blob/cb7d9a87c999eb1d2280959e5afbeee9e270ef3d/backend/api/v2beta1/filter.proto>`_). Example:

                  ::

                    json.dumps({
                        "predicates": [{
                            "operation": "EQUALS",
                            "key": "display_name",
                            "stringValue": "my-name",
                        }]
                    })
        :return: V2beta1ListPipelineVersionsResponse object.
        """
        response = self.client.list_pipeline_versions(pipeline_id, page_token, page_size, sort_by, filter)
        return response

    @keyword
    def delete_pipeline_version(self, pipeline_id: str, pipeline_version_id: str):
        """Deletes a pipeline version.


        :param pipeline_id: ID of the pipeline
        :param pipeline_version_id: ID of the pipeline version
        :return:
        """
        self.client.delete_pipeline_version(pipeline_id, pipeline_version_id)

    @keyword
    def delete_all_pipeline_versions(self, pipeline_id: str):
        """Deletes all pipeline versions for a pipeline
        :param pipeline_id: ID of the pipeline
        """
        all_versions = self.get_all_pipeline_versions(pipeline_id=pipeline_id)
        for pipeline_version in all_versions:
            self.delete_pipeline_version(pipeline_version.pipeline_id, pipeline_version.pipeline_version_id)

    @keyword
    def run_pipeline(
        self,
        experiment_id: str | None = None,
        job_name: str | None = None,
        pipeline_package_path: str | None = None,
        params: dict[str, Any] | None = None,
        pipeline_id: str | None = None,
        version_id: str | None = None,
        pipeline_root: str | None = None,
        enable_caching: bool | None = None,
        service_account: str | None = None,
    ):
        """Runs a pipeline.

        Must specify either `pipeline_package_path` or both `pipeline_id` and `version_id`.
        In the first case, pipeline and pipeline version are not automatically created
        """

        if experiment_id is None:
            experiment_id = self.get_default_experiment_id()

        response = self.client.run_pipeline(
            experiment_id,
            job_name,
            pipeline_package_path,
            params,
            pipeline_id,
            version_id,
            pipeline_root,
            enable_caching,
            service_account,
        )
        return response.run_id

    @keyword
    def import_run_pipeline_from_url(self, pipeline_url, pipeline_params):
        """Creates and starts a pipeline run from pipeline_url

        When using this method, a pipeline run will be created and started but no pipeline or pipeline_version
        will be created
        """
        print(f"pipeline_params({type(pipeline_params)}): {pipeline_params}")
        print(f"downloading: {pipeline_url}")
        test_pipeline_run_yaml, _ = self.api.do_get(pipeline_url)
        pipeline_file = "/tmp/test_pipeline_run_yaml.yaml"
        with open(pipeline_file, "w", encoding="utf-8") as f:
            f.write(test_pipeline_run_yaml)
        print(f"{pipeline_url} content stored at {pipeline_file}")
        print("create a run from pipeline")
        response = self.client.create_run_from_pipeline_package(pipeline_file=pipeline_file, arguments=pipeline_params)
        return response.run_id

    @keyword
    def import_run_pipeline_from_file(self, pipeline_file, pipeline_params):
        """Creates and starts a pipeline run from pipeline_file

        When using this method, a pipeline run will be created and started but no pipeline or pipeline_version
        will be created
        """
        print(f"create a run from pipeline file {pipeline_file}")
        response = self.client.create_run_from_pipeline_package(pipeline_file=pipeline_file, arguments=pipeline_params)
        return response.run_id

    @keyword
    def wait_for_run_completion(self, run_id, timeout=160, sleep_duration=5):
        """Waits for a run to complete"""
        response = self.client.wait_for_run_completion(run_id=run_id, timeout=timeout, sleep_duration=sleep_duration)
        return response.state

    @keyword
    def get_run_status(self, run_id):
        """###Gets run status"""
        response = self.client.get_run(run_id)
        return response.state

    @keyword
    def check_run_status(self, run_id, timeout=160):
        """Waits for a run to complete"""
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
    def delete_pipeline(self, pipeline_id):
        """Deletes a pipeline"""
        print(f"Deleting pipeline {pipeline_id}")
        self.client.delete_pipeline(pipeline_id)

    @keyword
    def list_runs(
        self,
        page_token: str = "",
        page_size: int = 10,
        sort_by: str = "",
        experiment_id: str | None = None,
        namespace: str | None = None,
        filter: str | None = None,
    ):
        """List runs.

        Args:
            page_token: Page token for obtaining page from paginated response.
            page_size: Size of the page.
            sort_by: Sort string of format ``'[field_name]', '[field_name] desc'``. For example, ``'display_name desc'``.
            experiment_id: Experiment ID to filter upon
            namespace: Kubernetes namespace to use. Used for multi-user deployments. For single-user deployments, this should be left as ``None``.
            filter: A url-encoded, JSON-serialized Filter protocol buffer
                (see `filter.proto message <https://github.com/kubeflow/pipelines/blob/cb7d9a87c999eb1d2280959e5afbeee9e270ef3d/backend/api/v2beta1/filter.proto>`_). For a list of all filter operations ``'opertion'``, see `here <https://github.com/kubeflow/pipelines/blob/777c98153daf3dfae82730e14ff37bdddc334c4d/sdk/python/kfp/client/client.py#L37-L45>`_. Example:

                  ::

                    json.dumps(
                        {
                            "predicates": [
                                {
                                    "operation": "EQUALS",
                                    "key": "display_name",
                                    "stringValue": "my-name",
                                }
                            ]
                        }
                    )

          Returns:
            ``V2beta1ListRunsResponse`` object.
        """
        response = self.client.list_runs(page_token, page_size, sort_by, experiment_id, namespace, filter)
        return response

    @keyword
    def get_all_runs(self, namespace: str, experiment_id: str | None = None, pipeline_version_id: str | None = None):
        """
        Returns a list of all pipeline runs in an experiment, filtering by pipeline_version_id when provided.
        When needed, this function goes through pagination in order to get all the pipeline run
        """

        if experiment_id is None:
            experiment_id = self.get_default_experiment_id()

        if pipeline_version_id is not None:
            my_filter = json.dumps(
                {
                    "predicates": [
                        {
                            "operation": "EQUALS",
                            "key": "pipeline_version_id",
                            "stringValue": "PIPELINE_VERSION_ID",
                        }
                    ]
                }
            ).replace("PIPELINE_VERSION_ID", pipeline_version_id)
        else:
            my_filter = ""

        all_runs = []
        next_page_token = ""
        while next_page_token is not None:
            response = self.list_runs(
                page_token=next_page_token,
                page_size=10,
                sort_by="created_at desc",
                experiment_id=experiment_id,
                namespace=namespace,
                filter=my_filter,
            )
            next_page_token = response.next_page_token
            if response.runs is not None:
                all_runs.extend(response.runs)

        return all_runs

    @keyword
    def delete_all_runs_in_experiment(
        self, namespace: str, experiment_id: str | None = None, pipeline_version_id: str | None = None
    ):
        """
        Delete all pipeline runs in a namespace and experiment, optionally filtering by pipeline_version_id
        :param namespace: Namespace where to delete the runs
        :param experiment_id: Experiment ID where to find the runs. If not provided, delete from Default experiment
        :param pipeline_version_id:  If provided, delete only runs for this pipeline_version_id
        :return:
        """
        message = (
            f"Deleting all runs: namespace={namespace},"
            f"experiment_id={experiment_id}, pipeline_version_id={pipeline_version_id}"
        )
        print(message)
        all_runs = self.get_all_runs(
            namespace=namespace, experiment_id=experiment_id, pipeline_version_id=pipeline_version_id
        )
        for pipeline_run in all_runs:
            self.delete_run(pipeline_run.run_id)

    @keyword
    def delete_all_runs_for_pipeline(self, namespace: str, pipeline_id: str, experiment_id: str | None = None):
        """Delete all pipeline runs for all versions for a given pipeline and experiment. If experiment_id is not
        provided, Default experiment will be used"""
        all_versions = self.get_all_pipeline_versions(pipeline_id=pipeline_id)
        for pipeline_version in all_versions:
            self.delete_all_runs_in_experiment(
                namespace=namespace,
                experiment_id=experiment_id,
                pipeline_version_id=pipeline_version.pipeline_version_id,
            )

    @keyword
    def delete_run(self, run_id):
        """Deletes a run"""
        print(f"Deleting run {run_id}")
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
        """Creates a pipeline run from a python function"""
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
