#!/bin/bash

# Script pour créer un contrat directement avec peer chaincode invoke
# Utilise les certificats depuis l'hôte

set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Création d'un contrat sur la blockchain ===${NC}"

# Variables
CHANNEL_NAME="contrat-agraire"
CHAINCODE_NAME="foncier"
ORGS_PATH="/home/absolue/my-blockchain/network/organizations"

# Générer les données
UUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTRACT_ID="CONTRAT-$(date +%Y%m%d)-$(printf '%03d' $((RANDOM % 1000)))"

echo -e "${YELLOW}ID: ${CONTRACT_ID}${NC}"
echo -e "${YELLOW}UUID: ${UUID}${NC}"

# JSON du contrat (échapper correctement les guillemets)
CONTRACT_JSON="{\"id\":\"${CONTRACT_ID}\",\"uuid\":\"${UUID}\",\"numeroContrat\":\"CA-2025-AFOR-001\",\"dateContrat\":\"${TIMESTAMP}\",\"typeContrat\":\"BAIL_EMPHYTEOTIQUE\",\"creationDate\":\"${TIMESTAMP}\",\"region\":\"Bélier\",\"prefecture\":\"Yamoussoukro\",\"sousPrefecture\":\"Attiégouakro\",\"village\":\"Koffikro\",\"owner\":{\"name\":\"KOUAME Jean-Baptiste\",\"dateNaissance\":\"1975-03-15\",\"lieuNaissance\":\"Yamoussoukro\",\"numeroIdentite\":\"CI-YAM-1975-001234\",\"telephone\":\"+225 07 12 34 56 78\",\"adresse\":\"Yamoussoukro, Quartier Commerce\"},\"beneficiary\":{\"name\":\"KONAN Marie-Louise\",\"dateNaissance\":\"1985-07-22\",\"lieuNaissance\":\"Abidjan\",\"numeroIdentite\":\"CI-ABJ-1985-005678\",\"telephone\":\"+225 05 98 76 54 32\",\"adresse\":\"Abidjan, Cocody\"},\"parcellesInfos\":[{\"superficie\":5.0,\"unite\":\"hectare\",\"limites\":\"Nord: Route principale, Sud: Rivière Bandama\",\"occupation\":\"CULTURE\",\"typeCulture\":\"CACAO\",\"natureSol\":\"Terre argileuse fertile\"}],\"duree\":25,\"dateDebut\":\"${TIMESTAMP}\",\"montantLoyer\":500000,\"devise\":\"XOF\",\"modalitePaiement\":\"ANNUEL\",\"statut\":\"ACTIF\",\"validationCVGFR\":{\"valide\":true,\"dateValidation\":\"${TIMESTAMP}\",\"validateur\":\"BAMBA Mamadou\"},\"validationAFOR\":{\"valide\":true,\"dateValidation\":\"${TIMESTAMP}\",\"agentId\":\"AFOR-YAM-2025-001\",\"agentNom\":\"OUATTARA Fatou\"}}"

echo -e "${YELLOW}Envoi de la transaction...${NC}"

# Configuration de l'environnement pour peer CLI
export CORE_PEER_TLS_ENABLED=true
export CORE_PEER_LOCALMSPID="AFOROrg"
export CORE_PEER_TLS_ROOTCERT_FILE="${ORGS_PATH}/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
export CORE_PEER_MSPCONFIGPATH="${ORGS_PATH}/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
export CORE_PEER_ADDRESS="localhost:7051"

# Créer le contrat
peer chaincode invoke \
    -o localhost:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls \
    --cafile "${ORGS_PATH}/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem" \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses localhost:7051 \
    --tlsRootCertFiles "${ORGS_PATH}/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt" \
    --peerAddresses localhost:8051 \
    --tlsRootCertFiles "${ORGS_PATH}/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt" \
    -c "{\"function\":\"creerContrat\",\"Args\":[\"${CONTRACT_JSON}\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contrat créé avec succès !${NC}"
    echo -e "${GREEN}ID: ${CONTRACT_ID}${NC}"
    
    sleep 2
    
    # Lire le contrat
    echo -e "${YELLOW}Vérification du contrat...${NC}"
    peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${CHAINCODE_NAME} \
        -c "{\"function\":\"lireContrat\",\"Args\":[\"${CONTRACT_ID}\"]}" | jq .
    
    echo -e "${GREEN}=== Contrat créé et vérifié ===${NC}"
else
    echo -e "${RED}✗ Erreur lors de la création${NC}"
    exit 1
fi
