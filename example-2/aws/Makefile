# Makefile for AWS EKS Infrastructure

.PHONY: help init plan apply destroy validate clean logs status connect push-image

# Variables
AWS_REGION ?= us-east-1
CLUSTER_NAME ?= $(shell terraform output -raw cluster_name 2>/dev/null || echo "eks-demo")
ECR_REPO ?= $(shell terraform output -raw ecr_repository_url 2>/dev/null)
DOCKER_IMAGE ?= my-app
DOCKER_TAG ?= latest

# Colors for output
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[1;33m
NC=\033[0m # No Color

## Show this help message
help:
	@echo "$(GREEN)AWS EKS Infrastructure Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Available commands:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Variables:$(NC)"
	@echo "  AWS_REGION    = $(AWS_REGION)"
	@echo "  CLUSTER_NAME  = $(CLUSTER_NAME)"
	@echo "  DOCKER_IMAGE  = $(DOCKER_IMAGE)"
	@echo "  DOCKER_TAG    = $(DOCKER_TAG)"

## Validate prerequisites
validate-prereq:
	@echo "$(YELLOW)Validating prerequisites...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)Terraform is required$(NC)"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "$(RED)AWS CLI is required$(NC)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl is required$(NC)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)Docker is required$(NC)"; exit 1; }
	@aws sts get-caller-identity >/dev/null 2>&1 || { echo "$(RED)AWS credentials not configured$(NC)"; exit 1; }
	@echo "$(GREEN)✅ Prerequisites validated$(NC)"

## Initialize Terraform
init: validate-prereq
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	terraform init
	@echo "$(GREEN)✅ Terraform initialized$(NC)"

## Validate Terraform configuration
validate: init
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	terraform validate
	terraform fmt -check
	@echo "$(GREEN)✅ Configuration validated$(NC)"

## Plan infrastructure changes
plan: validate
	@echo "$(YELLOW)Planning infrastructure changes...$(NC)"
	terraform plan -out=tfplan
	@echo "$(GREEN)✅ Plan created$(NC)"

## Apply infrastructure changes
apply: plan
	@echo "$(YELLOW)Applying infrastructure changes...$(NC)"
	terraform apply tfplan
	@rm -f tfplan
	@echo "$(GREEN)✅ Infrastructure deployed$(NC)"
	@$(MAKE) connect

## Quick deploy (plan and apply in one step)
deploy: validate
	@echo "$(YELLOW)Deploying infrastructure...$(NC)"
	terraform apply -auto-approve
	@echo "$(GREEN)✅ Infrastructure deployed$(NC)"
	@$(MAKE) connect

## Configure kubectl for cluster access
connect:
	@echo "$(YELLOW)Configuring kubectl...$(NC)"
	@if [ "$(CLUSTER_NAME)" = "eks-demo" ]; then \
		echo "$(RED)Cluster not found. Deploy infrastructure first.$(NC)"; \
		exit 1; \
	fi
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(CLUSTER_NAME)
	@echo "$(GREEN)✅ kubectl configured for cluster: $(CLUSTER_NAME)$(NC)"

## Show cluster status
status: connect
	@echo "$(YELLOW)Cluster Status:$(NC)"
	@echo "Region: $(AWS_REGION)"
	@echo "Cluster: $(CLUSTER_NAME)"
	@echo ""
	@kubectl cluster-info
	@echo ""
	@kubectl get nodes -o wide
	@echo ""
	@kubectl get pods --all-namespaces

## Show cluster logs
logs:
	@echo "$(YELLOW)Cluster Logs:$(NC)"
	@aws logs describe-log-groups --log-group-name-prefix "/aws/eks/$(CLUSTER_NAME)" --region $(AWS_REGION)

## Get ECR login and repository info
ecr-login:
	@echo "$(YELLOW)ECR Repository Info:$(NC)"
	@if [ -z "$(ECR_REPO)" ]; then \
		echo "$(RED)ECR repository not found. Deploy infrastructure first.$(NC)"; \
		exit 1; \
	fi
	@echo "Repository URL: $(ECR_REPO)"
	@echo ""
	@echo "$(YELLOW)Getting ECR login...$(NC)"
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REPO)
	@echo "$(GREEN)✅ Logged into ECR$(NC)"

