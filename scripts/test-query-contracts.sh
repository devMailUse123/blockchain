#!/bin/bash

# Script de test - Interrogation des contrats
set -e

# Configuration Fabric
export PATH=/home/absolue/fabric-samples/bin:$PATH
export FABRIC_CFG_PATH=/home/absolue/fabric-samples/config
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_ADDRESS=localhost:7051
export CORE_PEER_TLS_ROOTCERT_FILE=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
export CORE_PEER_MSPCONFIGPATH=/home/absolue/my-blockchain/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp

CHANNEL_NAME="contrat-agraire"
CC_NAME="foncier"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  TEST - INTERROGATION DES CONTRATS             ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════${NC}\n"

# Fonction pour interroger un contrat
query_contract() {
    local CODE=$1
    echo -e "${BLUE}🔍 Recherche du contrat: ${CODE}${NC}"
    
    RESULT=$(peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${CC_NAME} \
        -c "{\"Args\":[\"lireContrat\",\"${CODE}\"]}" 2>&1)
    
    if echo "$RESULT" | grep -q "codeContract"; then
        echo -e "${GREEN}✅ Contrat trouvé${NC}\n"
        echo "$RESULT" | jq '.' 2>/dev/null || echo "$RESULT"
        echo ""
        return 0
    else
        echo -e "${RED}❌ Contrat non trouvé${NC}"
        echo "$RESULT" | grep -E "(Error|message:)" | head -2
        echo ""
        return 1
    fi
}

# Fonction pour lister tous les contrats
list_all_contracts() {
    echo -e "${BLUE}📋 Liste de tous les contrats:${NC}"
    
    RESULT=$(peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${CC_NAME} \
        -c '{"Args":["listerContrats"]}' 2>&1)
    
    if echo "$RESULT" | grep -q "\["; then
        echo -e "${GREEN}✅ Contrats trouvés${NC}\n"
        echo "$RESULT" | jq '.' 2>/dev/null || echo "$RESULT"
        echo ""
        
        # Compter les contrats
        COUNT=$(echo "$RESULT" | jq '. | length' 2>/dev/null || echo "?")
        echo -e "${GREEN}📊 Total: ${COUNT} contrat(s)${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Aucun contrat ou erreur${NC}"
        echo "$RESULT" | grep -E "(Error|message:)" | head -2
        echo ""
    fi
}

# Test 1: Chercher le contrat de test
echo -e "${YELLOW}═══ Test 1: Contrat de test ═══${NC}\n"
query_contract "TEST-2024-001"

# Test 2: Lister tous les contrats
echo -e "${YELLOW}═══ Test 2: Liste complète ═══${NC}\n"
list_all_contracts

# Test 3: Recherche par bailleur
echo -e "${YELLOW}═══ Test 3: Recherche par bailleur ═══${NC}\n"
echo -e "${BLUE}🔍 Recherche des contrats du bailleur: KOUAME${NC}"

RESULT=$(peer chaincode query \
    -C ${CHANNEL_NAME} \
    -n ${CC_NAME} \
    -c '{"Args":["rechercherParBailleur","KOUAME"]}' 2>&1)

if echo "$RESULT" | grep -q "\["; then
    echo -e "${GREEN}✅ Contrats trouvés${NC}\n"
    echo "$RESULT" | jq '.' 2>/dev/null || echo "$RESULT"
    echo ""
else
    echo -e "${YELLOW}⚠️  Aucun contrat trouvé ou méthode non disponible${NC}\n"
fi

# Test 4: Contrat inexistant
echo -e "${YELLOW}═══ Test 4: Contrat inexistant (test négatif) ═══${NC}\n"
query_contract "INEXISTANT-999"

echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Tests d'interrogation terminés${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
