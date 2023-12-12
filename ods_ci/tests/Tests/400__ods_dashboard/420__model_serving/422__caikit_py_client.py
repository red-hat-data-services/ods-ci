from caikit_nlp_client import HttpClient, GrpcClient
import pytest
import subprocess
import os

http_host = os.environ["MODEL_HTTP_ENDPOINT"]
grpc_host = os.environ["MODEL_GRPC_ENDPOINT"]
port = 443
text = "At what temperature does water boil?"


def test_http_skip_validation():
    http_client = HttpClient(f"https://{http_host}:{port}", verify=False)
    generated_text = http_client.generate_text("flan-t5-small-caikit", text)
    print("generated: answer: ",generated_text)
    print(generated_text)
    assert generated_text == "74 degrees F"

def test_http_tls():
    result = subprocess.run(["tests/e2e/get_cert.sh"])
    assert  result.returncode == 0
    http_client = HttpClient(f"https://{http_host}:{port}", ca_cert_path="openshift_ca_istio_knative.crt")
    generated_text = http_client.generate_text("flan-t5-small-caikit", text)
    print(generated_text)
    assert generated_text == "74 degrees F"

def test_http_mtls():
    result = subprocess.run(["tests/e2e/get_cert.sh"])
    assert  result.returncode == 0
    result = subprocess.run(["tests/e2e/gen_client_certs.sh"])
    assert  result.returncode == 0
    http_client = HttpClient(f"https://{http_host}:{port}", ca_cert_path="openshift_ca_istio_knative.crt", client_cert_path="tmp/client_cert/public.crt", client_key_path="tmp/client_cert/private.key")
    generated_text = http_client.generate_text("flan-t5-small-caikit", text)
    print(generated_text)
    assert generated_text == "74 degrees F"

def test_grpc_skip_validation():
    grpc_client = GrpcClient(grpc_host, port, verify=False)
    generated_text = grpc_client.generate_text("flan-t5-small-caikit", text)
    print("generated: answer: ",generated_text)
    assert generated_text == "74 degrees F"

def test_grpc_tls():
    result = subprocess.run(["tests/e2e/get_cert.sh"])
    assert  result.returncode == 0
    grpc_client = GrpcClient(grpc_host, port, ca_cert="openshift_ca_istio_knative.crt")
    generated_text = grpc_client.generate_text("flan-t5-small-caikit", text)
    print(generated_text)
    assert generated_text == "74 degrees F"
    

def test_grpc_mtls():
    result = subprocess.run(["tests/e2e/get_cert.sh"])
    assert  result.returncode == 0
    result = subprocess.run(["tests/e2e/gen_client_certs.sh"])
    assert  result.returncode == 0
    grpc_client = GrpcClient(grpc_host, port, ca_cert="openshift_ca_istio_knative.crt", client_cert="tmp/client_cert/public.crt", client_key="tmp/client_cert/private.key")
    generated_text = grpc_client.generate_text("flan-t5-small-caikit", text)
    print(generated_text)
    assert generated_text == "74 degrees F"

# test_http_skip_validation()
# test_http_tls()
# test_http_mtls()
# test_grpc_skip_validation()
# test_grpc_tls()
# test_grpc_mtls()
