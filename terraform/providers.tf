terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
  }
}

# Пульт управления для Storage-Node (TrueNAS 9700X)
provider "libvirt" {
  alias = "storage"
  uri   = "qemu+ssh://root@192.168.1.176/system"
}

# Пульт управления для Compute-Node (EndeavourOS 9950X3D)
provider "libvirt" {
  alias = "compute"
  uri   = "qemu+ssh://root@192.168.1.22/system"
}

# Пульт управления для самого себя (Workstation 9800X3D)
provider "libvirt" {
  alias = "workstation"
  uri   = "qemu:///system" # Тут SSH не нужен, работаем локально
}
