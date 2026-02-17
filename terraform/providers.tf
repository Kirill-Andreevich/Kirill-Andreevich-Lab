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

# Хост 9950X (Compute)
provider "libvirt" {
  alias = "compute"
  uri   = "qemu+ssh://km@192.168.1.22/system?sshauth=privkey&keyfile=/home/km/.ssh/id_ed25519&known_hosts_verify=ignore"
}

# Хост 9800X (Workstation)
provider "libvirt" {
  alias = "workstation"
  uri   = "qemu+ssh://km@192.168.1.234/system?sshauth=privkey&keyfile=/home/km/.ssh/id_ed25519&known_hosts_verify=ignore"
}
