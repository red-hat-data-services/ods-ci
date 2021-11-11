import string
import escapism


def get_safe_username(username):
    # Calculates safe usernames using JupyterHub algorithm (e.g. ldap-user1 > ldap-2duser1)
    # Kubespawner example:
    #  https://github.com/jupyterhub/kubespawner/blob/251a0b65ffaff72e722446d5b9aac738ad6923d1/kubespawner/spawner.py#L1709
    safe_chars = set(string.ascii_lowercase + string.digits)
    return escapism.escape(username, safe=safe_chars, escape_char='-').lower()
