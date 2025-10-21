#!/bin/bash

# Script de test - Création d'un contrat
set -e

# Configuration Fabric
export PATH=/home/absolue/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/absolue/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

ORDERER_CA=/home/absolue/my-blockchain/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt
CHANNEL_NAME="contrat-agraire"
CC_NAME="foncier"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  TEST - CRÉATION DE CONTRAT                   ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════${NC}\n"

# Charger le JSON de test
TEST_FILE="${TEST_FILE:-test-data/contrat-simple.json}"
if [ ! -f "$TEST_FILE" ]; then
    echo -e "${RED}❌ Fichier de test non trouvé: $TEST_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📄 Chargement du contrat de test...${NC}"
CONTRAT_JSON=$(cat $TEST_FILE | jq -c .)
CODE_CONTRAT=$(cat $TEST_FILE | jq -r '.codeContract')

echo -e "${GREEN}✓${NC} Code contrat: ${CODE_CONTRAT}"
echo -e "${GREEN}✓${NC} Bailleur: $(cat $TEST_FILE | jq -r '.owner.nom') $(cat $TEST_FILE | jq -r '.owner.prenoms')"
echo -e "${GREEN}✓${NC} Preneur: $(cat $TEST_FILE | jq -r '.beneficiary.nom') $(cat $TEST_FILE | jq -r '.beneficiary.prenoms')"
echo -e "${GREEN}✓${NC} Terrain: $(cat $TEST_FILE | jq -r '.terrain.localisation')"
echo -e "${GREEN}✓${NC} Type: $(cat $TEST_FILE | jq -r '.type')"
echo -e "${GREEN}✓${NC} Loyer: $(cat $TEST_FILE | jq -r '.rent') FCFA/an\n"

# Créer le contrat
echo -e "${YELLOW}🚀 Création du contrat sur la blockchain...${NC}"
echo -e "${BLUE}   Endorsement: AFOR + CVGFR${NC}\n"

# Échapper le JSON pour l'inclure dans Args (remplacer " par \")
CONTRAT_ESCAPED=$(echo "$CONTRAT_JSON" | jq -c . | jq -Rs .)

# Créer la commande JSON
INVOKE_JSON=$(jq -n \
  --argjson contrat "$(echo $CONTRAT_JSON)" \
  '{Args: ["creerContrat", ($contrat | tostring)]}')

peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls --cafile ${ORDERER_CA} \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles /home/absolue/my-blockchain/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    -c "$INVOKE_JSON" 2>&1 | tee /tmp/create-contract.log

# Vérifier le résultat
if grep -q "status:200" /tmp/create-contract.log; then
    echo -e "\n${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}✅ CONTRAT CRÉÉ AVEC SUCCÈS !${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}\n"
    
    # Attendre la propagation
    echo -e "${BLUE}⏳ Attente de la propagation (5 secondes)...${NC}"
    sleep 5
    
    # Vérifier la lecture
    echo -e "${YELLOW}🔍 Vérification de la lecture du contrat...${NC}"
    peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${CC_NAME} \
        -c "{\"Args\":[\"lireContrat\",\"${CODE_CONTRAT}\"]}" 2>&1 | tee /tmp/query-contract.log
    
    if grep -q "codeContract" /tmp/query-contract.log; then
        echo -e "\n${GREEN}✅ Contrat lu avec succès depuis la blockchain${NC}"
    fi
else
    echo -e "\n${RED}════════════════════════════════════════════════${NC}"
    echo -e "${RED}❌ ERREUR LORS DE LA CRÉATION${NC}"
    echo -e "${RED}════════════════════════════════════════════════${NC}\n"
    echo -e "${YELLOW}Détails de l'erreur:${NC}"
    grep -E "(Error|message:)" /tmp/create-contract.log | head -5
    exit 1
fi
