locals {
}


resource "vsphere_virtual_machine" "vm-lb" {
  
  name             = "loadbalancer"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = vsphere_folder.folder.path
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    name             = "disk0.vmdk"
    size             = data.vsphere_virtual_machine.template.disks[0].size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks[0].eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks[0].thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = "loadbalancer"
        domain    = "howest.local"
      }
      network_interface {
      }
    }
  }
  provisioner "file" {
    connection {
    type     = "ssh"
    user     = var.user
    password = var.password
    host     = local.ipPub
    port     = [for ip in local.ips : tostring(ip.port) if ip.ip == self.guest_ip_addresses[0]][0]
    agent    = "false"
    }
      content      = templatefile("nginx.tmpl", {ips=vsphere_virtual_machine.vm[*].default_ip_address})
      destination = "/home/student/load-balancer.conf"
  }
  provisioner "remote-exec" {
    connection {
    type     = "ssh"
    user     = var.user
    password = var.password
    host     = local.ipPub
    port     = [for ip in local.ips : tostring(ip.port) if ip.ip == self.guest_ip_addresses[0]][0]
    agent    = "false"
    }
    inline = [
      "echo ${var.password} | sudo -S apt install nginx -y",
      "echo ${var.password} | sudo -S cp /home/student/load-balancer.conf /etc/nginx/conf.d/load-balancer.conf",
      "echo ${var.password} | sudo -S rm /etc/nginx/sites-enabled/default",
      "echo ${var.password} | sudo -S systemctl restart nginx"
    ]
  }
   
  
 
 
}