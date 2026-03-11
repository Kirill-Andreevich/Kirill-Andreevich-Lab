resource "local_file" "ansible_inventory" {
  filename = "../ansible/inventory/generated_hosts.ini"
  content  = <<EOT
[k8s_master]
k8s-master ansible_host=k8s-master.lan

[k8s_workers]
%{for i in range(var.worker_count)~}
k8s-worker-${i} ansible_host=k8s-worker-${i}.lan
%{endfor~}

[gitlab]
gitlab-srv ansible_host=gitlab-srv.lan

[all:vars]
ansible_user=km
ansible_ssh_private_key_file=~/.ssh/id_ed25519
EOT
}
