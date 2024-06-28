from kfp import dsl

from ods_ci.libs.DataSciencePipelinesKfp import DataSciencePipelinesKfp


# image and the sdk has a fixed value because the version matters
@dsl.component(packages_to_install=["codeflare-sdk==0.16.4"], base_image=DataSciencePipelinesKfp.base_image)
def ray_fn() -> int:
    import ray
    from codeflare_sdk.cluster.cluster import Cluster, ClusterConfiguration
    from codeflare_sdk import generate_cert

    cluster = Cluster(
        ClusterConfiguration(
            name="raytest",
            num_workers=1,
            head_cpus=1,
            head_memory=4,
            min_cpus=1,
            max_cpus=1,
            min_memory=1,
            max_memory=2,
            num_gpus=0,
            image="quay.io/project-codeflare/ray:2.20.0-py39-cu118",
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

    # reset the ray context in case there's already one.
    ray.shutdown()
    # establish connection to ray cluster
    generate_cert.generate_tls_cert(cluster.config.name, cluster.config.namespace)
    generate_cert.export_env(cluster.config.name, cluster.config.namespace)
    ray.init(address=cluster.cluster_uri(), logging_level="DEBUG")
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
