TF_DIR = terraform
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
APPS_DIR = kubernetes/apps

export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all down apps clean-pvc help

# Добавь эту переменную в начало файла, чтобы kubectl точно знал, куда смотреть
KUBECONFIG_PATH = $(HOME)/.kube/config

all: ## 1. Инфра, 2. Кубер, 3. Аппсы
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
	@# Ждем, пока API вообще начнет отвечать
	@until KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes > /dev/null 2>&1; do sleep 2; echo "Waiting for API..."; done
	@# Ждем, пока все ноды перейдут в статус Ready
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl wait --for=condition=Ready nodes --all --timeout=300s
	
	@echo "--- Cluster is READY! Deploying applications ---"
	@# Вызываем apps напрямую через переменную окружения для надежности
	KUBECONFIG=$(KUBECONFIG_PATH) $(MAKE) apps
	
	@echo "--- All systems GO! ---"
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A

down: ## 1. Удалить ВМ, 2. Почистить мусор
	cd $(TF_DIR) && terraform destroy -auto-approve
	rm -f ./join_command.txt
	@# Опционально: чистим локальный конфиг, чтобы не было конфликтов
	rm -f $(KUBECONFIG_PATH)
	@echo "--- Infrastructure DESTROYED and Cleaned ---"

apps: ## Только деплой приложений (Speedtest, Jellyfin, Nextcloud)
	@echo "Applying Kubernetes manifests from $(APPS_DIR)..."
	kubectl apply -f $(APPS_DIR)/
	kubectl get pods -o wide

clean-pvc: ## Очистить "хвосты" на TrueNAS (если удаляешь кластер)
	ssh km@192.168.1.30 "sudo zfs destroy -r NVME/k8s-vols/data && sudo zfs create NVME/k8s-vols/data"

help: ## Показать список команд
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

tf-apply: ## 1. Только поднять виртуалки (Terraform)
	@echo "--- Starting Terraform Apply ---"
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve

tf-destroy: ## 1. Только удалить виртуалки (Terraform)
	@echo "--- Starting Terraform Destroy ---"
	cd $(TF_DIR) && terraform destroy -auto-approve

k8s-config: ## 2. Скопировать конфиг кубера себе на хост
	@echo "--- Fetching kubeconfig from Master ---"
	mkdir -p $(HOME)/.kube
	scp km@192.168.1.100:/etc/kubernetes/admin.conf $(KUBECONFIG_PATH)
	sudo chown $(shell id -u):$(shell id -g) $(KUBECONFIG_PATH)
