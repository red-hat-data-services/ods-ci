
"""
Example of usage
1. Register a new dynamic client
#python3 ods_ci/utils/scripts/openshift/openid.py register-client --token <IAT> --registration-endpoint https://myAuthServer.com/registrationEndpoint --redirect-uri <redirect-uri1> --redirect-uri <redirect-uri2> --client-name <client-name> --contact-email <contact-email1> --contact-email <contact-email2> --jenkins-props-file <jenkins-props-file>

2. Delete a dynamic client
#python3 ods_ci/utils/scripts/openshift/openid.py delete-client --registration-token <client-registration-token> --deletion-endpoint https://myAuthServer.com/deletionEndpoint --client-name <client-name>

3. Add OpenID identity provider (it assumes you are already logged in to the cluster)
#python3 ods_ci/utils/scripts/openshift/openid.py add-openid-idp --idp-name openid --client-id <id> --client-secret <secret> --issuer-url https://myAuthServer.com --ocp-secret-name openid-secret

4. Delete OpenID identity provider (it assumes you are already logged in to the cluster)
#python3 ods_ci/utils/scripts/openshift/openid.py delete-openid-idp --idp-name openid

5. Update OpenID identity provider (it assumes you are already logged in to the cluster)
#python3 ods_ci/utils/scripts/openshift/openid.py update-openid-idp --idp-name openid --client-id <id> --client-secret <secret> --issuer-url https://myAuthServer.com --ocp-secret-name openid-secret

6. Update redirect URIs for a dynamic client
#python3 ods_ci/utils/scripts/openshift/openid.py update-redirect-uris --operation <add/remove> --registration-token <client-registration-token> --update-endpoint https://myAuthServer.com/updateEndpoint --client-name <client-name> --redirect-uri <redirect-uri1> --redirect-uri <redirect-uri2> --jenkins-props-file <jenkins-props-file>
"""

from typing import Literal
import click
import base64
from ods_ci.utils.scripts.logger import log
import json
import requests
from string import Template
from ods_ci.utils.scripts.util import execute_command
import os

REGISTRATION_BODY_TEMPLATE = Template("""
    {
        "application_type": "web",
        "redirect_uris": [
           ${redirect_uris}
        ],
        "client_name": "${client_name}",
        "contacts": [
            ${contact_emails}
        ]
    }
""")

OCP_DEFAULT_SECRET_NAME = "openid-idp-client-secret"
CLIENT_PROPERTIES_FILE_DEFAULT = "client.properties"

