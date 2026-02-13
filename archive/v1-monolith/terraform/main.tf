terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu+ssh://km@192.168.1.22/system?keyfile=/home/km/.ssh/id_ed25519"
}

# 1. ПУЛ ХРАНИЛИЩА
resource "libvirt_pool" "storage_pool" {
  name = "terraform_pool_v2"
  type = "dir"
  path = "/var/lib/libvirt/images/terraform_pool_v2"
}

# 2. СЕТЬ (NAT 192.168.7.x)
resource "libvirt_network" "lab_network" {
  name      = "lab_network"
  mode      = "nat"
  domain    = "lab.local"
  addresses = ["192.168.7.0/24"]
  dhcp {
    enabled = true
  }
}

# 3. БАЗОВЫЙ ОБРАЗ
resource "libvirt_volume" "common_base" {
  name   = "ubuntu-24-base.qcow2"
  pool   = libvirt_pool.storage_pool.name
  source = "/home/km/homelab/terraform/noble-base.qcow2"
  format = "qcow2"
}

# 4. 10 ДИСКОВ
resource "libvirt_volume" "os_disk" {
  count          = 10
  name           = "test_vm_disk_${count.index}.qcow2"
  pool           = libvirt_pool.storage_pool.name
  base_volume_id = libvirt_volume.common_base.id
  size           = 21474836480 
}

# 5. 10 МАШИН
resource "libvirt_domain" "my_first_vm" {
  count  = 10
  name   = "terraform-test-vm-${count.index}"
  memory = "512"
  vcpu   = 1

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id
  
  disk {
    volume_id = libvirt_volume.os_disk[count.index].id
  }

  network_interface {
    network_id     = libvirt_network.lab_network.id
    wait_for_lease = true # Ждем получения IP, чтобы он попал в конфиги
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }
}

# ГЕНЕРАЦИЯ ИНВЕНТАРЯ ДЛЯ ANSIBLE
resource "local_file" "ansible_inventory" {
  filename = "./../ansible/generated/hosts.ini"
  content  = <<EOT
[all:vars]
ansible_user=km

[compute]
manjaro
endeavour
truenas

[nodes]
%{ for vm in libvirt_domain.my_first_vm ~}
${vm.network_interface.0.addresses.0}
%{ endfor ~}

[all:children]
compute
nodes
EOT
}

# ГЕНЕРАЦИЯ ТАРГЕТОВ ДЛЯ PROMETHEUS (File SD)
