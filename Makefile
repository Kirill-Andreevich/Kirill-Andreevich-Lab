TF_DIR = terraform
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini

export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all down clean

all: ## Поднять всё одной кнопкой
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve
	@echo "Waiting for SSH..."
	sleep 30
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/01_prepare.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_install_k8s.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_init_master.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_join_workers.yml
	kubectl apply -f https://github.com
	@echo "Cluster is READY!"
	kubectl get nodes

down: ## Удалить всё
	cd $(TF_DIR) && terraform destroy -auto-approve
	rm -f ./join_command.txt
