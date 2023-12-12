from robot.api import logger
from robot.libraries.BuiltIn import BuiltIn
from robotlibcore import keyword
from caikit_nlp_client import HttpClient, GrpcClient


class CaikitPythonClient:
    """keywords to test https://github.com/opendatahub-io/caikit-nlp-client"""
    def __init__(self):
        self.BuiltIn = BuiltIn()
        self.self.client = None

    @keyword
    def get_http_client_without_ssl_validation(self, host, port):
        self.self.client = HttpClient(f"https://{host}:{port}", verify=False)
        self.get_client()
        # return  client
    
    @keyword
    def get_http_client_with_tls(self, host, port, ca_cert_path):
        self.client = HttpClient(f"https://{host}:{port}", ca_cert_path=ca_cert_path)
        self.get_client()
        # return  client
        
    @keyword
    def get_http_client_with_mtls(self, host, port, ca_cert_path, client_cert_path, client_key_path):
        self.client = HttpClient(f"https://{host}:{port}", ca_cert_path=ca_cert_path, client_cert_path=client_cert_path,
                            client_key_path=client_key_path)
        self.get_client()
        # return  client
    
    @keyword
    def get_grpc_client_without_ssl_validation(self, host, port):
        self.client = GrpcClient(host, port, verify=False)
        self.get_client()
        # return  client
    
    @keyword
    def get_grpc_client_with_tls(self, host, port, ca_cert_path):
        self.client = GrpcClient(host, port, ca_cert_path=ca_cert_path)
        self.get_client()
        # return  client    
    
    @keyword
    def get_grpc_client_with_mtls(self, host, port, ca_cert_path, client_cert_path, client_key_path):
        self.client = GrpcClient(host, port, ca_cert_path=ca_cert_path, client_cert_path=client_cert_path,
                            client_key_path=client_key_path)
        self.get_client()
        # return  client
    
    def get_client(self):
        if  self.client:
            return  self.client
        else:
            self.BuiltIn.fail("Something went wrong while setting up the connection to the host")