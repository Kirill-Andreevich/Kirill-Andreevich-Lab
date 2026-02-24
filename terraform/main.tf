# --- БАЗОВЫЕ ОБРАЗЫ ---
resource "libvirt_volume" "base_compute" {
  provider = libvirt.compute
  name     = "ubuntu-24.04-base.qcow2"
  pool     = "default"
  source   = var.base_image_url
  format   = "qcow2"
}

resource "libvirt_volume" "base_workstation" {
  provider = libvirt.workstation
  name     = "ubuntu-24.04-base.qcow2"
  pool     = "default"
  source   = var.base_image_url
  format   = "qcow2"
}

# --- ОБЩИЙ CLOUD-INIT ---
locals {
  common_cloudinit = <<EOT
#cloud-config
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("~/.ssh/id_ed25519.pub")}
packages:
  - qemu-guest-agent
  - open-iscsi
  - nfs-common
runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent ]
  - [ systemctl, enable, --now, iscsid ]
  - mkdir -p /run/flannel
  - |
    cat <<FLN > /run/flannel/subnet.env
    FLANNEL_NETWORK=10.244.0.0/16
    FLANNEL_SUBNET=10.244.1.1/24
    FLANNEL_MTU=1450
    FLANNEL_IPMASQ=true
    FLN
EOT
}

# --- MASTER ---
resource "libvirt_volume" "master_disk" {
  provider       = libvirt.workstation
  name           = "k8s-master.qcow2"
  base_volume_id = libvirt_volume.base_workstation.id
  pool           = "default"
  size           = 42949672960
}

resource "libvirt_cloudinit_disk" "init_master" {
  provider  = libvirt.workstation
  name      = "init-master.iso"
  pool      = "default"
  user_data = local.common_cloudinit

  network_config = <<EOT
version: 2
ethernets:
  id0:
    match:
      name: en*
    dhcp4: false
    addresses:
      - ${var.ips.master}/24
    routes:
      - to: default
        via: 192.168.1.1
    nameservers:
      addresses: [192.168.1.1, 8.8.8.8]
EOT
}

resource "libvirt_domain" "k8s_master" {
  provider   = libvirt.workstation
  name       = "k8s-master"
  vcpu       = 4
  memory     = 8192
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_master.id
  cpu { mode = "host-passthrough" }
  network_interface { 
    bridge    = "br0"
    addresses = [var.ips.master]
  }
  disk { volume_id = libvirt_volume.master_disk.id }

  lifecycle {
    replace_triggered_by = [libvirt_cloudinit_disk.init_master]
  }
}

# --- WORKERS ---
resource "libvirt_volume" "worker_disk" {
  count          = var.worker_count
  provider       = libvirt.compute
  name           = "k8s-worker-${count.index}.qcow2"
  base_volume_id = libvirt_volume.base_compute.id
  pool           = "default"
  size           = 42949672960
}

resource "libvirt_cloudinit_disk" "init_worker" {
  count     = var.worker_count
  provider  = libvirt.compute
  name      = "init-worker-${count.index}.iso"
  pool      = "default"
  user_data = local.common_cloudinit

  network_config = <<EOT
version: 2
ethernets:
  id0:
    match:
      name: en*
    dhcp4: false
    addresses:
      - 192.168.1.${var.ips.worker_start_ip + count.index}/24
    routes:
      - to: default
        via: 192.168.1.1
    nameservers:
      addresses: [192.168.1.1, 8.8.8.8]
EOT
}

resource "libvirt_domain" "k8s_worker" {
  count      = var.worker_count
  provider   = libvirt.compute
  name       = "k8s-worker-${count.index}"
  vcpu       = 6
  memory     = 12288
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_worker[count.index].id
  cpu { mode = "host-passthrough" }
  network_interface { 
    bridge    = "br0"
    addresses = ["192.168.1.${var.ips.worker_start_ip + count.index}"]
  }
  disk { volume_id = libvirt_volume.worker_disk[count.index].id }

  lifecycle {
    replace_triggered_by = [libvirt_cloudinit_disk.init_worker[count.index]]
  }
}

# --- GITLAB ---
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
  user_data = local.common_cloudinit

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
    replace_triggered_by = [libvirt_cloudinit_disk.init_gitlab]
  }
}
