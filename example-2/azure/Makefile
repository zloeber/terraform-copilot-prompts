# Makefile for Azure Kubernetes Service Infrastructure
# Provides convenient commands for managing the Terraform infrastructure

.PHONY: help init plan apply destroy validate format check-azure login clean

# Default target
help: ## Show this help message
	@echo "Azure Kubernetes Service Infrastructure Management"
	@echo "==============================================="
	@echo ""
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Variables
TERRAFORM_DIR := .
TFVARS_FILE := terraform.tfvars

# Terraform Operations
init: ## Initialize Terraform
	@echo "Initializing Terraform..."
	terraform -chdir=$(TERRAFORM_DIR) init

validate: ## Validate Terraform configuration
	@echo "Validating Terraform configuration..."
	terraform -chdir=$(TERRAFORM_DIR) validate

format: ## Format Terraform files
	@echo "Formatting Terraform files..."
	terraform -chdir=$(TERRAFORM_DIR) fmt -recursive

plan: check-tfvars ## Plan Terraform deployment
	@echo "Planning Terraform deployment..."
	terraform -chdir=$(TERRAFORM_DIR) plan -var-file=$(TFVARS_FILE)

apply: check-tfvars ## Apply Terraform configuration
	@echo "Applying Terraform configuration..."
	terraform -chdir=$(TERRAFORM_DIR) apply -var-file=$(TFVARS_FILE)

apply-auto-approve: check-tfvars ## Apply Terraform configuration without confirmation
	@echo "Auto-applying Terraform configuration..."
	terraform -chdir=$(TERRAFORM_DIR) apply -var-file=$(TFVARS_FILE) -auto-approve

destroy: check-tfvars ## Destroy Terraform infrastructure
	@echo "Destroying Terraform infrastructure..."
	terraform -chdir=$(TERRAFORM_DIR) destroy -var-file=$(TFVARS_FILE)

destroy-auto-approve: check-tfvars ## Destroy Terraform infrastructure without confirmation
	@echo "Auto-destroying Terraform infrastructure..."
	terraform -chdir=$(TERRAFORM_DIR) destroy -var-file=$(TFVARS_FILE) -auto-approve

# Azure Operations
check-azure: ## Check Azure CLI authentication
	@echo "Checking Azure CLI authentication..."
	@az account show > /dev/null 2>&1 || (echo "Error: Not logged in to Azure CLI. Run 'make login' first." && exit 1)
	@echo "Azure CLI authentication: OK"
	@echo "Current subscription: $$(az account show --query name -o tsv)"

login: ## Login to Azure CLI
	@echo "Logging in to Azure CLI..."
	az login

logout: ## Logout from Azure CLI
	@echo "Logging out from Azure CLI..."
	az logout

set-subscription: ## Set Azure subscription (requires SUBSCRIPTION_ID)
	@if [ -z "$(SUBSCRIPTION_ID)" ]; then \
		echo "Error: SUBSCRIPTION_ID is required. Usage: make set-subscription SUBSCRIPTION_ID=your-subscription-id"; \
		exit 1; \
	fi
	az account set --subscription $(SUBSCRIPTION_ID)

list-subscriptions: ## List available Azure subscriptions
	@echo "Available Azure subscriptions:"
	az account list --output table

# Kubernetes Operations
get-credentials: ## Get AKS cluster credentials (requires RESOURCE_GROUP and CLUSTER_NAME)
	@if [ -z "$(RESOURCE_GROUP)" ] || [ -z "$(CLUSTER_NAME)" ]; then \
		echo "Error: RESOURCE_GROUP and CLUSTER_NAME are required."; \
		echo "Usage: make get-credentials RESOURCE_GROUP=your-rg CLUSTER_NAME=your-cluster"; \
		exit 1; \
	fi
	az aks get-credentials --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME)

connect-cluster: ## Connect to AKS cluster using Terraform outputs
	@echo "Getting cluster credentials from Terraform outputs..."
	$(eval RESOURCE_GROUP := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw resource_group_name))
	$(eval CLUSTER_NAME := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw aks_cluster_name))
	az aks get-credentials --resource-group $(RESOURCE_GROUP) --name $(CLUSTER_NAME)
	@echo "Cluster credentials configured. Testing connection..."
	kubectl get nodes

acr-login: ## Login to Azure Container Registry using Terraform outputs
	@echo "Getting ACR name from Terraform outputs..."
	$(eval ACR_NAME := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw acr_name))
	az acr login --name $(ACR_NAME)

# Container Registry Operations
build-and-push: ## Build and push sample application (requires IMAGE_NAME)
	@if [ -z "$(IMAGE_NAME)" ]; then \
		echo "Error: IMAGE_NAME is required. Usage: make build-and-push IMAGE_NAME=myapp:v1.0"; \
		exit 1; \
	fi
	$(eval ACR_NAME := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw acr_name))
	docker tag $(IMAGE_NAME) $(ACR_NAME).azurecr.io/$(IMAGE_NAME)
	docker push $(ACR_NAME).azurecr.io/$(IMAGE_NAME)

