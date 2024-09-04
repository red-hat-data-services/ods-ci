from kfp import compiler, dsl
from kfp.dsl import Dataset, Input, Output


common_base_image = "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"


@dsl.component(
    base_image=common_base_image,
    packages_to_install=["pandas==2.2.0", "scikit-learn==1.4.0"],
)
def normalize_dataset(
    input_iris_dataset: Input[Dataset],
    normalized_iris_dataset: Output[Dataset],
    standard_scaler: bool
):
    import pandas as pd
    from sklearn.preprocessing import MinMaxScaler, StandardScaler

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
def my_pipeline(artifact_uri: str, standard_scaler: bool = True,):
    importer_task = dsl.importer(
        artifact_uri=artifact_uri,
        artifact_class=dsl.Dataset,
        reimport=True)
    normalize_dataset(input_iris_dataset=importer_task.output, standard_scaler=standard_scaler)


if __name__ == "__main__":
    compiler.Compiler().compile(my_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))

