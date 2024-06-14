from kfp import dsl

from ods_ci.libs.DataSciencePipelinesKfp import DataSciencePipelinesKfp


@dsl.component(packages_to_install=["codeflare-sdk"], base_image=DataSciencePipelinesKfp.base_image)
def ray_fn() -> int:
    # workaround for RHOAIENG-6701
    import time
    import ray
    from codeflare_sdk.cluster.cluster import Cluster, ClusterConfiguration
    from codeflare_sdk import generate_cert

    cluster = Cluster(
        ClusterConfiguration(
            name="raytest",
            num_workers=1,
            head_cpus=1,
            head_memory=2,
            min_cpus=1,
            max_cpus=1,
            min_memory=1,
            max_memory=2,
            num_gpus=0,
            image="quay.io/project-codeflare/ray:latest-py39-cu118",
            verify_tls=False
        )
    )

    # always clean the resources
    cluster.down()
    print(cluster.status())
    cluster.up()
    # workaround for RHOAIENG-6701
    # cluster.wait_ready()
    time.sleep(180)
    print(cluster.status())
    print(cluster.details())

    ray_dashboard_uri = cluster.cluster_dashboard_uri()
    ray_cluster_uri = cluster.cluster_uri()
    print(ray_dashboard_uri)
    print(ray_cluster_uri)

    # before proceeding make sure the cluster exists and the uri is not empty
    assert ray_cluster_uri, "Ray cluster needs to be started and set before proceeding"

    # reset the ray context in case there's already one.
    ray.shutdown()
    # establish connection to ray cluster
    generate_cert.generate_tls_cert(cluster.config.name, cluster.config.namespace)
    generate_cert.export_env(cluster.config.name, cluster.config.namespace)
    ray.init(address=cluster.cluster_uri())
    print("Ray cluster is up and running: ", ray.is_initialized())

    @ray.remote
    def train_fn():
        return 100

    result = ray.get(train_fn.remote())
    assert 100 == result
    ray.shutdown()
    cluster.down()
    return result


@dsl.pipeline(
    name="Ray Integration Test",
    description="Ray Integration Test",
)
def ray_integration():
    ray_fn()
