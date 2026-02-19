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

# --- CLOUD-INIT ДЛЯ WORKSTATION ---
resource "libvirt_cloudinit_disk" "init_workstation" {
  provider  = libvirt.workstation
  name      = "init-work.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("/home/km/.ssh/id_ed25519.pub")}
packages:
  - qemu-guest-agent
runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent ]
EOF
}

# --- CLOUD-INIT ДЛЯ COMPUTE (уникальный для каждой ноды) ---
resource "libvirt_cloudinit_disk" "init_compute" {
  count     = var.worker_count
  provider  = libvirt.compute
  name      = "init-comp-${count.index}.iso"
  pool      = "default"
  user_data = <<EOF
#cloud-config
hostname: k8s-worker-${count.index}
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ${file("/home/km/.ssh/id_ed25519.pub")}
network:
  version: 2
  ethernets:
    enp1s0:
      dhcp4: true
packages:
  - qemu-guest-agent
  - open-iscsi
runcmd:
  - [ systemctl, enable, --now, qemu-guest-agent ]
  - [ systemctl, enable, --now, iscsid ]
  - iscsiadm -m discovery -t sendtargets -p ${var.truenas_ip}
  - iscsiadm -m node -T ${var.iscsi_iqn} -p ${var.truenas_ip} --login
EOF
}

# --- WORKSTATION (9800X): MASTER ---
resource "libvirt_volume" "master_disk" {
  provider       = libvirt.workstation
  name           = "k8s-master-os.qcow2"
  base_volume_id = libvirt_volume.base_workstation.id
  size           = 21474836480
}

resource "libvirt_domain" "k8s_master" {
  provider   = libvirt.workstation
  name       = "k8s-master"
  vcpu       = 4
  memory     = 8192
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_workstation.id
  cpu { mode = "host-passthrough" }
  disk { volume_id = libvirt_volume.master_disk.id }
  network_interface { 
    bridge = "br0"
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# --- WORKSTATION (9800X): GITLAB ---
resource "libvirt_volume" "gitlab_disk" {
  provider       = libvirt.workstation
  name           = "gitlab-os.qcow2"
  base_volume_id = libvirt_volume.base_workstation.id
  size           = 42949672960
}

resource "libvirt_domain" "gitlab" {
  provider   = libvirt.workstation
  name       = "gitlab-srv"
  vcpu       = 8
  memory     = 16384
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_workstation.id
  cpu { mode = "host-passthrough" }
  disk { volume_id = libvirt_volume.gitlab_disk.id }
  network_interface { 
    bridge = "br0"
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# --- COMPUTE (9950X): WORKERS ---
resource "libvirt_volume" "worker_disk" {
  count          = var.worker_count
  provider       = libvirt.compute
  name           = "worker-${count.index}-os.qcow2"
  base_volume_id = libvirt_volume.base_compute.id
  size           = 21474836480
}

resource "libvirt_domain" "k8s_worker" {
  count      = var.worker_count
  provider   = libvirt.compute
  name       = "k8s-worker-${count.index}"
  vcpu       = 6
  memory     = 12288
  qemu_agent = true
  cloudinit  = libvirt_cloudinit_disk.init_compute[count.index].id
  cpu { mode = "host-passthrough" }
  disk { volume_id = libvirt_volume.worker_disk[count.index].id }
  network_interface { 
    bridge = "br0"
    wait_for_lease = true
  }
  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

