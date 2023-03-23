# Define required providers
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.35.0"
    }
  }
}

# Configure the OpenStack Provider
provider "openstack" {
  cloud = var.cloud_name
}

resource "openstack_compute_instance_v2" "vm" {
  name                    = var.vm_name
  image_name              = var.image_name
  flavor_name             = var.flavor_name
  key_pair                = var.key_pair
  security_groups         = ["default"]

  network {
    name = var.network_name
  }
}

resource "null_resource" "copy_execute" {
  
    connection {
    type = "ssh"
    host = openstack_compute_instance_v2.vm.access_ip_v4
    user = var.vm_user
    private_key = file(var.vm_private_key)
    }

 
  provisioner "file" {
    source      = "requirements.sh"
    destination = "/tmp/requirements.sh"
  }
  
   provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /tmp/requirements.sh",
      "sh /tmp/requirements.sh",
    ]
  }
  
  depends_on = [ openstack_compute_instance_v2.vm ]
  
  }
output "ip_address" {
  value = openstack_compute_instance_v2.vm.access_ip_v4
}
