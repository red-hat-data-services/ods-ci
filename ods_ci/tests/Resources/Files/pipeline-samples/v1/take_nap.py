from kfp import components, dsl


def take_nap(naptime_secs: int) -> str:
    """Sleeps for secs"""
    from time import sleep

    print(f"Sleeping for {naptime_secs} seconds: Zzzzzz ...")
    sleep(naptime_secs)
    return "I'm awake now. Did I snore?"


def wake_up(message: str):
    """Wakes up from nap printing a message"""
    print(message)


take_nap_op = components.create_component_from_func(
    take_nap,
    base_image="registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168",
)

wake_up_op = components.create_component_from_func(
    wake_up,
    base_image="registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168",
)


@dsl.pipeline(
    name="take-nap-pipeline",
    description="Pipeline that sleeps for 15 mins (900 secs)",
)
def take_nap_pipeline(naptime_secs: int = 900):
    take_nap_task = take_nap_op(naptime_secs)
    wake_up_task = wake_up_op(message=take_nap_task.output)


if __name__ == "__main__":
    from kfp_tekton.compiler import TektonCompiler

    TektonCompiler().compile(take_nap_pipeline, package_path=__file__.replace(".py", ".yaml"))
