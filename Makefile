# --- ПЕРЕМЕННЫЕ ПУТЕЙ ---
SHELL := /bin/bash
TF_INFRA_DIR = terraform/infra-vms
TF_CLUSTER_DIR = terraform/cluster-nodes
ANSIBLE_DIR = ansible
ANSIBLE_PLAYBOOKS = $(ANSIBLE_DIR)/playbooks
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
APPS_DIR = kubernetes/apps
CORE_DIR = kubernetes/core
KUBECONFIG_PATH = $(HOME)/.kube/config
HYPERVISORS = 192.168.1.22 192.168.1.23
SSH_USER = km
ANSIBLE_SECRETS = $(ANSIBLE_PLAYBOOKS)/00_generate_secrets.yml

export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all secrets infra k8s-base storage monitoring apps down status watch nodes pods logs shell pvc events clean-failed help vm-status vm-start vm-stop vm-kill backup report snapshots test-alert

# --- ОСНОВНЫЕ ЦИКЛЫ ---

all: secrets infra k8s-base storage monitoring apps ## Полный разворот: Секреты -> Инфра -> Кубер -> CSI -> Мониторинг -> Аппсы

secrets: ## Шаг 1: Генерация секретов (ZFS iSCSI, Alertmanager)
	@echo ">>> Генерация секретов из Vault..."
	@ansible-playbook $(ANSIBLE_SECRETS) --ask-vault-pass

infra: ## Шаг 2: Поднятие виртуальных машин (Terraform)
	@echo ">>> Развертывание инфраструктуры KVM..."
	cd $(TF_INFRA_DIR) && terraform init && terraform apply -auto-approve
	cd $(TF_CLUSTER_DIR) && terraform init && terraform apply -auto-approve

k8s-base: ## Шаг 3: Настройка ОС и Bootstrap Kubernetes
	@echo ">>> Установка Kubernetes и сетевой фабрики..."
	@sleep 30
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_PLAYBOOKS)/01_prepare.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_PLAYBOOKS)/02_install_k8s.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_PLAYBOOKS)/02_init_master.yml
	ansible-playbook -i $(INVENTORY) $(ANSIBLE_PLAYBOOKS)/02_join_workers.yml
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl wait --for=condition=Ready nodes --all --timeout=60s
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.3/config/manifests/metallb-native.yaml
	@sleep 20
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(CORE_DIR)/metallb-config.yaml

storage: ## Шаг 4: Развертывание Democratic CSI (TrueNAS iSCSI)
	@echo ">>> Подключение хранилища TrueNAS..."
	KUBECONFIG=$(KUBECONFIG_PATH) helm upgrade --install truenas-iscsi $(CORE_DIR)/democratic-csi \
		--namespace democratic-csi --create-namespace \
		-f $(CORE_DIR)/truenas-csi/zfs-iscsi-base.yaml \
		-f $(CORE_DIR)/truenas-csi/zfs-iscsi-prod.yaml \
		-f $(CORE_DIR)/truenas-csi/zfs-iscsi-secrets.yaml

monitoring: ## Шаг 5: Установка Prometheus, Grafana, Loki и Promtail
	@echo ">>> Развертывание стека мониторинга..."
	KUBECONFIG=$(KUBECONFIG_PATH) helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	KUBECONFIG=$(KUBECONFIG_PATH) helm repo add grafana https://grafana.github.io/helm-charts
	KUBECONFIG=$(KUBECONFIG_PATH) helm repo update
	
	@echo ">>> Установка Loki..."
	KUBECONFIG=$(KUBECONFIG_PATH) helm upgrade --install loki grafana/loki-stack \
		--namespace monitoring --create-namespace \
		-f $(CORE_DIR)/loki-values.yaml
		
	@echo ">>> Установка Kube-Prometheus-Stack (с MetalLB для UI)..."
	KUBECONFIG=$(KUBECONFIG_PATH) helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
		--namespace monitoring --create-namespace \
		-f $(CORE_DIR)/alertmanager-values-secrets.yaml \
		--set grafana.service.type=LoadBalancer \
		--set prometheus.service.type=LoadBalancer \
		--set alertmanager.service.type=LoadBalancer
		
	@echo ">>> Применение правил алертов и дашбордов..."
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(CORE_DIR)/hedgehog-rules.yaml
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(CORE_DIR)/network-alerts.yaml
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(CORE_DIR)/loki-datasource.yaml
	
	@echo ">>> Запуск Promtail на гипервизорах..."
	ansible-playbook $(ANSIBLE_PLAYBOOKS)/deploy_promtail.yml

apps: ## Шаг 6: Деплой пользовательских приложений
	@echo ">>> Запуск приложений (Nextcloud, Jellyfin)..."
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl apply -f $(APPS_DIR)/

