from kfp import compiler, dsl

common_base_image = (
    "registry.redhat.io/ubi9/python-312@sha256:e80ff3673c95b91f0dafdbe97afb261eab8244d7fd8b47e20ffcbcfee27fb168"
)


@dsl.component(base_image=common_base_image)
def print_message(message: str):
    import datetime  # noqa: PLC0415
    import time  # noqa: PLC0415

    t_end = time.time() + 60
    while time.time() < t_end:
        print(message + " (" + str(datetime.datetime.now()) + ")")


@dsl.pipeline(
    name="log-streaming-pipeline",
    description="Pipeline that prints a hello message in a loop to test log streaming in Dashboard",
)
def log_streaming_pipeline(message: str = "Hello world"):
    print_message(message=message).set_caching_options(False)


if __name__ == "__main__":
    compiler.Compiler().compile(log_streaming_pipeline, package_path=__file__.replace(".py", "_compiled.yaml"))
