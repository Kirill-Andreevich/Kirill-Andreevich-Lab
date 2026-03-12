# Слой "Apps" управляет только GitLab

locals {
  common_cloudinit = <<EOT
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/id_ed25519.pub")}
packages:
  - qemu-guest-agent
runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent ]
EOT
}

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

  meta_data = <<EOT
instance-id: gitlab-srv
local-hostname: gitlab-srv
EOT

  user_data = <<EOT
#cloud-config
${local.common_cloudinit}
EOT

  network_config = <<EOT
version: 2
ethernets:
  id0:
    match:
      name: en*
    dhcp4: true
    dhcp-identifier: mac
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
    bridge = "br0"
    mac    = "52:54:00:11:22:33"
  }
  disk { volume_id = libvirt_volume.gitlab_disk.id }

  lifecycle {
    prevent_destroy      = true
    ignore_changes       = [ cloudinit ]
  }
}
