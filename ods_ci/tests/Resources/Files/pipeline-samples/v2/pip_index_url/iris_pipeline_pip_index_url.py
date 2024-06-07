"""Iris pipeline for pip_index_url clusters

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
from kfp import Client, compiler, dsl
from kfp.dsl import ClassificationMetrics, Dataset, Input, Model, Output
from kfp import kubernetes

common_base_image = "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"


@dsl.component(base_image=common_base_image,
               packages_to_install=["pandas==2.2.0"],
               pip_index_urls=['$PIP_INDEX_URL']
               )
def create_dataset(iris_dataset: Output[Dataset]):
    import pandas as pd
    from io import StringIO

    data = """
    5.1,3.5,1.4,0.2,Iris-setosa
    4.9,3.0,1.4,0.2,Iris-setosa
    4.7,3.2,1.3,0.2,Iris-setosa
    4.6,3.1,1.5,0.2,Iris-setosa
    5.0,3.6,1.4,0.2,Iris-setosa
    5.7,3.8,1.7,0.3,Iris-setosa
    5.1,3.8,1.5,0.3,Iris-setosa
    5.4,3.4,1.7,0.2,Iris-setosa
    5.1,3.7,1.5,0.4,Iris-setosa
    5.1,3.4,1.5,0.2,Iris-setosa
    5.0,3.5,1.3,0.3,Iris-setosa
    4.5,2.3,1.3,0.3,Iris-setosa
    4.4,3.2,1.3,0.2,Iris-setosa
    5.0,3.5,1.6,0.6,Iris-setosa
    5.1,3.8,1.9,0.4,Iris-setosa
    4.8,3.0,1.4,0.3,Iris-setosa
    5.1,3.8,1.6,0.2,Iris-setosa
    4.6,3.2,1.4,0.2,Iris-setosa
    5.3,3.7,1.5,0.2,Iris-setosa
    5.0,3.3,1.4,0.2,Iris-setosa
    7.0,3.2,4.7,1.4,Iris-versicolor
    6.4,3.2,4.5,1.5,Iris-versicolor
    6.9,3.1,4.9,1.5,Iris-versicolor
    5.5,2.3,4.0,1.3,Iris-versicolor
    6.5,2.8,4.6,1.5,Iris-versicolor
    6.2,2.2,4.5,1.5,Iris-versicolor
    5.6,2.5,3.9,1.1,Iris-versicolor
    5.9,3.2,4.8,1.8,Iris-versicolor
    6.1,2.8,4.0,1.3,Iris-versicolor
    6.3,2.5,4.9,1.5,Iris-versicolor
    6.1,2.8,4.7,1.2,Iris-versicolor
    6.4,2.9,4.3,1.3,Iris-versicolor
    6.6,3.0,4.4,1.4,Iris-versicolor
    5.6,2.7,4.2,1.3,Iris-versicolor
    5.7,3.0,4.2,1.2,Iris-versicolor
    5.7,2.9,4.2,1.3,Iris-versicolor
    6.2,2.9,4.3,1.3,Iris-versicolor
    5.1,2.5,3.0,1.1,Iris-versicolor
    5.7,2.8,4.1,1.3,Iris-versicolor
    6.3,3.3,6.0,2.5,Iris-virginica
    5.8,2.7,5.1,1.9,Iris-virginica
    7.1,3.0,5.9,2.1,Iris-virginica
    6.3,2.9,5.6,1.8,Iris-virginica
    6.5,3.0,5.8,2.2,Iris-virginica
    6.9,3.1,5.1,2.3,Iris-virginica
    5.8,2.7,5.1,1.9,Iris-virginica
    6.8,3.2,5.9,2.3,Iris-virginica
    6.7,3.3,5.7,2.5,Iris-virginica
    6.7,3.0,5.2,2.3,Iris-virginica
    6.3,2.5,5.0,1.9,Iris-virginica
    6.5,3.0,5.2,2.0,Iris-virginica
    6.2,3.4,5.4,2.3,Iris-virginica
    5.9,3.0,5.1,1.8,Iris-virginica
    """
    col_names = ["Sepal_Length", "Sepal_Width", "Petal_Length", "Petal_Width", "Labels"]
    df = pd.read_csv(StringIO(data), names=col_names)

    with open(iris_dataset.path, "w") as f:
        df.to_csv(f)


@dsl.component(
    base_image=common_base_image,
    packages_to_install=["pandas==2.2.0", "scikit-learn==1.4.0"],
    pip_index_urls=['$PIP_INDEX_URL']
)
def normalize_dataset(
    input_iris_dataset: Input[Dataset],
    normalized_iris_dataset: Output[Dataset],
    standard_scaler: bool,
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


@dsl.component(
    base_image=common_base_image,
    packages_to_install=["pandas==2.2.0", "scikit-learn==1.4.0"],
    pip_index_urls=['$PIP_INDEX_URL']
)
def train_model(
    normalized_iris_dataset: Input[Dataset],
    model: Output[Model],
    metrics: Output[ClassificationMetrics],
    n_neighbors: int,
):
    import pickle

    import pandas as pd
    from sklearn.metrics import confusion_matrix, roc_curve
    from sklearn.model_selection import cross_val_predict, train_test_split
    from sklearn.neighbors import KNeighborsClassifier

    with open(normalized_iris_dataset.path) as f:
        df = pd.read_csv(f)

    y = df.pop("Labels")
    X = df

    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=0)

    clf = KNeighborsClassifier(n_neighbors=n_neighbors)
    clf.fit(X_train, y_train)

    predictions = cross_val_predict(clf, X_train, y_train, cv=3)
    metrics.log_confusion_matrix(
        ["Iris-Setosa", "Iris-Versicolour", "Iris-Virginica"],
        confusion_matrix(y_train, predictions).tolist(),  # .tolist() to convert np array to list.
    )

    model.metadata["framework"] = "scikit-learn"
    with open(model.path, "wb") as f:
        pickle.dump(clf, f)


@dsl.pipeline(name="iris-training-pipeline")
def my_pipeline(
    standard_scaler: bool = True,
    neighbors: int = 3,
):
    create_dataset_task = create_dataset()
    create_dataset_task.set_caching_options(False)
    kubernetes.use_config_map_as_env(create_dataset_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_index_url': 'PIP_INDEX_URL'})

    kubernetes.use_config_map_as_env(create_dataset_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_trusted_host': 'PIP_TRUSTED_HOST'})

    normalize_dataset_task = normalize_dataset(
        input_iris_dataset=create_dataset_task.outputs["iris_dataset"], standard_scaler=standard_scaler
    )
    normalize_dataset_task.set_caching_options(False)
    kubernetes.use_config_map_as_env(normalize_dataset_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_index_url': 'PIP_INDEX_URL'})

    kubernetes.use_config_map_as_env(normalize_dataset_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_trusted_host': 'PIP_TRUSTED_HOST'})

    train_model_task = train_model(
        normalized_iris_dataset=normalize_dataset_task.outputs["normalized_iris_dataset"], n_neighbors=neighbors
    )
    train_model_task.set_caching_options(False)
    kubernetes.use_config_map_as_env(train_model_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_index_url': 'PIP_INDEX_URL'})

    kubernetes.use_config_map_as_env(train_model_task,
                                     config_map_name='ds-pipeline-custom-env-vars',
                                     config_map_key_to_env={'pip_trusted_host': 'PIP_TRUSTED_HOST'})


compiler.Compiler().compile(pipeline_func=my_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))
