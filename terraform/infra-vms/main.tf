# Слой "Apps" управляет только GitLab

resource "libvirt_volume" "base_workstation" {
  provider = libvirt.workstation
  name     = "ubuntu-24.04-apps-base.qcow2"
  pool     = "default"
  source   = var.base_image_url
}

resource "libvirt_volume" "gitlab_disk" {
  provider       = libvirt.workstation
  name           = "gitlab-srv.qcow2"
  base_volume_id = libvirt_volume.base_workstation.id
  pool           = "default"
  size           = 64424509440
}

resource "libvirt_cloudinit_disk" "init_gitlab" {
  provider  = libvirt.workstation
  name      = "init-gitlab.iso"
  pool      = "default"
  user_data = <<EOT
#cloud-config
hostname: gitlab-srv
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/id_ed25519.pub")}
EOT

  network_config = <<EOT
version: 2
ethernets:
  id0:
    match:
      name: en*
    dhcp4: false
    addresses:
      - ${var.ips.gitlab}/24
    routes:
      - to: default
        via: 192.168.1.1
    nameservers:
      addresses: [192.168.1.1, 8.8.8.8]
EOT
}

resource "libvirt_domain" "gitlab_srv" {
  provider   = libvirt.workstation
  name       = "gitlab-srv"
  vcpu       = 4
  memory     = 8192
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_gitlab.id
  cpu { mode = "host-passthrough" }
  network_interface { 
    bridge    = "br0"
    addresses = [var.ips.gitlab]
  }
  disk { volume_id = libvirt_volume.gitlab_disk.id }

  lifecycle {
    prevent_destroy = true
    # Игнорируем изменения самого атрибута cloudinit, а не внешнего ресурса
    ignore_changes  = [ cloudinit ]
  }
}
