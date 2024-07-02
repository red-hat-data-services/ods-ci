import os
from kfp import dsl, compiler
from kfp.dsl import (component, Output, ClassificationMetrics, Metrics, HTML,
                     Markdown)

# In tests, we install a KFP package from the PR under test. Users should not
# normally need to specify `kfp_package_path` in their component definitions.
_KFP_PACKAGE_PATH = os.getenv('KFP_PACKAGE_PATH')

@component(
    base_image='registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61',
    kfp_package_path=_KFP_PACKAGE_PATH,
)
def html_visualization(html_artifact: Output[HTML]):
    import os
    target_size = 110 * 1024 * 1024  # 110 MB
    chunk_size = 1024 * 1024  # 1 MB

    with open("output_file.txt", "wb") as f:
        while os.path.getsize("output_file.txt") < target_size:
            f.write(b'0' * chunk_size)


@dsl.pipeline(name='over-100MB-artifact')
def generate_over_100mb_artifact():
    html_visualization_op = html_visualization()


compiler.Compiler().compile(pipeline_func=generate_over_100mb_artifact, package_path=__file__.replace(".py",
                                                                                                      "_compiled.yaml"))
