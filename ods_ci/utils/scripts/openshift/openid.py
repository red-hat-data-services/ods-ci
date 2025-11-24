import click

from ods_ci.utils.scripts.logger import log
import json
import requests
from string import Template


import sys

REGISTRATION_BODY_TEMPLATE = Template("""
    {
        "application_type": "web",
        "redirect_uris": [
           "${redirect_uris}"
        ],
        "client_name": "${client_name}",
        "contacts": [
            "${contact_emails}"
        ]
    }
""")

class OpenIdOps:
    """Class for OpenID identity provider operations"""

    def __init__(self):
        """Initialize OpenIdOps"""
        self.token = ""
        self.jenkins_props_file = ""
        self.client_registration_token = ""
        self.idp_name = ""
        self.client_id = ""
        self.client_name = ""
        self.client_secret = ""
        self.registration_endpoint = ""

    def _write_jenkins_properties(self):
        """Write TOKEN to a properties file for Jenkins to read"""
        if self.jenkins_props_file:
            try:
                with open(self.jenkins_props_file, "w") as f:
                    f.write(f"CLIENT_NAME={self.client_name}\n")
                    f.write(f"CLIENT_ID={self.client_id}\n")
                    f.write(f"CLIENT_SECRET={self.client_secret}\n")
                    f.write(f"CLIENT_REGISTRATION_TOKEN={self.client_registration_token}\n")
                log.info(f"Client details written to Jenkins properties file: {self.jenkins_props_file}")
            except Exception as e:
                log.error(f"Failed to write registration token to properties file: {e}")
                return 1
        return

    def dynamic_client_registration(self, registration_endpoint: str, token: str, redirect_uris: list[str], client_name: str, contact_emails: list[str], jenkins_props_file: str):
        self.token = token
        self.jenkins_props_file = jenkins_props_file
        self.registration_endpoint = registration_endpoint
        registration_body = REGISTRATION_BODY_TEMPLATE.substitute(
            redirect_uris=redirect_uris,
            client_name=client_name,
            contact_emails=contact_emails,
        )
        log.info(f"Registration body: {registration_body}")
        headers = {
            "Authorization": f"Bearer {self.token}",
        }
        request = requests.post(f"{self.registration_endpoint}", json=json.loads(registration_body), headers=headers)
        if request.status_code != 201:
            log.error(f"Failed to register client: {request.status_code} {request.json()['error']} - {request.json()['error_description']}")
            return 1
        log.info(f"Client registered successfully: {request.status_code}")
        self.client_name = request.json()["client_name"]
        self.client_id = request.json()["client_id"]
        self.client_secret = request.json()["client_secret"]
        self.client_registration_token = request.json()["registration_access_token"]
        self._write_jenkins_properties()
        return
    
    def delete_dynamic_client(self, registration_token: str, deletion_endpoint: str, client_name: str):
        headers = {
            "Authorization": f"Bearer {registration_token}",
        }
        request = requests.delete(f"{deletion_endpoint}", headers=headers)
        if request.status_code != 204:
            log.error(f"Failed to delete client {client_name}: {request.status_code} {request.text}")
            return 1
        log.info(f"Client {client_name} deleted successfully: {request.status_code}")
        return

    def add_openid_identity_provider(self, idp_name: str, client_id: str, client_secret: str, issuer_url: str):
        """Adds OpenID identity provider to the cluster"""
        log.info("Adding OpenID identity provider...")
        log.info("add_openid_identity_provider() method called successfully")
        return


@click.group()
def cli():
    """CLI for OpenID identity provider operations"""
    pass


@cli.command("register-client")
@click.option(
    "--token",
    required=True,
    help="Token required for client registration",
)
@click.option(
    "--registration-endpoint",
    required=True,
    help="Registration endpoint required for client registration",
)
@click.option(
    "--redirect-uri",
    required=True,
    multiple=True,
    help="Redirect URIs for the client (can be specified multiple times)",
)
@click.option(
    "--client-name",
    required=True,
    help="Name of the client to register",
)
@click.option(
    "--contact-email",
    required=True,
    multiple=True,
    help="Contact emails for the client (can be specified multiple times)",
)
@click.option(
    "--jenkins-props-file",
    default=None,
    help="Path to properties file for Jenkins to read TOKEN (e.g., env.properties)",
)
def register_client(token, registration_endpoint, redirect_uri, client_name, contact_email, jenkins_props_file):
    """Register an OpenID client dynamically"""
    openid_ops = OpenIdOps()
    exit(openid_ops.dynamic_client_registration(
        token=token,
        registration_endpoint=registration_endpoint,
        redirect_uris=",".join(list(redirect_uri)),
        client_name=client_name,
        contact_emails=",".join(list(contact_email)),
        jenkins_props_file=jenkins_props_file,
    ))


@cli.command("delete-client")
@click.option(
    "--registration-token",
    required=True,
    help="Registration token required for deleting OpenID client",
)
@click.option(
    "--deletion-endpoint",
    required=True,
    help="Deletion endpoint required for deleting OpenID client",
)
@click.option(
    "--client-name",
    required=True,
    help="Name of the client to delete",
)
def delete_client(registration_token, deletion_endpoint, client_name):
    """Delete an OpenID client dynamically"""
    openid_ops = OpenIdOps()

    exit(openid_ops.delete_dynamic_client(
        registration_token=registration_token,
        deletion_endpoint=deletion_endpoint,
        client_name=client_name,
    ))

@cli.command("add-openid-idp")
@click.option(
    "--idp-name",
    required=True,
    help="Token required for adding OpenID identity provider",
)
@click.option(
    "--client-id",
    required=True,
    help="Client ID required for adding OpenID identity provider",
)
@click.option(
    "--client-secret",
    required=True,
    help="Client secret required for adding OpenID identity provider",
)
@click.option(
    "--issuer-url",
    required=True,
    help="Issuer URL required for adding OpenID identity provider",
)
def add_openid_idp(idp_name: str, client_id: str, client_secret: str, registration_endpoint: str):
    """Add OpenID identity provider to the cluster"""
    openid_ops = OpenIdOps()

    exit(openid_ops.add_openid_identity_provider(
        idp_name=idp_name,
        client_id=client_id,
        client_secret=client_secret,
        registration_endpoint=registration_endpoint,
    ))

if __name__ == "__main__":
    cli()
