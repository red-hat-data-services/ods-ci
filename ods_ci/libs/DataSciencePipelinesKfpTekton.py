import subprocess
from json import JSONDecodeError
import requests
import os
import json
import time
from robotlibcore import keyword
import base64
from kfp import dsl
from kfp import components
import kfp_tekton
from kfp_tekton.compiler import TektonCompiler
from DataSciencePipelinesAPI import DataSciencePipelinesAPI


# The pipelines methods are static
# ----------------------------------- begin pipeline methods -----------------------------------
def random_num(low: int, high: int) -> int:
    """Generate a random number between low and high."""
    import random
    result = random.randint(low, high)
    print(result)
    return result


def flip_coin() -> str:
    """Flip a coin and output heads or tails randomly."""
    import random
    result = 'heads' if random.randint(0, 1) == 0 else 'tails'
    print(result)
    return result


def print_msg(msg: str):
    """Print a message."""
    print(msg)


# source https://github.com/kubeflow/kfp-tekton/blob/master/samples/flip-coin/condition.py
@dsl.pipeline(
    name='conditional-execution-pipeline',
    description='Shows how to use dsl.Condition().'
)
def flipcoin_pipeline():
    flip_coin_op = components.create_component_from_func(
        flip_coin, base_image='python:alpine3.6')
    print_op = components.create_component_from_func(
        print_msg, base_image='python:alpine3.6')
    random_num_op = components.create_component_from_func(
        random_num, base_image='python:alpine3.6')

    flip = flip_coin_op()
    with dsl.Condition(flip.output == 'heads'):
        random_num_head = random_num_op(0, 9)
        with dsl.Condition(random_num_head.output > 5):
            print_op('heads and %s > 5!' % random_num_head.output)
        with dsl.Condition(random_num_head.output <= 5):
            print_op('heads and %s <= 5!' % random_num_head.output)

    with dsl.Condition(flip.output == 'tails'):
        random_num_tail = random_num_op(10, 19)
        with dsl.Condition(random_num_tail.output > 15):
            print_op('tails and %s > 15!' % random_num_tail.output)
        with dsl.Condition(random_num_tail.output <= 15):
            print_op('tails and %s <= 15!' % random_num_tail.output)
# ----------------------------------- end pipeline methods -----------------------------------


# The name of the function should be kfp_tekton_<real_fn_call>. Example:
# real_fn_call=create_run_from_pipeline_func
# fn=kfp_tekton_create_run_from_pipeline_func
class DataSciencePipelinesKfpTekton:
    def __init__(self):
        self.client = None
        self.api = None

    def get_client(self, user, pwd, project):
        if self.client is None:
            self.api = DataSciencePipelinesAPI()
            self.api.login_using_user_and_password(user, pwd, project)
            self.client = kfp_tekton.TektonClient(
                host=f'https://{self.api.route}/',
                existing_token=self.api.sa_token,
                ssl_ca_cert=self.get_cert(self.api)
            )
        return self.client, self.api

    def get_cert(self, api):
        cert_json, _ = api.run_oc('oc get secret -n openshift-ingress-operator router-ca -o json')
        cert = json.loads(cert_json)['data']['tls.crt']
        decoded_cert = base64.b64decode(cert).decode('utf-8')

        file_name = '/tmp/kft-cert'
        cert_file = open(file_name, "w")
        cert_file.write(decoded_cert)
        cert_file.close()
        return file_name

    @keyword
    def kfp_tekton_create_run_from_pipeline_func(self, user, pwd, project, fn):
        client, _ = self.get_client(user, pwd, project)
        # it is not a good idea use eval at all, but this is for testing purpose and make it easy the integration with
        # the Robot Framework
        # the fn parameter is without ()
        # example: flipcoin_pipeline
        pipeline = eval(fn)
        # create_run_from_pipeline_func will compile the code
        # if you need to see the yaml, for debugging purpose, call: TektonCompiler().compile(pipeline, f'{fn}.yaml')
        result = client.create_run_from_pipeline_func(pipeline_func=pipeline, arguments={})
        return result

    # we are calling DataSciencePipelinesAPI because of https://github.com/kubeflow/kfp-tekton/issues/1223
    # The code that I am seeing locally is `not in ['succeeded', 'failed', 'skipped', 'error']`
    # Our endpoint is returning Completed. I can't see where is the source code for 1.5 in order to make an assumption
    # if it is an issue or not
    # Once we found a final answer. we can only call client instead of api. the test case won't change
    @keyword
    def kfp_tekton_wait_for_run_completion(self, user, pwd, project, run_result):
        _, api = self.get_client(user, pwd, project)
        return api.check_run_status(run_result.run_id)

