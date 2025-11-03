# ============================================================
# Makefile - Terraform Infrastructure Management
# ============================================================

.PHONY: help init plan apply destroy validate fmt clean backend check-backend output ssh-afor ssh-cvgfr ssh-prefet ssh-orderer

# Variables
TERRAFORM := terraform
AWS := aws
BACKEND_SCRIPT := ../scripts/terraform/setup-backend.sh
PLAN_FILE := tfplan

# Couleurs
GREEN := \033[0;32m
YELLOW := \033[1;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Afficher cette aide
	@echo "========================================="
	@echo "🚀 Terraform - Hyperledger Fabric AWS"
	@echo "========================================="
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

check-backend: ## Vérifier que le backend S3/DynamoDB existe
	@echo "$(YELLOW)🔍 Vérification du backend Terraform...$(NC)"
	@$(AWS) s3 ls s3://afor-blockchain-terraform-state > /dev/null 2>&1 || \
		(echo "$(RED)❌ Backend S3 non trouvé. Exécuter 'make backend' d'abord.$(NC)" && exit 1)
	@$(AWS) dynamodb describe-table --table-name afor-blockchain-terraform-locks > /dev/null 2>&1 || \
		(echo "$(RED)❌ Table DynamoDB non trouvée. Exécuter 'make backend' d'abord.$(NC)" && exit 1)
	@echo "$(GREEN)✅ Backend configuré correctement$(NC)"

backend: ## Créer le backend S3 + DynamoDB pour Terraform
	@echo "$(YELLOW)📦 Configuration du backend Terraform...$(NC)"
	@chmod +x $(BACKEND_SCRIPT)
	@$(BACKEND_SCRIPT)

init: check-backend ## Initialiser Terraform (télécharger les providers)
	@echo "$(YELLOW)🔧 Initialisation de Terraform...$(NC)"
	@$(TERRAFORM) init -upgrade
	@echo "$(GREEN)✅ Terraform initialisé$(NC)"

validate: ## Valider la syntaxe Terraform
	@echo "$(YELLOW)✔️  Validation de la configuration...$(NC)"
	@$(TERRAFORM) validate
	@echo "$(GREEN)✅ Configuration valide$(NC)"

fmt: ## Formater le code Terraform
	@echo "$(YELLOW)📝 Formatage du code...$(NC)"
	@$(TERRAFORM) fmt -recursive
	@echo "$(GREEN)✅ Code formaté$(NC)"

plan: validate ## Créer un plan de déploiement
	@echo "$(YELLOW)📊 Création du plan de déploiement...$(NC)"
	@$(TERRAFORM) plan -out=$(PLAN_FILE)
	@echo ""
	@echo "$(GREEN)✅ Plan créé: $(PLAN_FILE)$(NC)"
	@echo "Exécuter 'make apply' pour déployer"

plan-destroy: validate ## Créer un plan de destruction
	@echo "$(YELLOW)📊 Création du plan de destruction...$(NC)"
	@$(TERRAFORM) plan -destroy -out=$(PLAN_FILE)
	@echo ""
	@echo "$(RED)⚠️  Plan de destruction créé: $(PLAN_FILE)$(NC)"
	@echo "Exécuter 'make apply' pour détruire (⚠️ DANGER)"

apply: ## Appliquer le plan de déploiement
	@if [ ! -f $(PLAN_FILE) ]; then \
		echo "$(RED)❌ Fichier de plan non trouvé. Exécuter 'make plan' d'abord.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)🚀 Application du plan...$(NC)"
	@$(TERRAFORM) apply $(PLAN_FILE)
	@rm -f $(PLAN_FILE)
	@echo ""
	@echo "$(GREEN)✅ Déploiement terminé !$(NC)"
	@echo ""
	@make output

apply-auto: plan ## Appliquer automatiquement (sans confirmation)
	@echo "$(RED)⚠️  Application automatique en cours...$(NC)"
	@$(TERRAFORM) apply -auto-approve
	@echo "$(GREEN)✅ Déploiement terminé !$(NC)"

destroy: ## Détruire toute l'infrastructure (⚠️ DANGER)
	@echo "$(RED)⚠️  ⚠️  ⚠️  DESTRUCTION DE L'INFRASTRUCTURE ⚠️  ⚠️  ⚠️$(NC)"
	@echo ""
	@read -p "Taper 'yes' pour confirmer la destruction: " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		$(TERRAFORM) destroy; \
	else \
		echo "$(YELLOW)❌ Destruction annulée$(NC)"; \
	fi

destroy-auto: ## Détruire automatiquement (⚠️⚠️ EXTRÊMEMENT DANGEREUX)
	@echo "$(RED)⚠️  ⚠️  ⚠️  DESTRUCTION AUTOMATIQUE ⚠️  ⚠️  ⚠️$(NC)"
	@$(TERRAFORM) destroy -auto-approve

output: ## Afficher les outputs Terraform
	@echo "$(YELLOW)📋 Outputs Terraform:$(NC)"
	@echo ""
	@$(TERRAFORM) output
	@echo ""

output-json: ## Sauvegarder les outputs en JSON
	@echo "$(YELLOW)💾 Sauvegarde des outputs...$(NC)"
	@$(TERRAFORM) output -json > outputs.json
	@echo "$(GREEN)✅ Outputs sauvegardés dans outputs.json$(NC)"

state-list: ## Lister les ressources dans l'état Terraform
	@$(TERRAFORM) state list

state-show: ## Afficher les détails d'une ressource (usage: make state-show RESOURCE=module.vpc)
	@$(TERRAFORM) state show $(RESOURCE)

refresh: ## Rafraîchir l'état Terraform
	@echo "$(YELLOW)🔄 Rafraîchissement de l'état...$(NC)"
	@$(TERRAFORM) refresh
	@echo "$(GREEN)✅ État rafraîchi$(NC)"

graph: ## Générer un graphe de dépendances
	@echo "$(YELLOW)📊 Génération du graphe...$(NC)"
	@$(TERRAFORM) graph | dot -Tpng > graph.png
	@echo "$(GREEN)✅ Graphe sauvegardé: graph.png$(NC)"

clean: ## Nettoyer les fichiers temporaires
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	@rm -rf .terraform .terraform.lock.hcl $(PLAN_FILE) outputs.json graph.png
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

# ============================================================
# Commandes SSH
# ============================================================

ssh-afor: ## SSH vers le peer AFOR
	@INSTANCE_IP=$$($(TERRAFORM) output -json | jq -r '.peer_afor_private_ip.value'); \
	echo "$(YELLOW)🔐 Connexion SSH à AFOR ($$INSTANCE_IP)...$(NC)"; \
	ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@$$INSTANCE_IP

ssh-cvgfr: ## SSH vers le peer CVGFR
	@INSTANCE_IP=$$($(TERRAFORM) output -json | jq -r '.peer_cvgfr_private_ip.value'); \
	echo "$(YELLOW)🔐 Connexion SSH à CVGFR ($$INSTANCE_IP)...$(NC)"; \
	ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@$$INSTANCE_IP

ssh-prefet: ## SSH vers le peer PREFET
	@INSTANCE_IP=$$($(TERRAFORM) output -json | jq -r '.peer_prefet_private_ip.value'); \
	echo "$(YELLOW)🔐 Connexion SSH à PREFET ($$INSTANCE_IP)...$(NC)"; \
	ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@$$INSTANCE_IP

ssh-orderer: ## SSH vers l'orderer
	@INSTANCE_IP=$$($(TERRAFORM) output -json | jq -r '.orderer_private_ip.value'); \
	echo "$(YELLOW)🔐 Connexion SSH à Orderer ($$INSTANCE_IP)...$(NC)"; \
	ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@$$INSTANCE_IP

# ============================================================
# Commandes AWS
# ============================================================

instances: ## Lister les instances EC2
	@echo "$(YELLOW)📋 Instances EC2:$(NC)"
	@$(AWS) ec2 describe-instances \
		--filters "Name=tag:Project,Values=afor-blockchain" \
		--query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
		--output table

logs-peer: ## Afficher les logs CloudWatch des peers
	@echo "$(YELLOW)📋 Logs Fabric Peers:$(NC)"
	@$(AWS) logs tail /aws/ec2/fabric-peer --follow

logs-orderer: ## Afficher les logs CloudWatch de l'orderer
	@echo "$(YELLOW)📋 Logs Fabric Orderer:$(NC)"
	@$(AWS) logs tail /aws/ec2/fabric-orderer --follow

alb-status: ## Vérifier le status du Load Balancer
	@echo "$(YELLOW)🔍 Status ALB:$(NC)"
	@$(AWS) elbv2 describe-load-balancers \
		--names afor-blockchain-api-lb \
		--query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' \
		--output table

alb-targets: ## Vérifier les targets du Load Balancer
	@TG_ARN=$$($(AWS) elbv2 describe-target-groups --names afor-blockchain-api-tg --query 'TargetGroups[0].TargetGroupArn' --output text); \
	echo "$(YELLOW)🎯 Targets ALB:$(NC)"; \
	$(AWS) elbv2 describe-target-health --target-group-arn $$TG_ARN --output table

costs: ## Estimer les coûts mensuels
	@echo "$(YELLOW)💰 Estimation des coûts mensuels (us-east-1):$(NC)"
	@echo ""
	@echo "  Compute:"
	@echo "    - 3x EC2 t3.large (24/7)       ~$150"
	@echo "    - 1x EC2 t3.xlarge (24/7)      ~$100"
	@echo ""
	@echo "  Réseau:"
	@echo "    - 3x NAT Gateway                ~$100"
	@echo "    - Application Load Balancer     ~$20"
	@echo ""
	@echo "  Stockage:"
	@echo "    - EBS Storage (630 GB)          ~$65"
	@echo "    - S3 Backups (~100 GB)          ~$3"
	@echo ""
	@echo "  Monitoring:"
	@echo "    - CloudWatch Logs + Metrics     ~$12"
	@echo ""
	@echo "  $(GREEN)Total estimé: ~$450/mois$(NC)"
	@echo ""

# ============================================================
# Workflows Complets
# ============================================================

deploy: backend init plan apply output-json ## Déploiement complet de l'infrastructure
	@echo ""
	@echo "$(GREEN)=========================================$(NC)"
	@echo "$(GREEN)✅ Déploiement complet terminé !$(NC)"
	@echo "$(GREEN)=========================================$(NC)"
	@echo ""

check: validate fmt ## Vérifier la configuration et formater
	@echo "$(GREEN)✅ Checks terminés$(NC)"

.DEFAULT_GOAL := help
