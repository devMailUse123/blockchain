#!/bin/bash

# Script de déploiement complet du chaincode Foncier
set -e

export PATH=/home/absolue/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/absolue/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true

# Chemins corrigés
BASE_DIR="/home/absolue/my-blockchain"
ORDERER_CA="${BASE_DIR}/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt"
CHANNEL_NAME="contrat-agraire"
CC_NAME="foncier"
CC_VERSION="${CHAINCODE_VERSION:-4.0}"
CC_SEQUENCE="${CHAINCODE_SEQUENCE:-1}"
CC_PACKAGE="${BASE_DIR}/foncier-v${CC_VERSION}.tar.gz"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier que le package existe
if [ ! -f "${CC_PACKAGE}" ]; then
    echo -e "${RED}❌ Erreur: Package non trouvé: ${CC_PACKAGE}${NC}"
    echo -e "${YELLOW}   Exécutez 'make package' d'abord${NC}"
    exit 1
fi

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  DÉPLOIEMENT COMPLET DU CHAINCODE FONCIER V${CC_VERSION}${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

# Étape 1: Créer les canaux
echo -e "${YELLOW}📋 [1/6] Création des canaux...${NC}"
bash /home/absolue/my-blockchain/scripts/create-channels.sh > /dev/null 2>&1
echo -e "${GREEN}✅ Canaux créés${NC}\n"

# Étape 2: Join des peers
echo -e "${YELLOW}🔗 [2/6] Join des peers aux canaux...${NC}"
bash /home/absolue/my-blockchain/scripts/join-channels.sh > /dev/null 2>&1 || true
echo -e "${GREEN}✅ Peers rejoints${NC}\n"

# Étape 3: Installer sur AFOR
echo -e "${YELLOW}📦 [3/6] Installation du chaincode sur AFOR...${NC}"
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

peer lifecycle chaincode install ${CC_PACKAGE} > /tmp/install-afor.log 2>&1 || true

# Extraire le Package ID
PACKAGE_ID=$(peer lifecycle chaincode queryinstalled 2>&1 | grep "foncier_${CC_VERSION}" | awk '{print $3}' | sed 's/,//')
echo -e "   Package ID: ${PACKAGE_ID}"
echo -e "${GREEN}✅ Installé sur AFOR${NC}\n"

# Étape 4: Installer sur CVGFR
echo -e "${YELLOW}📦 [4/6] Installation du chaincode sur CVGFR...${NC}"
export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp

peer lifecycle chaincode install ${CC_PACKAGE} > /tmp/install-cvgfr.log 2>&1 || true
echo -e "${GREEN}✅ Installé sur CVGFR${NC}\n"

# Étape 5: Approuver pour AFOR et CVGFR
echo -e "${YELLOW}✍️  [5/6] Approbation du chaincode...${NC}"

export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    --tls \
    --cafile ${ORDERER_CA} > /dev/null 2>&1

echo -e "   ✓ AFOR approuvé"

export CORE_PEER_LOCALMSPID="CVGFROrg"
export CORE_PEER_ADDRESS=localhost:8051
export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp

peer lifecycle chaincode approveformyorg \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --package-id ${PACKAGE_ID} \
    --sequence ${CC_SEQUENCE} \
    --tls \
    --cafile ${ORDERER_CA} > /dev/null 2>&1

echo -e "   ✓ CVGFR approuvé"
echo -e "${GREEN}✅ Approbations terminées${NC}\n"

# Étape 6: Commit
echo -e "${YELLOW}🔐 [6/6] Commit du chaincode sur le canal...${NC}"
peer lifecycle chaincode commit \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --channelID ${CHANNEL_NAME} \
    --name ${CC_NAME} \
    --version ${CC_VERSION} \
    --sequence ${CC_SEQUENCE} \
    --tls \
    --cafile ${ORDERER_CA} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles ${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    > /dev/null 2>&1

echo -e "${GREEN}✅ Chaincode committé${NC}\n"

# Initialisation du ledger
echo -e "${YELLOW}🚀 Initialisation du ledger...${NC}"
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls \
    --cafile ${ORDERER_CA} \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles ${BASE_DIR}/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles ${BASE_DIR}/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    -c '{"function":"initLedger","Args":[]}' > /dev/null 2>&1

echo -e "${GREEN}✅ Ledger initialisé${NC}\n"

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}║  ${GREEN}✅ DÉPLOIEMENT RÉUSSI !${BLUE}                                ║${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📊 Informations de déploiement:${NC}"
echo -e "   Canal: ${CHANNEL_NAME}"
echo -e "   Chaincode: ${CC_NAME}"
echo -e "   Version: ${CC_VERSION}"
echo -e "   Sequence: ${CC_SEQUENCE}"
echo -e "   Package ID: ${PACKAGE_ID}"

echo -e "\n${YELLOW}🧪 Commandes de test:${NC}"
echo -e "   # Lister les métadonnées:"
echo -e "   peer chaincode query -C ${CHANNEL_NAME} -n ${CC_NAME} -c '{\"Args\":[\"lireMetadata\"]}'"
echo -e ""
echo -e "   # Tester la création d'un contrat (voir docs/API.md pour le format complet)"
