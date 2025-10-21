#!/bin/bash

# Script pour créer les canaux via l'API Channel Participation
set -e

export PATH=/home/absolue/fabric-samples/bin:$PATH

ORDERER_ADMIN_URL="localhost:7053"
ORDERER_ADMIN_TLS_CERT="/home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt"
ORDERER_ADMIN_TLS_KEY="/home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key"
ORDERER_CA="/home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt"
CHANNEL_ARTIFACTS="/home/absolue/my-blockchain/network/channel-artifacts"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Création des Canaux via osnadmin                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Créer le canal contrat-agraire
echo -e "${YELLOW}[1/1] Création du canal contrat-agraire...${NC}"
osnadmin channel join \
  --channelID contrat-agraire \
  --config-block ${CHANNEL_ARTIFACTS}/contrat-agraire.block \
  -o ${ORDERER_ADMIN_URL} \
  --ca-file ${ORDERER_CA} \
  --client-cert ${ORDERER_ADMIN_TLS_CERT} \
  --client-key ${ORDERER_ADMIN_TLS_KEY} 2>&1 || echo "Canal déjà créé ou erreur ignorée"
echo -e "${GREEN}✅ Canal contrat-agraire créé${NC}\n"

# Vérifier les canaux créés
echo -e "${YELLOW}Vérification des canaux sur l'orderer:${NC}"
osnadmin channel list \
  -o ${ORDERER_ADMIN_URL} \
  --ca-file ${ORDERER_CA} \
  --client-cert ${ORDERER_ADMIN_TLS_CERT} \
  --client-key ${ORDERER_ADMIN_TLS_KEY}

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}✅ Canaux Créés avec Succès!${BLUE}                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"
