from kfp import components, dsl


def print_message(message: str) -> str:
    """Prints a message"""
    print(message)
    return message


def print_message_2(message: str):
    """Prints a message"""
    print(message)


print_message_op = components.create_component_from_func(
    print_message,
    base_image="registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168",
)

print_message_2_op = components.create_component_from_func(
    print_message_2,
    base_image="registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168",
)


@dsl.pipeline(
    name="version-test-pipeline",
    description="Pipeline that prints a hello message",
)
def version_test_pipeline(message: str = "Hello world"):
    print_message_task = print_message_op(message)
    print_message_2_task = print_message_2_op(message=print_message_task.output)


if __name__ == "__main__":
    from kfp_tekton.compiler import TektonCompiler

    TektonCompiler().compile(
        version_test_pipeline, package_path=__file__.replace(".py", "_compiled.yaml")
    )
