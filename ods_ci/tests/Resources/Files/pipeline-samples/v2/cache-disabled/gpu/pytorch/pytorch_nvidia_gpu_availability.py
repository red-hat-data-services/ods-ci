from kfp import compiler, dsl, kubernetes
from kfp.dsl import PipelineTask

#  Runtime: Pytorch with CUDA and Python 3.9 (UBI 9)
common_base_image = (
    "quay.io/modh/runtime-images@sha256:cee154f6db15de27929362f91baa128fc4f79b9c1930ab0f27561174d39aadfa"
)


def add_gpu_toleration(task: PipelineTask, accelerator_type: str, accelerator_limit: int):
    print(f"Adding GPU tolerations: {accelerator_type}({accelerator_limit})")
    task.set_accelerator_type(accelerator=accelerator_type)
    task.set_accelerator_limit(accelerator_limit)
    kubernetes.add_toleration(task, key=accelerator_type, operator="Exists", effect="NoSchedule")


@dsl.component(
    base_image=common_base_image
)
def verify_gpu_availability(gpu_toleration: bool):
    import torch

    cuda_available = torch.cuda.is_available()
    device_count = torch.cuda.device_count()
    print("------------------------------")
    print("GPU availability")
    print("------------------------------")
    print(f"cuda available: {cuda_available}")
    print(f"device count: {device_count}")
    if gpu_toleration:
        assert torch.cuda.is_available()
        assert torch.cuda.device_count() > 0
        t = torch.tensor([5, 5, 5], dtype=torch.int64, device='cuda')
    else:
        assert not torch.cuda.is_available()
        assert torch.cuda.device_count() == 0
        t = torch.tensor([5, 5, 5], dtype=torch.int64)
    print(f"tensor: {t}")
    print("GPU availability test: PASS")


@dsl.pipeline(
    name="pytorch-nvidia-gpu-availability",
    description="Verifies pipeline tasks run on GPU nodes only when tolerations are added",
)
def pytorch_nvidia_gpu_availability():
    verify_gpu_availability(gpu_toleration=False).set_caching_options(False)

    task_with_toleration = verify_gpu_availability(gpu_toleration=True).set_caching_options(False)
    add_gpu_toleration(task_with_toleration, "nvidia.com/gpu", 1)


if __name__ == "__main__":
    compiler.Compiler().compile(pytorch_nvidia_gpu_availability, package_path=__file__.replace(".py", "_compiled.yaml"))
