from kfp import components, dsl


def print_message(message: str):
    """Prints a message"""
    print(message)


print_message_op = components.create_component_from_func(
    print_message,
    base_image="registry.redhat.io/ubi8/python-39@sha256:3523b184212e1f2243e76d8094ab52b01ea3015471471290d011625e1763af61",
)


@dsl.pipeline(
    name="version-test-pipeline",
    description="Pipeline that prints a hello message",
)
def version_test_pipeline(message: str = "Hello world"):
    print_message_task = print_message_op(message)


if __name__ == "__main__":
    from kfp_tekton.compiler import TektonCompiler

    TektonCompiler().compile(
        version_test_pipeline, package_path=__file__.replace(".py", "_compiled.yaml")
    )
