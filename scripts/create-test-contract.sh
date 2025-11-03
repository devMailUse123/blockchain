#!/bin/bash

# Script pour créer un contrat de test via le CLI Fabric
# Usage: ./create-test-contract.sh

set -e

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Création d'un contrat de test ===${NC}"

# Variables
CHANNEL_NAME="contrat-agraire"
CHAINCODE_NAME="foncier"
ORG_NAME="afor"

# Générer UUID et dates
UUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTRACT_ID="CONTRAT-$(date +%Y%m%d)-001"

echo -e "${YELLOW}ID du contrat: ${CONTRACT_ID}${NC}"
echo -e "${YELLOW}UUID: ${UUID}${NC}"

# Créer le JSON du contrat
CONTRACT_JSON=$(cat <<EOF
{
  "id": "${CONTRACT_ID}",
  "uuid": "${UUID}",
  "numeroContrat": "CA-2025-AFOR-001",
  "dateContrat": "${TIMESTAMP}",
  "typeContrat": "BAIL_EMPHYTEOTIQUE",
  "creationDate": "${TIMESTAMP}",
  "region": "Bélier",
  "prefecture": "Yamoussoukro",
  "sousPrefecture": "Attiégouakro",
  "village": "Koffikro",
  "owner": {
    "name": "KOUAME Jean-Baptiste",
    "dateNaissance": "1975-03-15",
    "lieuNaissance": "Yamoussoukro",
    "numeroIdentite": "CI-YAM-1975-001234",
    "telephone": "+225 07 12 34 56 78",
    "adresse": "Yamoussoukro, Quartier Commerce"
  },
  "beneficiary": {
    "name": "KONAN Marie-Louise",
    "dateNaissance": "1985-07-22",
    "lieuNaissance": "Abidjan",
    "numeroIdentite": "CI-ABJ-1985-005678",
    "telephone": "+225 05 98 76 54 32",
    "adresse": "Abidjan, Cocody"
  },
  "parcellesInfos": [
    {
      "superficie": 5.0,
      "unite": "hectare",
      "limites": "Nord: Route principale, Sud: Rivière Bandama, Est: Parcelle KONAN, Ouest: Forêt classée",
      "occupation": "CULTURE",
      "typeCulture": "CACAO",
      "natureSol": "Terre argileuse fertile"
    }
  ],
  "duree": 25,
  "dateDebut": "${TIMESTAMP}",
  "montantLoyer": 500000,
  "devise": "XOF",
  "modalitePaiement": "ANNUEL",
  "statut": "ACTIF",
  "validationCVGFR": {
    "valide": true,
    "dateValidation": "${TIMESTAMP}",
    "validateur": "BAMBA Mamadou - Président CVGFR Koffikro",
    "commentaire": "Contrat validé par le comité villageois"
  },
  "validationAFOR": {
    "valide": true,
    "dateValidation": "${TIMESTAMP}",
    "agentId": "AFOR-YAM-2025-001",
    "agentNom": "OUATTARA Fatou",
    "commentaire": "Conformité vérifiée, documents en règle"
  },
  "conditionsParticulieres": [
    "Le bénéficiaire s'engage à maintenir les cultures de cacao",
    "Respect des normes environnementales en vigueur",
    "Participation aux activités communautaires du village"
  ]
}
EOF
)

echo -e "${GREEN}Contrat JSON créé${NC}"

# Fonction pour exécuter une commande dans le conteneur CLI
docker_exec() {
    docker exec cli "$@"
}

# Vérifier que le réseau est actif
echo -e "${YELLOW}Vérification du réseau...${NC}"
if ! docker ps | grep -q "cli"; then
    echo -e "${RED}Erreur: Le conteneur CLI n'est pas actif${NC}"
    echo -e "${YELLOW}Démarrez le réseau avec: make network-up${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Réseau actif${NC}"

# Configuration de l'environnement pour AFOR
echo -e "${YELLOW}Configuration de l'organisation AFOR...${NC}"

# Créer le contrat
echo -e "${YELLOW}Création du contrat sur la blockchain...${NC}"

docker exec \
    -e CORE_PEER_TLS_ENABLED=true \
    -e CORE_PEER_LOCALMSPID=AFOROrg \
    -e CORE_PEER_TLS_ROOTCERT_FILE=/opt/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    -e CORE_PEER_MSPCONFIGPATH=/opt/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp \
    -e CORE_PEER_ADDRESS=peer0.afor.foncier.ci:7051 \
    cli peer chaincode invoke \
    -o orderer.foncier.ci:7050 \
    --ordererTLSHostnameOverride orderer.foncier.ci \
    --tls --cafile /opt/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem \
    -C ${CHANNEL_NAME} \
    -n ${CHAINCODE_NAME} \
    --peerAddresses peer0.afor.foncier.ci:7051 \
    --tlsRootCertFiles /opt/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses peer0.cvgfr.foncier.ci:8051 \
    --tlsRootCertFiles /opt/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    -c "{\"function\":\"creerContrat\",\"Args\":[\"${CONTRACT_JSON}\"]}"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Contrat créé avec succès !${NC}"
    echo -e "${GREEN}ID: ${CONTRACT_ID}${NC}"
    
    # Attendre un peu pour que la transaction soit validée
    echo -e "${YELLOW}Attente de la validation (3 secondes)...${NC}"
    sleep 3
    
    # Lire le contrat créé
    echo -e "${YELLOW}Lecture du contrat créé...${NC}"
    docker_exec peer chaincode query \
        -C ${CHANNEL_NAME} \
        -n ${CHAINCODE_NAME} \
        -c "{\"function\":\"lireContrat\",\"Args\":[\"${CONTRACT_ID}\"]}"
    
    echo ""
    echo -e "${GREEN}=== Contrat créé et vérifié avec succès ===${NC}"
else
    echo -e "${RED}✗ Erreur lors de la création du contrat${NC}"
    exit 1
fi
