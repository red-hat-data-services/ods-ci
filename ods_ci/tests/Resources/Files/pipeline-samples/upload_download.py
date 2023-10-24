"""Test pipeline to exercise various data flow mechanisms."""
import kfp
from ods_ci.libs.DataSciencePipelinesKfpTekton import DataSciencePipelinesKfpTekton


"""Producer"""


def send_file(
    file_size_bytes: int,
    outgoingfile: kfp.components.OutputPath(),
):
    import os
    import zipfile

    def create_large_file(file_path, size_in_bytes):
        with open(file_path, 'wb') as f:
            f.write(os.urandom(size_in_bytes))

    def zip_file(input_file_path, output_zip_path):
        with zipfile.ZipFile(output_zip_path, 'w', compression=zipfile.ZIP_DEFLATED) as zipf:
            zipf.write(input_file_path, os.path.basename(input_file_path))

    print("starting creating the file...")
    file_path = "/tmp/large_file.txt"
    create_large_file(file_path, file_size_bytes)
    zip_file(file_path, outgoingfile)
    print("done")


"""Consumer"""


def receive_file(
    incomingfile: kfp.components.InputPath(),
    saveartifact: kfp.components.OutputPath(),
):
    import os
    import shutil

    print("reading %s, size is %s" % (incomingfile, os.path.getsize(incomingfile)))

    with open(incomingfile, "rb") as f:
        b = f.read(1)
        print("read byte: %s" % b)
        f.close()

    print("copying in %s to out %s" % (incomingfile, saveartifact))
    shutil.copyfile(incomingfile, saveartifact)


def test_uploaded_artifact(previous_step: kfp.components.InputPath(), file_size_bytes: int, mlpipeline_minio_artifact_secret: str):
    from minio import Minio
    import base64
    import json

    print(previous_step)
    name_data = previous_step.split('/')
    object_name = 'artifacts/' + name_data[4] + '/receive-file/saveartifact.tgz'

    mlpipeline_minio_artifact_secret = json.loads(mlpipeline_minio_artifact_secret)

    def inner_decode(my_str):
        return base64.b64decode(my_str).decode("utf-8")

    host = inner_decode(mlpipeline_minio_artifact_secret["host"])
    port = inner_decode(mlpipeline_minio_artifact_secret["port"])
    access_key = inner_decode(mlpipeline_minio_artifact_secret["accesskey"])
    secret_key = inner_decode(mlpipeline_minio_artifact_secret["secretkey"])
    secure = inner_decode(mlpipeline_minio_artifact_secret["secure"])
    secure = secure.lower() == 'true'
    client = Minio(
        f'{host}:{port}',
        access_key=access_key,
        secret_key=secret_key,
        secure=secure
    )

    data = client.get_object('mlpipeline', object_name)
    with open('my-testfile', 'wb') as file_data:
        for d in data.stream(32 * 1024):
            file_data.write(d)
        bytes_written = file_data.tell()

    print(file_size_bytes, bytes_written)
    diff = round((bytes_written / file_size_bytes) - 1, 3)
    print(diff)
    # if not matching, the test will fail
    assert diff == 0


"""Build the producer component"""
send_file_op = kfp.components.create_component_from_func(
    send_file,
    base_image=DataSciencePipelinesKfpTekton.base_image,
)

"""Build the consumer component"""
receive_file_op = kfp.components.create_component_from_func(
    receive_file,
    base_image=DataSciencePipelinesKfpTekton.base_image,
)

test_uploaded_artifact_op = kfp.components.create_component_from_func(
    test_uploaded_artifact,
    base_image=DataSciencePipelinesKfpTekton.base_image,
    packages_to_install=['minio']
)

"""Wire up the pipeline"""


@kfp.dsl.pipeline(
    name="Test Data Passing Pipeline 1",
)
def wire_up_pipeline(mlpipeline_minio_artifact_secret):
    import json

    file_size_mb = 20
    file_size_bytes = file_size_mb * 1024 * 1024

    send_file_task = send_file_op(file_size_bytes)

    receive_file_task = receive_file_op(
        send_file_task.output,
    ).add_pod_annotation(name='artifact_outputs', value=json.dumps(['saveartifact']))

    test_uploaded_artifact_op(receive_file_task.output, file_size_bytes, mlpipeline_minio_artifact_secret)


