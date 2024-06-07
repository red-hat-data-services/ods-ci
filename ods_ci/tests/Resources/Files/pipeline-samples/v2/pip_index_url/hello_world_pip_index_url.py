"""Hello world pipeline for pip_index_url clusters

This is an example of setting pip_index_url in a pipeline task
obtaining the value from a ConfigMap, in order to be able to run
the pipeline in a pip_index_url environment.

The pipeline reads the values from a ConfigMap (ds-pipeline-custom-env-vars)
and creates the environment variables PIP_INDEX_URL and PIP_TRUSTED_HOST
in the pipeline task.

Note: when compiling the pipeline, the resulting yaml file only uses
PIP_INDEX_URL (this is a limitation of kfp 2.7.0). We need to manually
modify the yaml file to use PIP_TRUSTED_HOST.

"""
from kfp import compiler, dsl
from kfp import kubernetes

common_base_image = "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"


@dsl.component(base_image=common_base_image,
               pip_index_urls=['$PIP_INDEX_URL'])
def print_message(message: str):
    import os
    """Prints a message"""
    print("------------------------------------------------------------------")
    print(message)
    print('pip_index_url:' + os.environ['PIP_INDEX_URL'])
    print('pip_trusted_host:' + os.environ['PIP_TRUSTED_HOST'])
    print("------------------------------------------------------------------")


@dsl.pipeline(name="hello-world-pipeline", description="Pipeline that prints a hello message")
def hello_world_pipeline(message: str = "Hello world"):
    print_message_task = print_message(message=message)
    print_message_task.set_caching_options(False)

    kubernetes.use_config_map_as_env(print_message_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_index_url': 'PIP_INDEX_URL'})

    kubernetes.use_config_map_as_env(print_message_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_trusted_host': 'PIP_TRUSTED_HOST'})


if __name__ == "__main__":
    compiler.Compiler().compile(hello_world_pipeline,
                                package_path=__file__.replace(".py", "_compiled.yaml"))
