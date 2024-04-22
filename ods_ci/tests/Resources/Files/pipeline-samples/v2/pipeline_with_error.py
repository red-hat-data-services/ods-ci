import os

from kfp import compiler
from kfp import dsl
from kfp.dsl import InputPath, OutputPath


@dsl.component(base_image="quay.io/modh/runtime-images:runtime-cuda-tensorflow-ubi9-python-3.9-2023b-20240301")
def get_data(output_path: OutputPath()):
    import urllib.request
    print("starting download...")
    url = "https://raw.githubusercontent.com/rh-aiservices-bu/fraud-detection/main/data/card_transdata.csv"
    urllib.request.urlretrieve(url, output_path)
    print("done")


@dsl.component(
    base_image="quay.io/modh/runtime-images:runtime-cuda-tensorflow-ubi9-python-3.9-2023b-20240301",
    packages_to_install=["tf2onnx", "seaborn"],
)
def train_model(input_path: InputPath(), output_path: OutputPath()):
    import os.path

    # Replace 'path_to_file' with your file's path
    file_exists = os.path.exists(input_path)
    print(file_exists)  # This will print True if the file exists, otherwise False

    # fake model training, just to use output_path
    import urllib.request
    print("starting download...")
    url = "https://rhods-public.s3.amazonaws.com/modelmesh-samples/onnx/mnist.onnx"
    urllib.request.urlretrieve(url, output_path)
    print("done")


@dsl.pipeline(name=os.path.basename(__file__).replace('.py', ''))
def pipeline():
    get_data_task = get_data()
    # csv_file = get_data_task.output
    csv_file = get_data_task.output
    train_model_task = train_model(input_path=csv_file)


if __name__ == '__main__':
    print('''
    If you run this pipeline, it will return an error: MissingRegion: could not find region configuration
    If you rerun you should expect the same failure and not a cache related error
    ''')
    compiler.Compiler().compile(
        pipeline_func=pipeline,
        package_path=__file__.replace('.py', '.yaml')
    )

