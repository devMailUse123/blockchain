#!/bin/bash
#
# Script de déploiement MONO-VM pour VM1 (AFOR)
# Déploie tout le réseau Fabric + API REST sur une seule machine
#
# Usage: ./deploy-vm1.sh

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DÉPLOIEMENT MONO-VM HYPERLEDGER FABRIC 3.1.1"
echo "  Sécurisation Foncière Rurale - Côte d'Ivoire"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$PROJECT_ROOT"

# Vérification Docker
echo -e "${YELLOW}[1/8] Vérification Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker non installé${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker $(docker --version | cut -d' ' -f3)${NC}"

# Vérification Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose non disponible${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose OK${NC}"

# Nettoyage (optionnel)
echo -e "${YELLOW}[2/8] Nettoyage des anciens conteneurs...${NC}"
cd deploy
docker compose down -v 2>/dev/null || true
echo -e "${GREEN}✅ Nettoyage terminé${NC}"

# Génération des certificats
echo -e "${YELLOW}[3/8] Génération des certificats MSP...${NC}"
cd "$PROJECT_ROOT"
if [ ! -d "network/organizations/ordererOrganizations" ]; then
    echo "Génération des certificats avec cryptogen..."
    cd scripts
    ./enroll-identities.sh || {
        echo -e "${RED}❌ Échec génération certificats${NC}"
        exit 1
    }
    cd "$PROJECT_ROOT"
fi
echo -e "${GREEN}✅ Certificats prêts${NC}"

# Création des artefacts du channel
echo -e "${YELLOW}[4/8] Création des artefacts channel...${NC}"
cd "$PROJECT_ROOT"
if [ ! -f "network/channel-artifacts/contrat-agraire.block" ]; then
    echo "Génération du genesis block..."
    cd scripts
    ./create-channels.sh genesis || {
        echo -e "${RED}❌ Échec création genesis block${NC}"
        exit 1
    }
    cd "$PROJECT_ROOT"
fi
echo -e "${GREEN}✅ Genesis block créé${NC}"

# Démarrage du réseau Fabric
echo -e "${YELLOW}[5/8] Démarrage réseau Fabric...${NC}"
cd "$PROJECT_ROOT/deploy"
docker compose up -d orderer.foncier.ci
sleep 5
docker compose up -d couchdb-afor couchdb-cvgfr couchdb-prefet
sleep 10
docker compose up -d peer0.afor.foncier.ci peer0.cvgfr.foncier.ci peer0.prefet.foncier.ci
sleep 5
docker compose up -d cli

echo -e "${GREEN}✅ Réseau Fabric démarré${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "orderer|peer|couchdb|cli"

# Join channel
echo -e "${YELLOW}[6/8] Création et join du channel...${NC}"
cd "$PROJECT_ROOT/scripts"
./create-channels.sh || echo "Channel déjà créé"
./join-channels.sh || {
    echo -e "${YELLOW}⚠️  Erreur join channel, retry possible${NC}"
}
echo -e "${GREEN}✅ Channel configuré${NC}"

# Compilation et déploiement chaincode
echo -e "${YELLOW}[7/8] Déploiement du chaincode...${NC}"
cd "$PROJECT_ROOT/chaincode-java"

# Vérifier si Maven est disponible
if command -v mvn &> /dev/null; then
    echo "Compilation du chaincode avec Maven..."
    mvn clean package -DskipTests
    echo -e "${GREEN}✅ Chaincode compilé${NC}"
else
    echo -e "${YELLOW}⚠️  Maven non trouvé, utilise le .jar existant${NC}"
fi

cd "$PROJECT_ROOT/scripts"
./package-chaincode.sh || {
    echo -e "${RED}❌ Échec packaging chaincode${NC}"
    exit 1
}
echo -e "${GREEN}✅ Chaincode déployé${NC}"

# Démarrage API REST
echo -e "${YELLOW}[8/8] Démarrage API REST...${NC}"
cd "$PROJECT_ROOT/deploy"
docker compose build api-rest
docker compose up -d api-rest
sleep 10

# Vérification API
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API REST opérationnelle${NC}"
else
    echo -e "${YELLOW}⚠️  API en cours de démarrage...${NC}"
fi

# Résumé final
echo ""
echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ DÉPLOIEMENT TERMINÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"
echo -e "${GREEN}Services actifs :${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo -e "${GREEN}API REST :${NC}"
echo "  • Health:  http://localhost:3000/health"
echo "  • Swagger: http://localhost:3000/api-docs"
echo "  • Base:    http://localhost:3000/api"
echo ""
echo -e "${GREEN}Commandes utiles :${NC}"
echo "  • Logs API:        docker logs -f api-rest"
echo "  • Logs peers:      docker logs -f peer0.afor.foncier.ci"
echo "  • Arrêter tout:    cd deploy && docker compose down"
echo "  • Tester API:      curl http://localhost:3000/health"
echo ""
echo -e "${YELLOW}Pour accès externe (depuis votre poste) :${NC}"
echo "  • Remplacer localhost par l'IP publique VM1"
echo ""
