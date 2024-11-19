from kfp import compiler, dsl

common_base_image = (
    "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"
)

# image and the sdk has a fixed value because the version matters
@dsl.component(packages_to_install=["codeflare-sdk==v0.24.0"], base_image=common_base_image)
def ray_fn(
    AWS_DEFAULT_ENDPOINT: str,
    AWS_STORAGE_BUCKET: str,
    AWS_ACCESS_KEY_ID: str,
    AWS_SECRET_ACCESS_KEY: str,
    AWS_STORAGE_BUCKET_MNIST_DIR: str
) -> None:
    import openshift
    import subprocess
    import ray  # noqa: PLC0415
    import tempfile
    from codeflare_sdk import generate_cert  # noqa: PLC0415
    from codeflare_sdk.ray.cluster import Cluster, ClusterConfiguration  # noqa: PLC0415
    from codeflare_sdk.ray.client import RayJobClient
    from time import sleep

    training_script = """
import os

import torch
import requests
from pytorch_lightning import LightningModule, Trainer
from pytorch_lightning.callbacks.progress import TQDMProgressBar
from torch import nn
from torch.nn import functional as F
from torch.utils.data import DataLoader, random_split, RandomSampler
from torchmetrics import Accuracy
from torchvision import transforms
from torchvision.datasets import MNIST
import gzip
import shutil
from minio import Minio

PATH_DATASETS = os.environ.get("PATH_DATASETS", ".")
BATCH_SIZE = 256 if torch.cuda.is_available() else 64

local_mnist_path = os.path.dirname(os.path.abspath(__file__))

print("prior to running the trainer")
print("MASTER_ADDR: is ", os.getenv("MASTER_ADDR"))
print("MASTER_PORT: is ", os.getenv("MASTER_PORT"))

STORAGE_BUCKET_EXISTS = "AWS_DEFAULT_ENDPOINT" in os.environ
print("STORAGE_BUCKET_EXISTS: ", STORAGE_BUCKET_EXISTS)

print(f'Storage_Bucket_Default_Endpoint : is {os.environ.get("AWS_DEFAULT_ENDPOINT")}' if "AWS_DEFAULT_ENDPOINT" in os.environ else "")
print(f'Storage_Bucket_Name : is {os.environ.get("AWS_STORAGE_BUCKET")}' if "AWS_STORAGE_BUCKET" in os.environ else "")
print(f'Storage_Bucket_Mnist_Directory : is {os.environ.get("AWS_STORAGE_BUCKET_MNIST_DIR")}' if "AWS_STORAGE_BUCKET_MNIST_DIR" in os.environ else "")


class LitMNIST(LightningModule):
    def __init__(self, data_dir=PATH_DATASETS, hidden_size=64, learning_rate=2e-4):
        super().__init__()

        # Set our init args as class attributes
        self.data_dir = data_dir
        self.hidden_size = hidden_size
        self.learning_rate = learning_rate

        # Hardcode some dataset specific attributes
        self.num_classes = 10
        self.dims = (1, 28, 28)
        channels, width, height = self.dims
        self.transform = transforms.Compose(
            [
                transforms.ToTensor(),
                transforms.Normalize((0.1307,), (0.3081,)),
            ]
        )

        # Define PyTorch model
        self.model = nn.Sequential(
            nn.Flatten(),
            nn.Linear(channels * width * height, hidden_size),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_size, hidden_size),
            nn.ReLU(),
            nn.Dropout(0.1),
            nn.Linear(hidden_size, self.num_classes),
        )

        self.val_accuracy = Accuracy(task="multiclass", num_classes=10)
        self.test_accuracy = Accuracy(task="multiclass", num_classes=10)

    def forward(self, x):
        x = self.model(x)
        return F.log_softmax(x, dim=1)

    def training_step(self, batch, batch_idx):
        x, y = batch
        logits = self(x)
        loss = F.nll_loss(logits, y)
        return loss

    def validation_step(self, batch, batch_idx):
        x, y = batch
        logits = self(x)
        loss = F.nll_loss(logits, y)
        preds = torch.argmax(logits, dim=1)
        self.val_accuracy.update(preds, y)

        # Calling self.log will surface up scalars for you in TensorBoard
        self.log("val_loss", loss, prog_bar=True)
        self.log("val_acc", self.val_accuracy, prog_bar=True)

    def test_step(self, batch, batch_idx):
        x, y = batch
        logits = self(x)
        loss = F.nll_loss(logits, y)
        preds = torch.argmax(logits, dim=1)
        self.test_accuracy.update(preds, y)

        # Calling self.log will surface up scalars for you in TensorBoard
        self.log("test_loss", loss, prog_bar=True)
        self.log("test_acc", self.test_accuracy, prog_bar=True)

    def configure_optimizers(self):
        optimizer = torch.optim.Adam(self.parameters(), lr=self.learning_rate)
        return optimizer

    ####################
    # DATA RELATED HOOKS
    ####################

    def prepare_data(self):
        # download
        print("Downloading MNIST dataset...")

        if (
            STORAGE_BUCKET_EXISTS
            and os.environ.get("AWS_DEFAULT_ENDPOINT") != ""
            and os.environ.get("AWS_DEFAULT_ENDPOINT") != None
        ):
            print("Using storage bucket to download datasets...")

            dataset_dir = os.path.join(self.data_dir, "MNIST/raw")
            endpoint = os.environ.get("AWS_DEFAULT_ENDPOINT")
            access_key = os.environ.get("AWS_ACCESS_KEY_ID")
            secret_key = os.environ.get("AWS_SECRET_ACCESS_KEY")
            bucket_name = os.environ.get("AWS_STORAGE_BUCKET")

            # remove prefix if specified in storage bucket endpoint url
            secure = True
            if endpoint.startswith("https://"):
                endpoint = endpoint[len("https://") :]
            elif endpoint.startswith("http://"):
                endpoint = endpoint[len("http://") :]
                secure = False

            client = Minio(
                endpoint,
                access_key=access_key,
                secret_key=secret_key,
                cert_check=False,
                secure=secure,
            )

            if not os.path.exists(dataset_dir):
                os.makedirs(dataset_dir)
            else:
                print(f"Directory '{dataset_dir}' already exists")

            # To download datasets from storage bucket's specific directory, use prefix to provide directory name
            prefix = os.environ.get("AWS_STORAGE_BUCKET_MNIST_DIR")
            # download all files from prefix folder of storage bucket recursively
            for item in client.list_objects(bucket_name, prefix=prefix, recursive=True):
                file_name = item.object_name[len(prefix) + 1 :]
                dataset_file_path = os.path.join(dataset_dir, file_name)
                if not os.path.exists(dataset_file_path):
                    client.fget_object(bucket_name, item.object_name, dataset_file_path)
                else:
                    print(f"File-path '{dataset_file_path}' already exists")
                # Unzip files
                with gzip.open(dataset_file_path, "rb") as f_in:
                    with open(dataset_file_path.split(".")[:-1][0], "wb") as f_out:
                        shutil.copyfileobj(f_in, f_out)
                # delete zip file
                os.remove(dataset_file_path)
                unzipped_filepath = dataset_file_path.split(".")[0]
                if os.path.exists(unzipped_filepath):
                    print(
                        f"Unzipped and saved dataset file to path - {unzipped_filepath}"
                    )
            download_datasets = False

        else:
            print("Using default MNIST mirror reference to download datasets...")
            download_datasets = True

        MNIST(self.data_dir, train=True, download=download_datasets)
        MNIST(self.data_dir, train=False, download=download_datasets)

    def setup(self, stage=None):
        # Assign train/val datasets for use in dataloaders
        if stage == "fit" or stage is None:
            mnist_full = MNIST(
                self.data_dir, train=True, transform=self.transform, download=False
            )
            self.mnist_train, self.mnist_val = random_split(mnist_full, [55000, 5000])

        # Assign test dataset for use in dataloader(s)
        if stage == "test" or stage is None:
            self.mnist_test = MNIST(
                self.data_dir, train=False, transform=self.transform, download=False
            )

    def train_dataloader(self):
        return DataLoader(
            self.mnist_train,
            batch_size=BATCH_SIZE,
            sampler=RandomSampler(self.mnist_train, num_samples=1000),
        )

    def val_dataloader(self):
        return DataLoader(self.mnist_val, batch_size=BATCH_SIZE)

    def test_dataloader(self):
        return DataLoader(self.mnist_test, batch_size=BATCH_SIZE)

# Init DataLoader from MNIST Dataset

model = LitMNIST(data_dir=local_mnist_path)

print("GROUP: ", int(os.environ.get("GROUP_WORLD_SIZE", 1)))
print("LOCAL: ", int(os.environ.get("LOCAL_WORLD_SIZE", 1)))

# Initialize a trainer
trainer = Trainer(
    # devices=1 if torch.cuda.is_available() else None,  # limiting got iPython runs
    max_epochs=3,
    callbacks=[TQDMProgressBar(refresh_rate=20)],
    num_nodes=int(os.environ.get("GROUP_WORLD_SIZE", 1)),
    devices=int(os.environ.get("LOCAL_WORLD_SIZE", 1)),
    strategy="ddp",
)

# Train the model
trainer.fit(model)
"""

    pip_requirements = """
pytorch_lightning==2.4.0
torchmetrics==1.6.0
torchvision==0.20.1
minio
"""

    def assert_job_completion(status):
        if status == "SUCCEEDED":
            print(f"Job has completed: '{status}'")
            assert True
        else:
            print(f"Job has completed: '{status}'")
            assert False

    def assert_jobsubmit_withlogin(cluster, mnist_directory):
        with open("/run/secrets/kubernetes.io/serviceaccount/token") as token_file:
            auth_token = token_file.read()
        print("Auth token: " + auth_token)
        ray_dashboard = cluster.cluster_dashboard_uri()
        header = {"Authorization": f"Bearer {auth_token}"}
        client = RayJobClient(address=ray_dashboard, headers=header, verify=False)

        submission_id = client.submit_job(
            entrypoint="python mnist.py",
            runtime_env={
                "working_dir": mnist_directory,
                "pip": mnist_directory + "/mnist_pip_requirements.txt",
                "env_vars": {
                    "AWS_DEFAULT_ENDPOINT": AWS_DEFAULT_ENDPOINT,
                    "AWS_STORAGE_BUCKET": AWS_STORAGE_BUCKET,
                    "AWS_ACCESS_KEY_ID": AWS_ACCESS_KEY_ID,
                    "AWS_SECRET_ACCESS_KEY": AWS_SECRET_ACCESS_KEY,
                    "AWS_STORAGE_BUCKET_MNIST_DIR": AWS_STORAGE_BUCKET_MNIST_DIR
                },
            },
            entrypoint_num_cpus=1,
        )
        print(f"Submitted job with ID: {submission_id}")
        done = False
        time = 0
        timeout = 900
        while not done:
            status = client.get_job_status(submission_id)
            if status.is_terminal():
                break
            if not done:
                print(status)
                if timeout and time >= timeout:
                    raise TimeoutError(f"job has timed out after waiting {timeout}s")
                sleep(5)
                time += 5

        logs = client.get_job_logs(submission_id)
        print(logs)

        assert_job_completion(status)

        client.delete_job(submission_id)

        cluster.down()

    cluster = Cluster(
        ClusterConfiguration(
            name="raytest",
            num_workers=1,
            head_cpu_requests=1,
            head_cpu_limits=1,
            head_memory_requests=4,
            head_memory_limits=4,
            worker_cpu_requests=1,
            worker_cpu_limits=1,
            worker_memory_requests=1,
            worker_memory_limits=2,
            image="quay.io/modh/ray@sha256:db667df1bc437a7b0965e8031e905d3ab04b86390d764d120e05ea5a5c18d1b4",
            verify_tls=False
        )
    )

    # always clean the resources
    cluster.down()
    print(cluster.status())
    cluster.up()
    cluster.wait_ready()
    print(cluster.status())
    print(cluster.details())

    ray_dashboard_uri = cluster.cluster_dashboard_uri()
    ray_cluster_uri = cluster.cluster_uri()
    print(ray_dashboard_uri)
    print(ray_cluster_uri)

    # before proceeding make sure the cluster exists and the uri is not empty
    assert ray_cluster_uri, "Ray cluster needs to be started and set before proceeding"
    assert ray_dashboard_uri, "Ray dashboard needs to be started and set before proceeding"

    mnist_directory = tempfile.mkdtemp(prefix="mnist-dir")
    with open(mnist_directory + "/mnist.py", "w") as mnist_file:
        mnist_file.write(training_script)
    with open(mnist_directory + "/mnist_pip_requirements.txt", "w") as pip_requirements_file:
        pip_requirements_file.write(pip_requirements)
    
    assert_jobsubmit_withlogin(cluster, mnist_directory)
    
    cluster.down()

@dsl.pipeline(
    name="Ray Integration Test",
    description="Ray Integration Test",
)
def ray_job_integration(
    AWS_DEFAULT_ENDPOINT: str,
    AWS_STORAGE_BUCKET: str,
    AWS_ACCESS_KEY_ID: str,
    AWS_SECRET_ACCESS_KEY: str,
    AWS_STORAGE_BUCKET_MNIST_DIR: str
):
    ray_fn(
        AWS_DEFAULT_ENDPOINT=AWS_DEFAULT_ENDPOINT,
        AWS_STORAGE_BUCKET=AWS_STORAGE_BUCKET,
        AWS_ACCESS_KEY_ID=AWS_ACCESS_KEY_ID,
        AWS_SECRET_ACCESS_KEY=AWS_SECRET_ACCESS_KEY,
        AWS_STORAGE_BUCKET_MNIST_DIR=AWS_STORAGE_BUCKET_MNIST_DIR
    ).set_caching_options(False)


if __name__ == "__main__":
    compiler.Compiler().compile(ray_job_integration, package_path=__file__.replace(".py", "_compiled.yaml"))
