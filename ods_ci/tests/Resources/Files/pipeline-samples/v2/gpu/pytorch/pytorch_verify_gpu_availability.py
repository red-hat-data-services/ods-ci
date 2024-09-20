from kfp import compiler, dsl, kubernetes
from kfp.dsl import PipelineTask

#  Runtime: Pytorch with CUDA and Python 3.9 (UBI 9)
common_base_image = (
    "quay.io/modh/runtime-images@sha256:cee154f6db15de27929362f91baa128fc4f79b9c1930ab0f27561174d39aadfa"
)


# Plain Python image
# common_base_image = (
#     "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"
# )


def add_pip_index_configuration(task: PipelineTask):
    kubernetes.use_config_map_as_env(
        task,
        config_map_name="ds-pipeline-custom-env-vars",
        config_map_key_to_env={"pip_index_url": "PIP_INDEX_URL", "pip_trusted_host": "PIP_TRUSTED_HOST"},
    )


def add_gpu_toleration(task: PipelineTask, accelerator_type: str, accelerator_limit: int):
    print("Adding GPU tolerations")
    task.set_accelerator_type(accelerator=accelerator_type)
    task.set_accelerator_limit(accelerator_limit)
    kubernetes.add_toleration(task, key=accelerator_type, operator="Exists", effect="NoSchedule")


@dsl.component(base_image=common_base_image, packages_to_install=["torch"], pip_index_urls=["$PIP_INDEX_URL"])
def verify_gpu_availability(gpu_toleration_added: bool):
    import torch  # noqa: PLC0415

    cuda_available = torch.cuda.is_available()
    device_count = torch.cuda.device_count()
    print("------------------------------")
    print("GPU availability")
    print("------------------------------")
    print("gpu_toleration_added:" + str(gpu_toleration_added))
    print("torch.cuda.is_available():" + str(cuda_available))
    print("torch.cuda.device_count():" + str(device_count))
    if gpu_toleration_added and not torch.cuda.is_available():
        print("GPU availability test: FAIL")
        raise ValueError("GPU toleration was added but there is no GPU not available for this task")
    if not gpu_toleration_added and torch.cuda.is_available():
        print("GPU availability test: FAIL")
        raise ValueError("GPU toleration was not added but there is a GPU available for this task")
    print("GPU availability test: PASS")


@dsl.pipeline(
    name="pytorch-verify-gpu-availability",
    description="Verifies pipeline tasks run on GPU nodes only when tolerations are added",
)
def pytorch_verify_gpu_availability():
    task_without_toleration = verify_gpu_availability(gpu_toleration_added=False).set_caching_options(False)
    add_pip_index_configuration(task_without_toleration)

    task_with_toleration = verify_gpu_availability(gpu_toleration_added=True).set_caching_options(False)
    add_pip_index_configuration(task_with_toleration)
    add_gpu_toleration(task_with_toleration, "nvidia.com/gpu", 1)


if __name__ == "__main__":
    compiler.Compiler().compile(pytorch_verify_gpu_availability, package_path=__file__.replace(".py", "_compiled.yaml"))
