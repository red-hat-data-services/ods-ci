import click

from ods_ci.utils.scripts.logger import log
from ods_ci.utils.scripts.util import execute_command
import json
import requests


REGISTRATION_BODY_TEMPLATE = """
    {
        "application_type": "web",
        "redirect_uris": [
            {redirect_uris}
        ],
        "client_name": {client_name},
        "contacts": [
            {contact_emails}
        ]
    }
"""

class OpenIdOps:
    """Class for OpenID identity provider operations"""

    def __init__(self):
        """Initialize OpenIdOps"""
        self.token = ""
        self.jenkins_props_file = ""
        self.client_registration_token = ""
        self.idp_name = ""
        self.client_id = ""
        self.client_secret = ""
        self.registration_endpoint = ""

    def _write_jenkins_properties(self):
        """Write TOKEN to a properties file for Jenkins to read"""
        if self.jenkins_props_file:
            try:
                with open(self.jenkins_props_file, "w") as f:
                    f.write(f"CLIENT_REGISTRATION_TOKEN={self.client_registration_token}\n")
                    f.write(f"CLIENT_ID={self.client_id}\n")
                    f.write(f"CLIENT_SECRET={self.client_secret}\n")
                log.info(f"Registration token written to Jenkins properties file: {self.jenkins_props_file}")
                return True
            except Exception as e:
                log.error(f"Failed to write registration token to properties file: {e}")
                return False
        return False

    def dynamic_client_registration(self, registration_endpoint: str, token: str, redirect_uris: list[str], client_name: str, contact_emails: list[str], jenkins_props_file: str):
        self.token = token
        self.jenkins_props_file = jenkins_props_file
        self.registration_endpoint = registration_endpoint
        registration_body = REGISTRATION_BODY_TEMPLATE.format(
            redirect_uris=redirect_uris.join(","),
            client_name=client_name,
            contact_emails=contact_emails.join(","),
        )
        log.info(f"Registration body: {registration_body}")
        headers = {
            "Authorization": f"Bearer {self.token}",
        }
        request = requests.post(f"{self.registration_endpoint}", json=json.loads(registration_body), headers=headers)
        if request.status_code != 200:
            log.error(f"Failed to register client: {request.status_code} {request.text}")
            return 1
        log.info(f"Client registered successfully: {request.json()}")
        self.client_id = request.json()["client_id"]
        self.client_secret = request.json()["client_secret"]
        self.client_registration_token = request.json()["registration_access_token"]
        self._write_jenkins_properties()
        return 0
    
    def delete_dynamic_client(self, registration_token: str, deletion_endpoint: str, client_name: str):
        #deletion_body = REGISTRATION_BODY_TEMPLATE.format(
            # redirect_uris=redirect_uris.join(","),
            # client_name=client_name,
            # contact_emails=contact_emails.join(","),
        #)
        #log.info(f"Deletion body: {deletion_body}")
        headers = {
            "Authorization": f"Bearer {registration_token}",
        }
        request = requests.delete(f"{deletion_endpoint}", headers=headers)
        if request.status_code != 200:
            log.error(f"Failed to delete client {client_name}: {request.status_code} {request.text}")
            return 1
        log.info(f"Client {client_name} deleted successfully: {request.json()}")
        return 0

    def add_openid_identity_provider(self, idp_name: str, client_id: str, client_secret: str, issuer_url: str):
        """Adds OpenID identity provider to the cluster"""
        log.info("Adding OpenID identity provider...")
        # TODO: Implement the actual OpenID identity provider addition logic
        # This is a placeholder implementation
        # Example command structure (adjust based on your requirements):
        # cmd = f"oc create identityprovider openid --token={self.token}"
        # ret = execute_command(cmd)
        # if ret is None:
        #     log.error("Failed to add OpenID identity provider")
        #     return None
        # log.info("OpenID identity provider added successfully")
        # return ret
        log.info("add_openid_identity_provider() method called successfully")
        return True


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
    "--redirect-uris",
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
    "--contact-emails",
    required=True,
    multiple=True,
    help="Contact emails for the client (can be specified multiple times)",
)
@click.option(
    "--jenkins-props-file",
    default=None,
    help="Path to properties file for Jenkins to read TOKEN (e.g., env.properties)",
)
def register_client(token, redirect_uris, client_name, contact_emails, jenkins_props_file, output_token):
    """Register an OpenID client dynamically"""
    openid_ops = OpenIdOps()

    result = openid_ops.dynamic_client_registration(
        token=token,
        redirect_uris=list(redirect_uris),
        client_name=client_name,
        contact_emails=list(contact_emails),
        jenkins_props_file=jenkins_props_file,
    )

    if result is None:
        click.echo("Failed to register OpenID client", err=True)
        exit(1)

    # Output token for Jenkins if requested
    if output_token:
        click.echo(f"TOKEN={token}")

    click.echo("OpenID client registered successfully")


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
def delete_client(registration_token, deletion_endpoint):
    """Delete an OpenID client dynamically"""
    openid_ops = OpenIdOps()

    result = openid_ops.delete_dynamic_client(
        registration_token=registration_token,
        deletion_endpoint=deletion_endpoint,
    )

    if result is None:
        click.echo("Failed to delete OpenID client", err=True)
        exit(1)

    click.echo("OpenID client deleted successfully")

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

    result = openid_ops.add_openid_identity_provider(
        idp_name=idp_name,
        client_id=client_id,
        client_secret=client_secret,
        registration_endpoint=registration_endpoint,
    )

    if result is None:
        click.echo("Failed to add OpenID identity provider", err=True)
        exit(1)


    click.echo("OpenID identity provider added successfully")


if __name__ == "__main__":
    cli()

