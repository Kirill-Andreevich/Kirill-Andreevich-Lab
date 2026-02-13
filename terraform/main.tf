terraform {
  required_providers {
    libvirt = { 
      source  = "dmacvicar/libvirt"
      version = "0.7.1" 
    }
    local = { 
      source = "hashicorp/local" 
    }
  }
}

locals {
  compute_vms = var.vm_map
}

resource "libvirt_cloudinit_disk" "commoninit" {
  provider  = libvirt.compute
  name      = "commoninit.iso"
  user_data = <<EOT
#cloud-config
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh-authorized-keys:
      - ${file("/home/km/.ssh/id_ed25519.pub")}
EOT
}

resource "libvirt_volume" "base_image" {
  provider = libvirt.compute
  name     = "ubuntu-24.04-base.qcow2"
  pool     = "default"
  source   = var.base_image_url
  format   = "qcow2"
}

resource "libvirt_volume" "os_disk_compute" {
  for_each       = local.compute_vms
  provider       = libvirt.compute
  name           = "${each.key}-os.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base_image.id 
  format         = "qcow2"
}

resource "libvirt_domain" "vm_compute" {
  for_each = local.compute_vms
  provider = libvirt.compute
  name     = each.key
  vcpu     = each.value.cpu
  memory   = each.value.ram
  
  cloudinit = libvirt_cloudinit_disk.commoninit.id

  cpu { mode = "host-passthrough" }
  
  disk { volume_id = libvirt_volume.os_disk_compute[each.key].id }
  
  # Пробуем максимально простой проброс сети
  network_interface {
    # Это аналог твоего XML <interface type='bridge'> с прямой привязкой
    macvtap = "enp12s0"
    wait_for_lease = true
  }
  
  console {
    type        = "pty"
    target_port = "0"
  }
}

resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/generated_hosts.ini"
  content  = <<EOT
[compute_vms]
%{ for name, vm in libvirt_domain.vm_compute ~}
${name} ansible_host=${vm.network_interface.0.addresses.0}
%{ endfor ~}

[all:vars]
ansible_user=km
ansible_ssh_private_key_file=/home/km/.ssh/id_ed25519
EOT
}
