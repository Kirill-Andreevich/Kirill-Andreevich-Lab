TF_DIR = terraform
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
APPS_DIR = kubernetes/apps
KUBECONFIG_PATH = $(HOME)/.kube/config

export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all down apps clean-pvc help

all: ## 1. Инфра, 2. Кубер, 3. Хранилище, 4. Аппсы
	@echo "--- Starting Terraform ---"
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve
	
	@echo "--- Waiting for SSH (30s) ---"
	sleep 30
	
	@echo "--- Running Ansible Playbooks ---"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/01_prepare.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_install_k8s.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_init_master.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_join_workers.yml
	
	@echo "--- Deploying Network (Flannel) ---"
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
	
	@echo "--- Waiting for Kubernetes API and Nodes to be Ready ---"
	@until KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes > /dev/null 2>&1; do sleep 2; echo "Waiting for API..."; done
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl wait --for=condition=Ready nodes --all --timeout=300s

	@echo "--- Deploying MetalLB ---"
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
	@sleep 20
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f kubernetes/main/metallb-config.yaml

	@echo "--- Deploying Democratic CSI (TrueNAS Storage) ---"
	KUBECONFIG=$(KUBECONFIG_PATH) helm upgrade --install truenas-iscsi ./democratic-csi \
		--namespace democratic-csi \
		--create-namespace \
		-f zfs-iscsi-base.yaml \
		-f zfs-iscsi-prod.yaml \
		-f zfs-iscsi-secrets.yaml
	
	@echo "--- Waiting for Storage Provisioner to be Ready ---"
	@sleep 15
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl wait --for=condition=Ready pods --all -n democratic-csi --timeout=300s
	
	@echo "--- Cluster is READY! Deploying applications ---"
	KUBECONFIG=$(KUBECONFIG_PATH) $(MAKE) apps
	
	@echo "--- All systems GO! ---"
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get svc -o wide
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A

down: ## 1. Удалить ресурсы K8s (освободить TrueNAS), 2. Удалить ВМ
	@echo "--- Gracefully removing K8s apps and PVCs to release TrueNAS locks ---"
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete -f $(APPS_DIR)/ --timeout=60s
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pvc --all -A --timeout=60s
	@echo "--- Waiting for Democratic CSI to clean up TrueNAS (20s) ---"
	@sleep 20
	
	@echo "--- Starting Terraform Destroy ---"
	cd $(TF_DIR) && terraform destroy -auto-approve
	
	@echo "--- Cleaning local files ---"
	rm -f ./join_command.txt
	rm -f $(KUBECONFIG_PATH)
	@echo "--- Infrastructure DESTROYED and Cleaned ---"

apps: ## Только деплой приложений
	@echo "Applying Kubernetes manifests from $(APPS_DIR)..."
	kubectl apply -f $(APPS_DIR)/

clean-pvc: ## Очистить хвосты на TrueNAS (ручной режим)
	ssh km@192.168.1.30 "sudo zfs destroy -r NVME/k8s-vols/data && sudo zfs create NVME/k8s-vols/data"

help: ## Показать список команд
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