class OpenIdOps:
    """Class for OpenID identity provider operations"""

    def __init__(self):
        """Initialize OpenIdOps"""
        self.token = ""
        self.jenkins_props_file = CLIENT_PROPERTIES_FILE_DEFAULT
        self.client_registration_token = ""
        self.idp_name = ""
        self.client_id = ""
        self.client_name = ""
        self.client_secret = ""
        self.registration_endpoint = ""
        self.ocp_secret_name = OCP_DEFAULT_SECRET_NAME

    def _write_jenkins_properties(self):
        """Write client details to a properties file for Jenkins to read"""
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
    
    def _apply_openid_identity_provider(self):
        """Patches OAuth CR with the new identity provider"""
        template_path = os.path.abspath(os.path.dirname(__file__)) + "/../../../configs/templates/openid.json"
        with open(template_path, "r") as f:
            openid_template = Template(f.read())
        openid_json = openid_template.substitute(
            idp_name=self.idp_name,
            client_id=self.client_id,
            client_secret_name=self.ocp_secret_name,
            issuer_url=self.issuer_url,
        )
        patch_value = json.loads(openid_json)
        patch_array = [
            {
                "op": "add",
                "path": "/spec/identityProviders/-",
                "value": patch_value
            }
        ]
        patch_json = json.dumps(patch_array)
        cmd = f"oc patch oauth cluster --type json -p '{patch_json}'"
        return_rc, _ = execute_command(
            cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to apply OpenID identity provider: {return_rc}")
            return 1
        log.info(f"OpenID identity provider applied successfully: {return_rc}")
        return

    def register_dynamic_client(self, registration_endpoint: str, token: str, redirect_uris: list[str], client_name: str, contact_emails: list[str], jenkins_props_file: str):
        """Registers a new dynamic OpenIDclient"""
        self.token = token
        self.jenkins_props_file = jenkins_props_file
        self.registration_endpoint = registration_endpoint
        redirect_uris = ", ".join([f'"{uri}"' for uri in redirect_uris])
        contact_emails = ", ".join([f'"{email}"' for email in contact_emails])
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
    
    def update_redirect_uris(self, operation: Literal["add", "remove"], registration_token: str, update_endpoint: str, client_name: str, redirect_uris: list[str], jenkins_props_file: str):
        """Updates (add/remove) redirect URIs on a existing dynamic OpenID client"""
        self.jenkins_props_file = jenkins_props_file
        headers = {
            "Authorization": f"Bearer {registration_token}",
        }
        request = requests.get(f"{update_endpoint}", headers=headers)
        if request.status_code != 200:
            log.error(f"Failed to GET current client info for {client_name}: {request.status_code} {request.text}")
            return 1
        current_client_info = request.json()
        current_uris = current_client_info["redirect_uris"]
        if client_name != current_client_info["client_name"]:
            log.error(f"Client name mismatch: {client_name} is not expected for the given client ID.")
            return 1
        if operation == "add":
            updated_uris = list(set(current_uris) | set(redirect_uris))
        elif operation == "remove":
            updated_uris = list(set(current_uris) - set(redirect_uris))
        else:
            log.error(f"Invalid operation: {operation}")
            return 1
        if len(set(updated_uris)) == len(set(current_uris)):
            log.info(f"No changes in redirect URIs to apply. Skip the update")
            self.client_name = current_client_info["client_name"]
            self.client_id = current_client_info["client_id"]
            self.client_secret = current_client_info["client_secret"]
            self.client_registration_token = current_client_info["registration_access_token"]
            self._write_jenkins_properties()
            return
        updated_client_info = current_client_info
        updated_client_info["redirect_uris"] = updated_uris
        update_request = requests.put(f"{update_endpoint}", headers=headers, json=updated_client_info)
        if update_request.status_code != 200:
            log.error(f"Failed to {operation} redirect URIs to client {client_name}: {update_request.status_code} {update_request.text}")
            return 1
        log.info(f"{operation.capitalize()} Redirect URIs perfomed successfully on client {client_name}: {update_request.status_code}")
        updated_client_info = update_request.json()
        self.client_name = updated_client_info["client_name"]
        self.client_id = updated_client_info["client_id"]
        self.client_secret = updated_client_info["client_secret"]
        self.client_registration_token = updated_client_info["registration_access_token"]
        self._write_jenkins_properties()
        return


    def delete_dynamic_client(self, registration_token: str, deletion_endpoint: str, client_name: str):
        """Deletes a dynamic OpenID client"""
        headers = {
            "Authorization": f"Bearer {registration_token}",
        }
        request = requests.delete(f"{deletion_endpoint}", headers=headers)
        if request.status_code != 204:
            log.error(f"Failed to delete client {client_name}: {request.status_code} {request.text}")
            return 1
        log.info(f"Client {client_name} deleted successfully: {request.status_code}")
        return

    def add_openid_identity_provider(self, idp_name: str, client_id: str, client_secret: str, issuer_url: str, ocp_secret_name: str):
        """Configure the OpenID identity provider in the cluster"""
        log.info("Adding OpenID identity provider...")
        self.idp_name = idp_name
        self.client_id = client_id
        self.client_secret = client_secret
        self.issuer_url = issuer_url
        if ocp_secret_name:
            self.ocp_secret_name = ocp_secret_name
        cmd=f"oc create secret generic {ocp_secret_name} --from-literal=clientSecret={client_secret} -n openshift-config"
        return_rc, _ = execute_command(
            cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to create client secret: {return_rc}")
            return 1

        self._apply_openid_identity_provider()
        return

    def update_openid_identity_provider(self, idp_name: str, client_id: str, client_secret: str, issuer_url: str, ocp_secret_name: str):
        """Updates the OpenID identity provider in the cluster, e.g., update the secret if the value has changed"""
        log.info("Updating OpenID identity provider...")
        self.idp_name = idp_name
        self.client_id = client_id
        self.client_secret = client_secret
        self.issuer_url = issuer_url
        if ocp_secret_name:
            self.ocp_secret_name = ocp_secret_name
        client_secret_encoded = base64.b64encode(client_secret.encode("ascii")).decode('ascii')
        secret_data = f"""{{
            "data": {{
                "client-secret": "{client_secret_encoded}"
            }}
        }}"""
        cmd = f"""oc patch secret {ocp_secret_name} -p '{secret_data}' -n openshift-config"""
        return_rc, _ = execute_command(
            cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to update client secret: {return_rc}")
            return 1
        self._apply_openid_identity_provider()
        log.info(f"OpenID identity provider updated successfully: {return_rc}")
        return
    
    def remove_openid_identity_provider(self, idp_name: str, ocp_secret_name: str):
        """Removes OpenID identity provider from the cluster"""
        log.info("Removing OpenID identity provider...")
        log.info(">> Deleting OCP secret...")
        if not ocp_secret_name:
            ocp_secret_name_cmd = "oc get oauth cluster -ojsonpath='{{.spec.identityProviders[?(@.name==\"{}\")].openID.clientSecret.name}}'".format(idp_name)
            return_rc, ocp_secret_name = execute_command(
                ocp_secret_name_cmd,
                return_rc=True,
            )
            if return_rc != 0 or not ocp_secret_name:
                log.error(f"Failed to get OCP secret name or secret name is empty: {return_rc}")
                return 1
        ocp_secret_name = ocp_secret_name.strip()
        delete_secret_cmd = f"oc delete secret {ocp_secret_name} -n openshift-config --ignore-not-found"
        return_rc, _ = execute_command(
            delete_secret_cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to delete OCP secret: {return_rc}")
            return 1
        log.info(f"OCP secret deleted successfully: {return_rc}")
        log.info(">> Deleting OpenID identity provider...")
        idp_idx_cmd = f"oc get oauth cluster -o json | jq '.spec.identityProviders | map(.name == \"{idp_name}\") | index(true)'"
        return_rc, idp_idx = execute_command(
            idp_idx_cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to get OpenID identity provider index: {return_rc}")
            return 1
        if idp_idx == "null":
            log.error(f"OpenID identity provider {idp_name} not found")
            return 1
        idp_removal_array = [
            {"op": "remove","path": f"/spec/identityProviders/{idp_idx.strip()}"}
        ]
        idp_removal_json = json.dumps(idp_removal_array)
        cmd = f"oc patch oauth cluster --type json -p '{idp_removal_json}'"
        return_rc, _ = execute_command(
            cmd,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to delete OpenID identity provider: {return_rc}")
            return 1
        log.info(f">> {idp_name} openID identity provider deleted successfully: {return_rc}")
        log.info(">> Deleting user identities...")
        delete_identities = f"oc get identity -oname | grep 'identity.user.openshift.io/{idp_name}:' | xargs oc delete"
        return_rc, _ = execute_command(
            delete_identities,
            return_rc=True,
        )
        if return_rc != 0:
            log.error(f"Failed to delete user identities: {return_rc}")
            return 1
        log.info(f">> {idp_name} users identities deleted successfully: {return_rc}")
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
    required=False,
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
    default=CLIENT_PROPERTIES_FILE_DEFAULT,
    help="Path to properties file for Jenkins or other tools to read CLIENT_NAME, CLIENT_ID, CLIENT_SECRET, CLIENT_REGISTRATION_TOKEN (e.g., client.properties)",
)
def register_client(token, registration_endpoint, redirect_uri, client_name, contact_email, jenkins_props_file):
    """Register an OpenID client dynamically"""
    openid_ops = OpenIdOps()
    exit(openid_ops.register_dynamic_client(
        token=token,
        registration_endpoint=registration_endpoint,
        redirect_uris=list(redirect_uri),
        client_name=client_name,
        contact_emails=list(contact_email),
        jenkins_props_file=jenkins_props_file,
    ))

@cli.command("update-redirect-uris")
@click.option(
    "--operation",
    required=True,
    help="Operation to perform on the redirect URIs",
)
@click.option(
    "--registration-token",
    required=True,
    help="Registration token required for updating redirect URIs",
)
@click.option(
    "--update-endpoint",
    required=True,
    help="Update endpoint required for updating redirect URIs",
)
@click.option(
    "--client-name",
    required=True,
    help="Name of the client to update redirect URIs",
)
@click.option(
    "--redirect-uri",
    required=True,
    multiple=True,
    help="Redirect URIs to update (can be specified multiple times)",
)
@click.option(
    "--jenkins-props-file",
    default=CLIENT_PROPERTIES_FILE_DEFAULT,
    help="Path to properties file for Jenkins or other tools to read CLIENT_NAME, CLIENT_ID, CLIENT_SECRET, CLIENT_REGISTRATION_TOKEN (e.g., client.properties)",
)
def update_redirect_uris(operation, registration_token, update_endpoint, client_name, redirect_uri, jenkins_props_file):
    """Update redirect URIs for an OpenID client"""
    openid_ops = OpenIdOps()
    exit(openid_ops.update_redirect_uris(
        operation=operation,
        registration_token=registration_token,
        update_endpoint=update_endpoint,
        client_name=client_name,
        redirect_uris=list(redirect_uri),
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
@click.option(
    "--ocp-secret-name",
    default=OCP_DEFAULT_SECRET_NAME,
    required=False,
    help="OpenShift secret name required for adding OpenID identity provider",
)
def add_openid_idp(idp_name: str, client_id: str, client_secret: str, issuer_url: str, ocp_secret_name: str):
    """Add OpenID identity provider to the cluster"""
    openid_ops = OpenIdOps()

    exit(openid_ops.add_openid_identity_provider(
        idp_name=idp_name,
        client_id=client_id,
        client_secret=client_secret,
        issuer_url=issuer_url,
        ocp_secret_name=ocp_secret_name,
    ))

@cli.command("delete-openid-idp")
@click.option(
    "--idp-name",
    required=True,
    help="Name of the OpenID identity provider to delete",
)
@click.option(
    "--ocp-secret-name",
    required=False,
    help="OpenShift secret name required for deleting OpenID identity provider",
)
def delete_openid_idp(idp_name: str, ocp_secret_name: str):
    """Delete OpenID identity provider from the cluster"""
    openid_ops = OpenIdOps()
    exit(openid_ops.remove_openid_identity_provider(idp_name=idp_name, ocp_secret_name=ocp_secret_name))

if __name__ == "__main__":
    cli()
