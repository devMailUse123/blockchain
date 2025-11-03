.PHONY: help build package network-up network-down deploy-full test-create test-query clean logs

# Variables
CHAINCODE_NAME = foncier
CHAINCODE_VERSION = 4.0
CHAINCODE_SEQUENCE = 1
CHANNEL_NAME = contrat-agraire
NETWORK_DIR = deploy
SCRIPTS_DIR = scripts
CHAINCODE_DIR = chaincode-java
API_DIR = api
API_PORT = 3000

# Couleurs pour l'affichage
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

help: ## Afficher cette aide
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)║  Makefile - Blockchain Foncière Côte d'Ivoire          ║$(NC)"
	@echo "$(GREEN)═══════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "Commandes disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

build: ## Compiler le chaincode Java
	@echo "$(YELLOW)📦 Compilation du chaincode...$(NC)"
	cd $(CHAINCODE_DIR) && mvn clean package -DskipTests
	@echo "$(GREEN)✅ Chaincode compilé avec succès$(NC)"

package: build ## Créer le package chaincode (.tar.gz)
	@echo "$(YELLOW)📦 Création du package chaincode...$(NC)"
	@CHAINCODE_VERSION=$(CHAINCODE_VERSION) bash $(SCRIPTS_DIR)/package-chaincode.sh
	@echo "$(GREEN)✅ Package créé: foncier-v$(CHAINCODE_VERSION).tar.gz$(NC)"

network-up: ## Démarrer le réseau Fabric
	@echo "$(YELLOW)🚀 Démarrage du réseau Fabric...$(NC)"
	cd $(NETWORK_DIR) && docker compose down -v
	cd $(NETWORK_DIR) && docker compose up -d
	@sleep 15
	@echo "$(GREEN)✅ Réseau démarré$(NC)"
	@docker ps --format "table {{.Names}}\t{{.Status}}"

network-down: ## Arrêter le réseau Fabric
	@echo "$(YELLOW)🛑 Arrêt du réseau...$(NC)"
	cd $(NETWORK_DIR) && docker compose down -v
	@echo "$(GREEN)✅ Réseau arrêté$(NC)"

deploy-full: package ## Déploiement complet du chaincode
	@echo "$(YELLOW)🚀 Déploiement complet du chaincode...$(NC)"
	@bash $(SCRIPTS_DIR)/deploy-full.sh
	@echo "$(GREEN)✅ Déploiement terminé$(NC)"

test-create: ## Créer un contrat de test
	@echo "$(YELLOW)🧪 Création d'un contrat de test...$(NC)"
	@bash $(SCRIPTS_DIR)/test-create-contract.sh
	@echo "$(GREEN)✅ Test terminé$(NC)"

create-contract: ## Créer un contrat réel sur la blockchain
	@echo "$(YELLOW)📝 Création d'un contrat sur la blockchain...$(NC)"
	@bash $(SCRIPTS_DIR)/create-contract-via-api.sh

test-query: ## Interroger les contrats
	@echo "$(YELLOW)🔍 Interrogation des contrats...$(NC)"
	@bash $(SCRIPTS_DIR)/test-query-contracts.sh

test-couchdb: ## Vérifier les données dans CouchDB
	@echo "$(YELLOW)🔍 Vérification CouchDB...$(NC)"
	@bash $(SCRIPTS_DIR)/test-couchdb.sh

logs: ## Afficher les logs des peers
	@echo "$(YELLOW)📋 Logs des peers...$(NC)"
	@echo "$(GREEN)--- AFOR Peer ---$(NC)"
	@docker logs peer0.afor.foncier.ci --tail 50
	@echo ""
	@echo "$(GREEN)--- CVGFR Peer ---$(NC)"
	@docker logs peer0.cvgfr.foncier.ci --tail 50

clean: network-down ## Nettoyer tout (réseau + fichiers générés)
	@echo "$(YELLOW)🧹 Nettoyage...$(NC)"
	rm -rf $(CHAINCODE_DIR)/target
	rm -f *.tar.gz code.tar.gz
	rm -rf tmp-code cc-package
	rm -f /tmp/install-*.log
	@echo "$(GREEN)✅ Nettoyage terminé$(NC)"

# Workflow complet
all: clean network-up deploy-full test-create test-query ## Workflow complet (tout réinitialiser et déployer)
	@echo "$(GREEN)✅ Workflow complet terminé avec succès !$(NC)"

# Quick start
quick: network-up deploy-full ## Démarrage rapide (réseau + déploiement)
	@echo "$(GREEN)✅ Démarrage rapide terminé !$(NC)"

# ========== API REST ==========

api-install: ## Installer les dépendances de l'API
	@echo "$(YELLOW)📦 Installation des dépendances de l'API...$(NC)"
	cd $(API_DIR) && npm install
	@echo "$(GREEN)✅ Dépendances installées$(NC)"

api-start: ## Démarrer l'API REST
	@echo "$(YELLOW)🚀 Démarrage de l'API REST...$(NC)"
	cd $(API_DIR) && mkdir -p logs && node src/server.js

api-dev: ## Démarrer l'API en mode développement (avec nodemon)
	@echo "$(YELLOW)🚀 Démarrage de l'API en mode développement...$(NC)"
	cd $(API_DIR) && npm run dev

api-test: ## Tester l'API REST
	@echo "$(YELLOW)🧪 Test de l'API REST...$(NC)"
	@sleep 2
	@echo "$(GREEN)1️⃣  Health Check:$(NC)"
	@curl -s http://localhost:$(API_PORT)/api/health | jq .
	@echo ""
	@echo "$(GREEN)2️⃣  Blockchain Health:$(NC)"
	@curl -s http://localhost:$(API_PORT)/api/health/blockchain | jq .

api-logs: ## Voir les logs de l'API
	@tail -f $(API_DIR)/logs/all.log

api-stop: ## Arrêter l'API REST
	@echo "$(YELLOW)🛑 Arrêt de l'API...$(NC)"
	@pkill -f "node src/server.js" || true
	@echo "$(GREEN)✅ API arrêtée$(NC)"

# ========== Workflow Complet avec API ==========

start-all: network-up deploy-full api-install api-start ## Tout démarrer (réseau + chaincode + API)
	@echo "$(GREEN)✅ Tout est démarré !$(NC)"
	@echo "$(YELLOW)API accessible sur: http://localhost:$(API_PORT)$(NC)"

stop-all: network-down api-stop ## Tout arrêter
	@echo "$(GREEN)✅ Tout est arrêté$(NC)"