## Build and push Docker image to ECR
push-image: ecr-login
	@echo "$(YELLOW)Building and pushing Docker image...$(NC)"
	@if [ ! -f "Dockerfile" ]; then \
		echo "$(RED)Dockerfile not found in current directory$(NC)"; \
		exit 1; \
	fi
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .
	docker tag $(DOCKER_IMAGE):$(DOCKER_TAG) $(ECR_REPO):$(DOCKER_TAG)
	docker push $(ECR_REPO):$(DOCKER_TAG)
	@echo "$(GREEN)✅ Image pushed to ECR: $(ECR_REPO):$(DOCKER_TAG)$(NC)"

## Scale node groups
scale-up:
	@echo "$(YELLOW)Scaling node groups up...$(NC)"
	aws eks update-nodegroup-config \
		--cluster-name $(CLUSTER_NAME) \
		--nodegroup-name system \
		--scaling-config minSize=3,maxSize=15,desiredSize=5 \
		--region $(AWS_REGION)
	aws eks update-nodegroup-config \
		--cluster-name $(CLUSTER_NAME) \
		--nodegroup-name application \
		--scaling-config minSize=3,maxSize=15,desiredSize=5 \
		--region $(AWS_REGION)
	@echo "$(GREEN)✅ Node groups scaled up$(NC)"

## Scale node groups down
scale-down:
	@echo "$(YELLOW)Scaling node groups down...$(NC)"
	aws eks update-nodegroup-config \
		--cluster-name $(CLUSTER_NAME) \
		--nodegroup-name system \
		--scaling-config minSize=1,maxSize=5,desiredSize=2 \
		--region $(AWS_REGION)
	aws eks update-nodegroup-config \
		--cluster-name $(CLUSTER_NAME) \
		--nodegroup-name application \
		--scaling-config minSize=1,maxSize=5,desiredSize=2 \
		--region $(AWS_REGION)
	@echo "$(GREEN)✅ Node groups scaled down$(NC)"

## Monitor cluster resources
monitor:
	@echo "$(YELLOW)Monitoring cluster resources...$(NC)"
	@watch 'kubectl top nodes 2>/dev/null || echo "Metrics server not available"; echo ""; kubectl get pods --all-namespaces'

## Deploy sample application
deploy-sample:
	@echo "$(YELLOW)Deploying sample application...$(NC)"
	kubectl apply -f - <<EOF
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  name: nginx-sample
	  namespace: default
	spec:
	  replicas: 2
	  selector:
	    matchLabels:
	      app: nginx-sample
	  template:
	    metadata:
	      labels:
	        app: nginx-sample
	    spec:
	      containers:
	      - name: nginx
	        image: nginx:latest
	        ports:
	        - containerPort: 80
	---
	apiVersion: v1
	kind: Service
	metadata:
	  name: nginx-sample-service
	  namespace: default
	spec:
	  selector:
	    app: nginx-sample
	  ports:
	  - port: 80
	    targetPort: 80
	  type: ClusterIP
	EOF
	@echo "$(GREEN)✅ Sample application deployed$(NC)"
	@kubectl get pods -l app=nginx-sample

## Remove sample application
remove-sample:
	@echo "$(YELLOW)Removing sample application...$(NC)"
	kubectl delete deployment nginx-sample 2>/dev/null || true
	kubectl delete service nginx-sample-service 2>/dev/null || true
	@echo "$(GREEN)✅ Sample application removed$(NC)"

## Show cluster endpoints and connection info
info:
	@echo "$(YELLOW)Cluster Information:$(NC)"
	@terraform output cluster_connection_info 2>/dev/null || echo "Run 'make apply' first"

## Show all outputs
outputs:
	@echo "$(YELLOW)Terraform Outputs:$(NC)"
	@terraform output

## Clean up local files
clean:
	@echo "$(YELLOW)Cleaning up local files...$(NC)"
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f tfplan
	rm -f terraform.tfstate.backup
	@echo "$(GREEN)✅ Local files cleaned$(NC)"

## Show cost estimation (requires infracost)
cost:
	@echo "$(YELLOW)Cost Estimation:$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		infracost breakdown --path .; \
	else \
		echo "$(RED)Infracost not installed. Visit: https://www.infracost.io/$(NC)"; \
	fi

