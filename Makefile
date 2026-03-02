# --- ПЕРЕМЕННЫЕ ПУТЕЙ ---
TF_APPS_DIR = terraform/apps
TF_K8S_DIR = terraform/k8s
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
APPS_DIR = kubernetes/apps
KUBECONFIG_PATH = $(HOME)/.kube/config
HYPERVISORS = 192.168.1.22 192.168.1.23
SSH_USER = km

ANSIBLE_SECRETS = $(ANSIBLE_DIR)/00_generate_secrets.yml
export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all down apps infra-apps infra-k8s status watch nodes pods logs shell pvc events clean-failed help vm-status

# --- ОСНОВНЫЕ ЦИКЛЫ ---

all: infra-apps infra-k8s ## Полный разворот: Инфра -> Секреты -> Кубер -> Аппсы
	@ansible-playbook $(ANSIBLE_SECRETS) --ask-vault-pass
	sleep 30
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/01_prepare.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_install_k8s.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_init_master.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_DIR)/02_join_workers.yml
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl wait --for=condition=Ready nodes --all --timeout=60s
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
	@sleep 20
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f kubernetes/main/metallb-config.yaml
	KUBECONFIG=$(KUBECONFIG_PATH) helm upgrade --install truenas-iscsi ./democratic-csi --namespace democratic-csi --create-namespace -f zfs-iscsi-base.yaml -f zfs-iscsi-prod.yaml -f zfs-iscsi-secrets.yaml
	KUBECONFIG=$(KUBECONFIG_PATH) $(MAKE) apps

down: confirm ## Полное удаление ресурсов K8s и инфраструктуры
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete -f $(APPS_DIR)/ --timeout=30s
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pvc --all -A --timeout=30s
	cd $(TF_K8S_DIR) && terraform destroy -auto-approve
	cd $(TF_APPS_DIR) && terraform destroy -auto-approve

# --- МОНИТОРИНГ ---

status: ## Сводный отчет: ноды, поды, сервисы (IP от MetalLB) и диски
	@echo "--- NODES ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide
	@echo "\n--- PODS ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A
	@echo "\n--- STORAGE (PVC) ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pvc -A

watch: ## Живой мониторинг ресурсов в реальном времени
	watch -n 2 "KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes,pods,svc,pvc -A"

# --- УПРАВЛЕНИЕ K8S ---

nodes: ## Список всех нод кластера
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide

pods: ## Список всех подов во всех неймспейсах
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A

logs: ## Посмотреть логи приложения (usage: make logs app=nextcloud)
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl logs -f $$(KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -l app=$(app) -o name | head -n 1)

shell: ## Зайти в консоль пода (usage: make shell app=jellyfin)
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl exec -it $$(KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -l app=$(app) -o name | head -n 1) -- /bin/bash

pvc: ## Проверить состояние дисков TrueNAS iSCSI
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pvc,pv -A

events: ## Последние события в кластере (дебаг)
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get events --sort-by=.lastTimestamp -A

clean-failed: ## Удалить поды со статусом Failed или Evicted
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pods --field-selector status.phase=Failed -A

# --- ИНФРАСТРУКТУРА ---

infra-apps: ## Развернуть защищенный слой Apps (GitLab)
	cd $(TF_APPS_DIR) && terraform init && terraform apply -auto-approve

infra-k8s: ## Развернуть динамический слой K8s (Master + Workers)
	cd $(TF_K8S_DIR) && terraform init && terraform apply -auto-approve

vm-status: ## Состояние ВМ на гипервизорах (virsh)
	@for host in $(HYPERVISORS); do echo "--- $$host ---"; ssh $(SSH_USER)@$$host "virsh -c qemu:///system list --all"; done

confirm:
	@read -p "Уверены? [y/N]: " ans; [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]

help: ## Показать это меню помощи
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
