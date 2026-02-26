# --- ПЕРЕМЕННЫЕ ПУТЕЙ ---
TF_DIR = terraform
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
APPS_DIR = kubernetes/apps
KUBECONFIG_PATH = $(HOME)/.kube/config

# Пути к плейбукам безопасности и бэкапа
ANSIBLE_SECRETS = $(ANSIBLE_DIR)/00_generate_secrets.yml
ANSIBLE_BACKUP = $(ANSIBLE_DIR)/99_s3_backup.yml

# Переменные окружения для Restic (чтобы не вводить экспорт вручную)
R_ENV = source ./.restic_env

export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all down apps clean-pvc help backup generate-secrets backup-list backup-ls backup-check vm-status vm-start vm-stop

# --- ОСНОВНОЙ ЦИКЛ ---

all: ## 1. Инфра, 2. Секреты, 3. Кубер, 4. Хранилище, 5. Аппсы
	@echo "--- Starting Terraform ---"
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve

	@echo "--- Generating Secrets from Vault ---"
	ansible-playbook $(ANSIBLE_SECRETS) --ask-vault-pass

	@echo "--- Waiting for SSH (30s) ---"
	sleep 30

	@echo "--- Running Ansible Playbooks ---"
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/01_prepare.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_install_k8s.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_init_master.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_join_workers.yml

	@echo "--- Deploying Network (Flannel) ---"
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

	@echo "--- Waiting for Kubernetes API ---"
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

	@echo "--- Cleaning up temporary secrets ---"
	rm -f zfs-iscsi-secrets.yaml

	@echo "--- Cluster is READY! Deploying applications ---"
	KUBECONFIG=$(KUBECONFIG_PATH) $(MAKE) apps

# --- БЭКАПЫ (RESTIC) ---

backup: ## Запустить бэкап проекта в S3
	@echo "--- Starting Restic Backup ---"
	ansible-playbook $(ANSIBLE_BACKUP) -K --ask-vault-pass

backup-list: ## Посмотреть список всех снимков в S3
	@$(R_ENV) && restic snapshots

backup-ls: ## Посмотреть файлы внутри последнего бэкапа
	@$(R_ENV) && restic ls latest

backup-check: ## Проверить целостность данных в S3
	@$(R_ENV) && restic check

# --- УПРАВЛЕНИЕ ---

generate-secrets: ## Только создать файл секретов для проверки
	ansible-playbook $(ANSIBLE_SECRETS) --ask-vault-pass

apps: ## Деплой приложений
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(APPS_DIR)/

down: confirm ## Удалить ресурсы K8s и виртуалки
	@echo "--- Removing K8s resources ---"
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete -f $(APPS_DIR)/ --timeout=60s
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pvc --all -A --timeout=60s
	@echo "--- Terraform Destroy ---"
	cd $(TF_DIR) && terraform destroy -auto-approve
	rm -f ./join_command.txt $(KUBECONFIG_PATH) zfs-iscsi-secrets.yaml

vm-status: ## Статус всех виртуалок на гипервизорах
	ssh km@192.168.1.22 "virsh -c qemu:///system list --all"
	-ssh km@192.168.1.23 "virsh -c qemu:///system list --all"

clean-pvc: ## Очистить ZFS на TrueNAS
	ssh km@192.168.1.30 "sudo zfs destroy -r NVME/k8s-vols/data && sudo zfs create NVME/k8s-vols/data"

confirm:
	@read -p "⚠️ УВЕРЕНЫ? [y/N]: " ans; [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]

help: ## Показать это меню
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
