# Узел Compute (9950X3D)
provider "libvirt" {
  alias = "compute"
  uri   = "qemu+ssh://km@${var.host_ips["compute"]}/system?sshauth=privkey&keyfile=/home/km/.ssh/id_ed25519"
}

# Узел Workstation (9800X3D)
provider "libvirt" {
  alias = "workstation"
  uri   = "qemu+ssh://km@${var.host_ips["workstation"]}/system?sshauth=privkey&keyfile=/home/km/.ssh/id_ed25519"
}
