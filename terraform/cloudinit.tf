resource "libvirt_cloudinit_disk" "commoninit" {
  count = 10
  name  = "commoninit-${count.index}.iso"
  pool  = libvirt_pool.storage_pool.name
  
  user_data = <<EOT
#cloud-config
hostname: terraform-test-vm-${count.index}
manage_etc_hosts: true 
users:
  - name: km
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - ${file("~/.ssh/id_ed25519.pub")}

# Устанавливаем и запускаем SSH сразу
packages:
  - openssh-server
  - qemu-guest-agent

runcmd:
  - systemctl enable --now ssh
  - systemctl enable --now qemu-guest-agent
EOT
}
