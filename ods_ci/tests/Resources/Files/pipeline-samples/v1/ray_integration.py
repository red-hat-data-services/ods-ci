from kfp import components, dsl

from ods_ci.libs.DataSciencePipelinesKfp import DataSciencePipelinesKfp


def ray_fn(openshift_server: str, openshift_token: str) -> int:
    import ray
    from codeflare_sdk.cluster.auth import TokenAuthentication
    from codeflare_sdk.cluster.cluster import Cluster, ClusterConfiguration

    print("before login")
    auth = TokenAuthentication(token=openshift_token, server=openshift_server, skip_tls=True)
    auth_return = auth.login()
    print(f'auth_return: "{auth_return}"')
    print("after login")
    cluster = Cluster(
        ClusterConfiguration(
            name="raytest",
            # namespace must exist, and it is the same from 432__data-science-pipelines-tekton.robot
            namespace="pipelineskfptekton1",
            num_workers=1,
            head_cpus="500m",
            min_memory=1,
            max_memory=1,
            num_gpus=0,
            image="quay.io/project-codeflare/ray:latest-py39-cu118",
            instascale=False,
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
    ray.init(address=ray_cluster_uri)
    print("Ray cluster is up and running: ", ray.is_initialized())

    @ray.remote
    def train_fn():
        return 100

    result = ray.get(train_fn.remote())
    assert 100 == result
    ray.shutdown()
    cluster.down()
    auth.logout()
    return result


@dsl.pipeline(
    name="Ray Integration Test",
    description="Ray Integration Test",
)
def ray_integration(openshift_server, openshift_token):
    ray_op = components.create_component_from_func(
        ray_fn,
        base_image=DataSciencePipelinesKfp.base_image,
        packages_to_install=["codeflare-sdk"],
    )
    ray_op(openshift_server, openshift_token)
