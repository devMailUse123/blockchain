#!/bin/bash

# Script pour démarrer le réseau complet avec Fabric CAs
set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  DÉMARRAGE COMPLET DU RÉSEAU FABRIC${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Étape 1: Nettoyer
echo -e "${YELLOW}🧹 [1/3] Nettoyage...${NC}"
cd /home/absolue/my-blockchain/deploy
docker compose -f docker-compose-ca.yaml down -v 2>/dev/null || true
docker compose down -v 2>/dev/null || true
cd /home/absolue/my-blockchain
sudo rm -rf network/organizations 2>/dev/null || true
mkdir -p network/organizations/peerOrganizations network/organizations/ordererOrganizations

# Étape 2: Démarrer les CAs et générer les certificats
echo -e "${YELLOW}🔐 [2/3] Démarrage des CAs et génération des certificats...${NC}"
cd /home/absolue/my-blockchain/deploy
docker-compose -f docker-compose-ca.yaml up -d

echo -e "   Attente du démarrage des CAs (20 secondes)..."
sleep 20

# Vérifier que les CAs sont démarrés
echo -e "   ${GREEN}✓${NC} CAs démarrés"
docker ps --filter "name=ca-" --format "     - {{.Names}}: {{.Status}}"

cd /home/absolue/my-blockchain

# Inscription des identités avec cryptogen (solution temporaire)
echo -e "${YELLOW}   Génération des certificats avec cryptogen...${NC}"
export PATH=/home/absolue/fabric-samples/bin:$PATH
cryptogen generate --config=network/crypto-config.yaml --output=network/organizations > /dev/null 2>&1
echo -e "   ${GREEN}✓${NC} Certificats générés"

# Génération du bloc genesis du canal
echo -e "${YELLOW}   Génération du bloc genesis du canal...${NC}"
export FABRIC_CFG_PATH=/home/absolue/my-blockchain/network
export PATH=/home/absolue/fabric-samples/bin:$PATH
mkdir -p network/channel-artifacts
configtxgen -profile FoncierOrdererGenesis \
    -outputBlock network/channel-artifacts/contrat-agraire.block \
    -channelID contrat-agraire > /dev/null 2>&1
echo -e "   ${GREEN}✓${NC} Bloc genesis créé"

# Étape 3: Démarrer le réseau
echo -e "${YELLOW}🚀 [3/3] Démarrage du réseau Fabric...${NC}"
cd /home/absolue/my-blockchain/deploy
docker-compose up -d

echo -e "   Attente du démarrage du réseau (15 secondes)..."
sleep 15

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ RÉSEAU DÉMARRÉ AVEC SUCCÈS !${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}\n"

# Afficher l'état des conteneurs
echo -e "${YELLOW}📊 État des conteneurs:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAMES|foncier|couchdb|orderer|cli"

echo -e "\n${YELLOW}📝 Prochaines étapes:${NC}"
echo -e "   1. Créer les canaux: ${GREEN}make deploy-full${NC}"
echo -e "   2. Tester: ${GREEN}make test-create${NC}"
