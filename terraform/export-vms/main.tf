# Скачиваем базовый образ Ubuntu 24.04 специально для сборок
resource "libvirt_volume" "base_ubuntu_24_export" {
  provider = libvirt.compute
  name     = "ubuntu-24.04-export-base.qcow2"
  pool     = "default"
  source   = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format   = "qcow2"
}

# Создаем "жирный" диск на 120GB
resource "libvirt_volume" "zabbix_disk" {
  provider       = libvirt.compute
  name           = "zabbix-export.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.base_ubuntu_24_export.id
  size           = 120 * 1024 * 1024 * 1024 # 120GB
}

resource "libvirt_cloudinit_disk" "init_zabbix" {
  provider  = libvirt.compute
  name      = "init-zabbix-export.iso"
  user_data = file("${path.module}/cloud_init_zabbix.cfg")
}

# Конфигурация самой ВМ (12 ядер, 24 ГБ ОЗУ)
resource "libvirt_domain" "zabbix_export_vm" {
  provider = libvirt.compute
  name     = "zabbix-for-proxmox"
  vcpu     = 12
  memory   = 24576 # 24GB RAM

  cpu { mode = "host-passthrough" }

  disk { volume_id = libvirt_volume.zabbix_disk.id }
  
  cloudinit = libvirt_cloudinit_disk.init_zabbix.id

  network_interface {
    bridge = "br0"
    # IP выдаст DHCP, для сборки и скачивания зависимостей этого достаточно
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  qemu_agent = true
}
