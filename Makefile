# Variables
TF_DIR = terraform
ANSIBLE_DIR = ansible

.PHONY: all deploy destroy clean ping ai-up

# Main command
all: deploy ai-up

# 1. Infrastructure Layer (Terraform)
deploy:
	@echo "Deploying virtual machines..."
	cd $(TF_DIR) && terraform apply -auto-approve

# 2. Connection Check
ping:
	@echo "Checking connectivity..."
	cd $(ANSIBLE_DIR) && ansible all -i inventory/generated_hosts.ini -m ping

# 3. Application Layer (Ansible)
ai-up:
	@echo "Deploying DeepSeek-R1..."
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/generated_hosts.ini site.yml

# 4. Destroy Everything
destroy:
	@echo "Destroying infrastructure..."
	cd $(TF_DIR) && terraform destroy -auto-approve

# 5. Clean up
clean:
	rm -rf $(TF_DIR)/.terraform
	rm -f $(TF_DIR)/*.tfstate*
	rm -f $(ANSIBLE_DIR)/inventory/generated_hosts.ini