down: confirm ## Полное удаление ресурсов K8s и инфраструктуры
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete -f $(APPS_DIR)/ --timeout=30s
	-KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pvc --all -A --timeout=30s
	cd $(TF_CLUSTER_DIR) && terraform destroy -auto-approve
	cd $(TF_INFRA_DIR) && terraform destroy -auto-approve

# --- МОНИТОРИНГ И ДЕБАГ ---
status: ## Сводный отчет: ноды, поды, сервисы и диски
	@echo "--- NODES ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide
	@echo "\n--- PODS ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A
	@echo "\n--- STORAGE (PVC) ---"
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pvc -A

watch: ## Живой мониторинг ресурсов
	watch -n 2 "KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes,pods,svc,pvc -A"

nodes: ## Список всех нод кластера
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get nodes -o wide

pods: ## Список всех подов во всех неймспейсах
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -A

logs: ## Посмотреть логи (usage: make logs app=nextcloud)
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl logs -f $$(KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -l app=$(app) -o name | head -n 1)

shell: ## Зайти в консоль пода (usage: make shell app=jellyfin)
	@KUBECONFIG=$(KUBECONFIG_PATH) kubectl exec -it $$(KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pods -l app=$(app) -o name | head -n 1) -- /bin/bash

pvc: ## Проверить состояние дисков TrueNAS iSCSI
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get pvc,pv -A

events: ## Последние события в кластере
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl get events --sort-by=.lastTimestamp -A

clean-failed: ## Удалить упавшие поды
	KUBECONFIG=$(KUBECONFIG_PATH) kubectl delete pods --field-selector status.phase=Failed -A

# --- УПРАВЛЕНИЕ ГИПЕРВИЗОРАМИ ---
vm-status: ## Статус всех ВМ на гипервизорах
	@for host in $(HYPERVISORS); do \
		echo "--- $$host ---"; \
		ssh $(SSH_USER)@$$host "virsh -c qemu:///system list --all"; \
	done

vm-start: ## Включить все ВМ кластера
	@for host in $(HYPERVISORS); do \
		echo ">>> Starting VMs on host..."; \
		ssh $(SSH_USER)@$$host "virsh -c qemu:///system list --all --name --state-shutoff | grep -v win | xargs -r -I {} virsh -c qemu:///system start {}"; \
	done

vm-stop: ## Мягкое выключение нод
	@for host in $(HYPERVISORS); do \
		echo ">>> Stopping VMs on host..."; \
		ssh $(SSH_USER)@$$host "virsh -c qemu:///system list --all --name --state-running | grep -v win | xargs -r -I {} virsh -c qemu:///system shutdown {}"; \
	done

vm-kill: ## ЖЕСТКОЕ выключение нод (Destroy)
	@echo -n "⚠ WARNING: Hard kill all non-win VMs? [y/N]: " && read ans && [ $${ans:-N} = y ]
	@for host in $(HYPERVISORS); do \
		echo ">>> KILLING VMs on host..."; \
		ssh $(SSH_USER)@$$host "virsh -c qemu:///system list --name --state-running | grep -v win | xargs -r -I {} virsh -c qemu:///system destroy {}"; \
	done

# --- ОБСЛУЖИВАНИЕ И БЭКАП ---
report: ## Генерация MD-дампа и синхронизация (helper.sh)
	./helper.sh

backup: ## Бэкап в S3 через Restic
	@source .restic_env && restic -r RESTIC_REPOSITORY backup . --exclude-file=.restic_ignore

snapshots: ## Посмотреть список бэкапов в S3
	@source .restic_env && restic -r RESTIC_REPOSITORY snapshots

test-alert: ## Проверка связи Alertmanager -> Telegram
	$(eval ALERT_IP := $(shell KUBECONFIG=$(KUBECONFIG_PATH) kubectl get svc -n monitoring kube-prometheus-stack-alertmanager -o jsonpath='{.status.loadBalancer.ingress.ip}'))
	@if [ -z "$(ALERT_IP)" ]; then echo "❌ Ошибка: У Alertmanager нет External IP."; exit 1; fi
	@echo "--- Sending Test Alert to $(ALERT_IP) ---"
	@curl -X POST http://$(ALERT_IP):9093/api/v2/alerts \
		-H "Content-Type: application/json" \
		-d '[{"labels":{"alertname":"ManualTestAlert","severity":"critical","instance":"$(shell hostname)"},"annotations":{"description":"Это проверка связи! Бот работает."}}]'

# --- ХЕЛПЕРЫ ---
confirm:
	@read -p "⚠ Уверены? [y/N]: " ans; [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]

help: ## Показать это меню помощи
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
