from kfp import compiler, dsl
from kfp.dsl import Dataset, Input, Output

common_base_image = (
    "registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168"
)


@dsl.component(
    base_image=common_base_image,
    packages_to_install=["pandas==2.2.0", "scikit-learn==1.4.0"],
)
def normalize_dataset(
    input_iris_dataset: Input[Dataset], normalized_iris_dataset: Output[Dataset], standard_scaler: bool
):
    import pandas as pd  # noqa: PLC0415
    from sklearn.preprocessing import MinMaxScaler, StandardScaler  # noqa: PLC0415

    with open(input_iris_dataset.path) as f:
        df = pd.read_csv(f)
    labels = df.pop("Labels")

    scaler = StandardScaler() if standard_scaler else MinMaxScaler()

    df = pd.DataFrame(scaler.fit_transform(df))
    df["Labels"] = labels
    normalized_iris_dataset.metadata["state"] = "Normalized"
    with open(normalized_iris_dataset.path, "w") as f:
        df.to_csv(f)


@dsl.pipeline(name="my-pipe")
def my_pipeline(
    artifact_uri: str,
    standard_scaler: bool = True,
):
    importer_task = dsl.importer(artifact_uri=artifact_uri, artifact_class=dsl.Dataset, reimport=True)
    importer_task.set_caching_options(False)
    normalize_dataset_task = normalize_dataset(input_iris_dataset=importer_task.output, standard_scaler=standard_scaler)
    normalize_dataset_task.set_caching_options(False)


if __name__ == "__main__":
    compiler.Compiler().compile(my_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))
