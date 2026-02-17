resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/generated_hosts.ini"
  content  = <<EOF
[k8s_master]
k8s-master ansible_host=${[for ip in libvirt_domain.k8s_master.network_interface.0.addresses : ip if can(regex("^192", ip))][0]}

[k8s_workers]
%{ for vm in libvirt_domain.k8s_worker ~}
${vm.name} ansible_host=${ join("", [for ip in vm.network_interface.0.addresses : ip if can(regex("^192", ip))]) }
%{ endfor ~}

[gitlab]
gitlab-srv ansible_host=${[for ip in libvirt_domain.gitlab.network_interface.0.addresses : ip if can(regex("^192", ip))][0]}

[all:vars]
ansible_user=km
ansible_ssh_private_key_file=/home/km/.ssh/id_ed25519
EOF
}
