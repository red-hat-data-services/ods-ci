from kfp import compiler, dsl

common_base_image = (
    "registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61"
)


@dsl.component(base_image=common_base_image)
def print_message_and_fail():
    """Prints a message and fails"""
    print("This is a test of failing task")
    raise ValueError("Task failed!")


@dsl.pipeline(name="fail-pipeline", description="Pipeline that prints a message and fails")
def fail_pipeline():
    print_message_and_fail().set_caching_options(False)


if __name__ == "__main__":
    compiler.Compiler().compile(fail_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))