## Destroy infrastructure (with confirmation)
destroy:
	@echo "$(RED)⚠️  WARNING: This will destroy ALL infrastructure!$(NC)"
	@echo "$(YELLOW)Type 'yes' to confirm:$(NC)"
	@read -p "" confirm && [ "$$confirm" = "yes" ] || (echo "$(GREEN)Cancelled$(NC)" && exit 1)
	@echo "$(YELLOW)Removing any deployed applications first...$(NC)"
	@$(MAKE) remove-sample 2>/dev/null || true
	@echo "$(YELLOW)Destroying infrastructure...$(NC)"
	terraform destroy -auto-approve
	@$(MAKE) clean
	@echo "$(GREEN)✅ Infrastructure destroyed$(NC)"

## Force destroy (no confirmation - USE WITH CAUTION)
force-destroy:
	@echo "$(RED)🚨 FORCE DESTROYING INFRASTRUCTURE...$(NC)"
	@$(MAKE) remove-sample 2>/dev/null || true
	terraform destroy -auto-approve
	@$(MAKE) clean
	@echo "$(GREEN)✅ Infrastructure force destroyed$(NC)"

## Run Terraform security scan (requires tfsec)
security-scan:
	@echo "$(YELLOW)Running security scan...$(NC)"
	@if command -v tfsec >/dev/null 2>&1; then \
		tfsec .; \
	else \
		echo "$(RED)tfsec not installed. Visit: https://tfsec.dev/$(NC)"; \
	fi

## Format Terraform code
format:
	@echo "$(YELLOW)Formatting Terraform code...$(NC)"
	terraform fmt -recursive
	@echo "$(GREEN)✅ Code formatted$(NC)"

## Show Terraform graph
graph:
	@echo "$(YELLOW)Generating Terraform dependency graph...$(NC)"
	terraform graph | dot -Tpng > terraform-graph.png
	@echo "$(GREEN)✅ Graph saved as terraform-graph.png$(NC)"

## Install kubectl plugins
install-plugins:
	@echo "$(YELLOW)Installing useful kubectl plugins...$(NC)"
	@if command -v krew >/dev/null 2>&1; then \
		kubectl krew install ctx ns top; \
		echo "$(GREEN)✅ Plugins installed$(NC)"; \
	else \
		echo "$(RED)Krew not installed. Visit: https://krew.sigs.k8s.io/$(NC)"; \
	fi

## Enable cluster autoscaler (example)
enable-autoscaler:
	@echo "$(YELLOW)Enabling cluster autoscaler...$(NC)"
	kubectl apply -f - <<EOF
	apiVersion: apps/v1
	kind: Deployment
	metadata:
	  name: cluster-autoscaler
	  namespace: kube-system
	  labels:
	    app: cluster-autoscaler
	spec:
	  selector:
	    matchLabels:
	      app: cluster-autoscaler
	  template:
	    metadata:
	      labels:
	        app: cluster-autoscaler
	    spec:
	      serviceAccountName: cluster-autoscaler
	      containers:
	      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
	        name: cluster-autoscaler
	        resources:
	          limits:
	            cpu: 100m
	            memory: 300Mi
	          requests:
	            cpu: 100m
	            memory: 300Mi
	        command:
	        - ./cluster-autoscaler
	        - --v=4
	        - --stderrthreshold=info
	        - --cloud-provider=aws
	        - --skip-nodes-with-local-storage=false
	        - --expander=least-waste
	        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/$(CLUSTER_NAME)
	EOF
	@echo "$(GREEN)✅ Cluster autoscaler configuration applied$(NC)"

## Quick troubleshooting
troubleshoot:
	@echo "$(YELLOW)Running troubleshooting checks...$(NC)"
	@echo "1. Cluster status:"
	@kubectl get nodes --no-headers | wc -l | xargs printf "   Nodes: %s\n"
	@echo "2. System pods:"
	@kubectl get pods -n kube-system | grep -v Running | wc -l | xargs printf "   Non-running system pods: %s\n"
	@echo "3. Recent events:"
	@kubectl get events --all-namespaces --sort-by='.firstTimestamp' | tail -5
	@echo "4. Node conditions:"
	@kubectl describe nodes | grep -A 5 "Conditions:"