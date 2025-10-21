#!/bin/bash

# Script pour faire rejoindre les peers aux canaux
set -e

export PATH=/home/absolue/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/absolue/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Faire rejoindre les Peers aux Canaux                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Récupérer les blocs genesis des canaux depuis l'orderer
echo -e "${YELLOW}[1/3] Récupération du bloc genesis du canal contrat-agraire...${NC}"
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

peer channel fetch 0 /tmp/contrat-agraire.block \
    -c contrat-agraire \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls \
    --cafile /home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt

echo -e "${GREEN}✅ Bloc genesis récupéré${NC}\n"

# Faire rejoindre AFOR au canal contrat-agraire
echo -e "${YELLOW}[2/3] AFOR rejoint le canal contrat-agraire...${NC}"
peer channel join -b /tmp/contrat-agraire.block

echo -e "${GREEN}✅ AFOR a rejoint contrat-agraire${NC}\n"

# Faire rejoindre CVGFR au canal contrat-agraire  
echo -e "${YELLOW}[3/3] CVGFR rejoint le canal contrat-agraire...${NC}"
export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp

peer channel join -b /tmp/contrat-agraire.block

echo -e "${GREEN}✅ CVGFR a rejoint contrat-agraire${NC}\n"

echo -e "\n${GREEN}✅ Tous les peers ont rejoint les canaux${NC}\n"

# Vérification
echo -e "${YELLOW}Vérification des canaux rejoints:${NC}"
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp
peer channel list

echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}✅ Les Peers ont rejoint les Canaux avec Succès!${BLUE}      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📝 Prochaine étape:${NC}"
echo -e "  Exécuter: bash scripts/approve-and-commit.sh"