# Kubernetes Deployment
deploy-sample: ## Deploy sample application to AKS
	@echo "Deploying sample application..."
	$(eval ACR_NAME := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw acr_name))
	@sed "s/<acr-name>/$(ACR_NAME)/g" sample-kubernetes-deployment.yaml | kubectl apply -f -
	@echo "Sample application deployed. Check status with: kubectl get pods -n sample-app"

undeploy-sample: ## Remove sample application from AKS
	@echo "Removing sample application..."
	kubectl delete namespace sample-app --ignore-not-found=true

# Utility Operations
check-tfvars: ## Check if terraform.tfvars exists
	@if [ ! -f $(TFVARS_FILE) ]; then \
		echo "Error: $(TFVARS_FILE) not found. Copy from terraform.tfvars.example and customize."; \
		exit 1; \
	fi

create-tfvars: ## Create terraform.tfvars from example
	@if [ -f $(TFVARS_FILE) ]; then \
		echo "Warning: $(TFVARS_FILE) already exists. Backing up to $(TFVARS_FILE).backup"; \
		cp $(TFVARS_FILE) $(TFVARS_FILE).backup; \
	fi
	cp terraform.tfvars.example $(TFVARS_FILE)
	@echo "Created $(TFVARS_FILE). Please customize it with your values."

outputs: ## Show Terraform outputs
	@echo "Terraform outputs:"
	terraform -chdir=$(TERRAFORM_DIR) output

state-list: ## List Terraform state resources
	@echo "Terraform state resources:"
	terraform -chdir=$(TERRAFORM_DIR) state list

clean: ## Clean Terraform files (keeps state)
	@echo "Cleaning Terraform temporary files..."
	rm -rf $(TERRAFORM_DIR)/.terraform/
	rm -f $(TERRAFORM_DIR)/.terraform.lock.hcl
	rm -f $(TERRAFORM_DIR)/terraform.tfplan

clean-all: clean ## Clean all Terraform files including state (DANGEROUS)
	@echo "WARNING: This will remove ALL Terraform state files!"
	@read -p "Are you sure? Type 'yes' to confirm: " confirm; \
	if [ "$$confirm" != "yes" ]; then \
		echo "Cancelled."; \
		exit 1; \
	fi
	rm -f $(TERRAFORM_DIR)/terraform.tfstate*

# Monitoring and Troubleshooting
show-cluster-info: ## Show cluster information
	@echo "Cluster Information:"
	kubectl cluster-info
	@echo ""
	@echo "Node Information:"
	kubectl get nodes -o wide
	@echo ""
	@echo "System Pods:"
	kubectl get pods -n kube-system

show-logs: ## Show container insights logs (requires az cli)
	@echo "Recent container logs from Azure Monitor..."
	$(eval RESOURCE_GROUP := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw resource_group_name))
	$(eval LOG_WORKSPACE := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw log_analytics_workspace_name))
	@echo "Log Analytics Workspace: $(LOG_WORKSPACE)"
	@echo "Use Azure Portal to view detailed logs and metrics."

check-connectivity: ## Check cluster and registry connectivity
	@echo "Checking connectivity..."
	@echo "1. Kubectl connectivity:"
	kubectl get nodes || echo "Failed to connect to cluster"
	@echo ""
	@echo "2. ACR connectivity:"
	$(eval ACR_NAME := $(shell terraform -chdir=$(TERRAFORM_DIR) output -raw acr_name))
	az acr check-health --name $(ACR_NAME) || echo "Failed to connect to ACR"

# Infrastructure Status
status: check-azure ## Show infrastructure status
	@echo "Infrastructure Status:"
	@echo "====================="
	@echo ""
	@echo "Azure Subscription: $$(az account show --query name -o tsv)"
	@echo ""
	@if [ -f $(TERRAFORM_DIR)/terraform.tfstate ]; then \
		echo "Terraform State: Present"; \
		echo ""; \
		echo "Resources:"; \
		terraform -chdir=$(TERRAFORM_DIR) state list | head -10; \
		echo ""; \
		echo "Key Outputs:"; \
		terraform -chdir=$(TERRAFORM_DIR) output --json | jq -r 'to_entries[] | select(.key | test(".*_name$$|.*_id$$")) | "\(.key): \(.value.value)"' 2>/dev/null || echo "Run terraform apply first"; \
	else \
		echo "Terraform State: Not found - run 'make apply' first"; \
	fi

# Development helpers
dev-setup: check-azure create-tfvars init ## Complete development setup
	@echo "Development setup complete!"
	@echo "Next steps:"
	@echo "1. Edit terraform.tfvars with your values"
	@echo "2. Run 'make plan' to review the infrastructure"
	@echo "3. Run 'make apply' to deploy"

quick-deploy: dev-setup plan apply connect-cluster ## Quick deployment for development
	@echo "Quick deployment complete!"
	@echo "Cluster is ready for use."