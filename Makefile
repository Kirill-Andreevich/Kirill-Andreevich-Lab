# Переменные путей
TF_DIR = terraform
ANSIBLE_DIR = ansible
INVENTORY = $(ANSIBLE_DIR)/inventory/generated_hosts.ini
SITE_YAML = $(ANSIBLE_DIR)/site.yml

# Отключаем проверку SSH ключей, так как виртуалки новые
export ANSIBLE_HOST_KEY_CHECKING=False

.PHONY: all up down provision ping help

help: ## Показать справку
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Создать инфраструктуру через Terraform
	cd $(TF_DIR) && terraform init && terraform apply -auto-approve

provision: ## Настроить софт (K8s v1.31 + Docker) через Ansible
	@echo "Ожидание готовности SSH..."
	sleep 20
	ansible-playbook -i $(INVENTORY) $(SITE_YAML)

all: up provision ## Полный цикл: развернуть и настроить

down: ## Удалить все виртуалки через Terraform
	cd $(TF_DIR) && terraform destroy -auto-approve

ping: ## Проверить связь со всеми нодами
	ansible all -i $(INVENTORY) -m ping
