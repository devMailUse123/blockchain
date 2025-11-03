#!/bin/bash

# Script pour créer un contrat via l'API REST
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== Création d'un contrat via l'API ===${NC}"

# Générer les données
UUID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
CONTRACT_ID="CONTRAT-$(date +%Y%m%d)-$(printf '%03d' $((RANDOM % 1000)))"

echo -e "${YELLOW}ID: ${CONTRACT_ID}${NC}"
echo -e "${YELLOW}UUID: ${UUID}${NC}"
echo -e "${YELLOW}Date: ${TIMESTAMP}${NC}"

# JSON du contrat (format minimal selon le modèle Java)
CONTRACT_JSON=$(cat <<EOF
{
  "id": "${CONTRACT_ID}",
  "uuid": "${UUID}",
  "creationDate": "${TIMESTAMP}",
  "codeContract": "CA-2025-AFOR-$(date +%H%M%S)",
  "type": "BAIL_EMPHYTEOTIQUE",
  "village": "Koffikro",
  "sousPrefecture": "Attiégouakro",
  "department": "Yamoussoukro",
  "ownerId": 1,
  "owner": {
    "name": "KOUAME Jean-Baptiste",
    "birthDate": "1975-03-15T00:00:00",
    "birthPlace": "Yamoussoukro",
    "idNumber": "CI-YAM-1975-001234",
    "phoneNumber": "+225 07 12 34 56 78",
    "address": "Yamoussoukro, Quartier Commerce",
    "type": "PROPRIETAIRE"
  },
  "beneficiaryId": 2,
  "beneficiary": {
    "name": "KONAN Marie-Louise",
    "birthDate": "1985-07-22T00:00:00",
    "birthPlace": "Abidjan",
    "idNumber": "CI-ABJ-1985-005678",
    "phoneNumber": "+225 05 98 76 54 32",
    "address": "Abidjan, Cocody",
    "type": "EXPLOITANT"
  },
  "terrainId": 1,
  "duration": 25,
  "durationUnit": "ANNEE",
  "rent": 500000,
  "rentTimeUnit": "PAR_AN",
  "rentPeriod": "ANNUEL"
}
EOF
)

echo -e "${YELLOW}Envoi à l'API...${NC}"

# Démarrer l'API en arrière-plan si elle n'est pas déjà lancée
if ! curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo -e "${YELLOW}Démarrage de l'API...${NC}"
    cd api && node src/server.js > /dev/null 2>&1 &
    API_PID=$!
    sleep 3
else
    echo -e "${GREEN}✓ API déjà active${NC}"
fi

# Créer le contrat
RESPONSE=$(curl -s -X POST http://localhost:3000/api/contracts \
    -H "Content-Type: application/json" \
    -d "${CONTRACT_JSON}")

# Vérifier le résultat
if echo "$RESPONSE" | jq -e '.success' > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Contrat créé avec succès !${NC}"
    echo ""
    echo -e "${GREEN}Détails:${NC}"
    echo "$RESPONSE" | jq .
    
    # Lire le contrat pour vérifier
    echo ""
    echo -e "${YELLOW}Vérification sur la blockchain...${NC}"
    sleep 2
    curl -s "http://localhost:3000/api/contracts/${CONTRACT_ID}" | jq .
    
    echo ""
    echo -e "${GREEN}=== Contrat créé et vérifié ===${NC}"
else
    echo -e "${RED}✗ Erreur lors de la création${NC}"
    echo "$RESPONSE" | jq .
    exit 1
fi
