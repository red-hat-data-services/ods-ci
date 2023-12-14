from kfp import components, dsl
from ods_ci.libs.DataSciencePipelinesKfpTekton import DataSciencePipelinesKfpTekton


def ray_fn(openshift_server:str, openshift_token:str) -> int:
    from codeflare_sdk.cluster.cluster import Cluster, ClusterConfiguration
    from codeflare_sdk.cluster.auth import TokenAuthentication
    import ray

    print('before login')
    auth = TokenAuthentication(
        token=openshift_token,
        server=openshift_server,
        skip_tls=True
    )
    auth_return = auth.login()
    print(f'auth_return: "{auth_return}"')
    print('after login')
    cluster = Cluster(ClusterConfiguration(
        name='raytest',
        # namespace must exist, and it is the same from 432__data-science-pipelines-tekton.robot
        namespace='pipelineskfptekton1',
        num_workers=1,
        head_cpus='500m',
        min_memory=1,
        max_memory=1,
        num_gpus=0,
        image="quay.io/project-codeflare/ray:latest-py39-cu118",
        instascale=False
    ))
    # workaround for https://github.com/project-codeflare/codeflare-sdk/pull/412
    cluster_file_name = '/opt/app-root/src/.codeflare/appwrapper/raytest.yaml'
    # Read in the file
    with open(cluster_file_name, 'r') as file:
        filedata = file.read()

    # Replace the target string
    filedata = filedata.replace('busybox:1.28', 'quay.io/project-codeflare/busybox:latest')

    # Write the file out again
    with open(cluster_file_name, 'w') as file:
        file.write(filedata)
    # end workaround

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
        ray_fn, base_image=DataSciencePipelinesKfpTekton.base_image,
        packages_to_install=['codeflare-sdk']
    )
    ray_op(openshift_server, openshift_token)
