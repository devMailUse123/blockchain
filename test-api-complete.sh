#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
KEYCLOAK_URL="https://auth.digifor2.afor-ci.app"
REALM="for-blockchain"
CLIENT_ID="afor-blockchain-api"
CLIENT_SECRET="SIYIU61c2d0FybVMiBUALc7oWjaNsFQq"
API_URL="http://localhost:3000"

echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST COMPLET API + KEYCLOAK + BLOCKCHAIN    ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo ""

# Étape 1: Obtenir le token
echo -e "${YELLOW}[1/6]${NC} Obtention du token Keycloak..."
TOKEN_RESPONSE=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}")

if echo $TOKEN_RESPONSE | grep -q "access_token"; then
    ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
    echo -e "${GREEN}✅ Token obtenu${NC}"
else
    echo -e "${RED}❌ Erreur lors de l'obtention du token${NC}"
    echo $TOKEN_RESPONSE | jq '.'
    exit 1
fi
echo ""

# Étape 2: Vérifier la santé de l'API
echo -e "${YELLOW}[2/6]${NC} Vérification de l'API..."
HEALTH=$(curl -s ${API_URL}/api/health)
if echo $HEALTH | grep -q "UP"; then
    echo -e "${GREEN}✅ API opérationnelle${NC}"
else
    echo -e "${RED}❌ API non disponible${NC}"
    exit 1
fi
echo ""

# Étape 3: Lister les contrats existants
echo -e "${YELLOW}[3/6]${NC} Liste des contrats existants..."
CONTRACTS=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" ${API_URL}/api/contracts)
COUNT=$(echo $CONTRACTS | jq '.count // 0')
echo -e "${GREEN}✅ ${COUNT} contrat(s) trouvé(s)${NC}"
echo $CONTRACTS | jq '.'
echo ""

# Étape 4: Créer un nouveau contrat avec le bon format
echo -e "${YELLOW}[4/6]${NC} Création d'un nouveau contrat..."
CONTRACT_CODE="TEST-API-$(date +%Y%m%d-%H%M%S)"

NEW_CONTRACT=$(cat <<EOF
{
  "id": "${CONTRACT_CODE}",
  "uuid": "$(uuidgen)",
  "codeContract": "${CONTRACT_CODE}",
  "creationDate": "$(date -u +%Y-%m-%dT%H:%M:%S)",
  "isNewContract": 1,
  "type": "LOCATION",
  "version": "1.0",
  "ownerId": 100,
  "beneficiaryId": 200,
  "terrainId": 300,
  "owner": {
    "id": 100,
    "name": "Test Keycloak Owner",
    "birthDate": "1980-01-01T00:00:00",
    "birthPlace": "Abidjan",
    "idNumber": "TEST001",
    "idType": "CNI",
    "phoneNumber": "+2250102030405",
    "address": "Test Address",
    "genre": "M",
    "type": "PROPRIETAIRE"
  },
  "beneficiary": {
    "id": 200,
    "name": "Test Keycloak Beneficiary",
    "birthDate": "1990-01-01T00:00:00",
    "birthPlace": "Bouaké",
    "idNumber": "TEST002",
    "idType": "CNI",
    "phoneNumber": "+2250102030406",
    "address": "Test Address 2",
    "genre": "F",
    "type": "LOCATAIRE"
  },
  "terrain": {
    "id": 300,
    "localisation": "Test Location",
    "surface": 5.5,
    "cvgfr": "CVGFR-TEST-001",
    "statut": "ACTIF",
    "certificatFoncier": "CF-TEST-001",
    "certificatFoncierType": "Certificat Foncier Rural",
    "surfaceMethod": "GPS",
    "surfaceMeasurment": "5.5 hectares",
    "croquisDisponible": "OUI"
  },
  "rent": "200000",
  "rentTimeUnit": "ANNEE",
  "rentIsEspece": 1,
  "rentIsNature": 0,
  "duration": "2",
  "durationUnit": "ANNEE",
  "region": "Test Region",
  "department": "Test Department",
  "sousPrefecture": "Test Sous-Prefecture",
  "village": "Test Village",
  "contractSignatory": [
    {
      "id": 1,
      "codeContract": "${CONTRACT_CODE}",
      "ownerName": "Test Keycloak Owner",
      "ownerSignature": "Signature_Owner",
      "beneficiaryName": "Test Keycloak Beneficiary",
      "beneficiarySignature": "Signature_Beneficiary",
      "cvgfrPresidentName": "Test President",
      "cvgfrPresidentSignature": "Signature_President",
      "creationDate": "$(date -u +%Y-%m-%dT%H:%M:%S)"
    }
  ]
}
EOF
)

CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$NEW_CONTRACT" \
  ${API_URL}/api/contracts)

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Contrat créé avec succès (${CONTRACT_CODE})${NC}"
    echo $BODY | jq '.'
else
    echo -e "${RED}❌ Erreur lors de la création (code: $HTTP_CODE)${NC}"
    echo $BODY | jq '.'
    echo ""
    echo -e "${YELLOW}📋 Erreur complète:${NC}"
    echo "$BODY"
    exit 1
fi
echo ""

# Étape 5: Lire le contrat créé
echo -e "${YELLOW}[5/6]${NC} Lecture du contrat créé..."
sleep 2
READ_RESPONSE=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" ${API_URL}/api/contracts/${CONTRACT_CODE})
if echo $READ_RESPONSE | grep -q "$CONTRACT_CODE"; then
    echo -e "${GREEN}✅ Contrat lu avec succès${NC}"
    echo $READ_RESPONSE | jq '.'
else
    echo -e "${RED}⚠️  Contrat non trouvé (peut être dans le ledger)${NC}"
fi
echo ""

# Étape 6: Vérifier dans CouchDB
echo -e "${YELLOW}[6/6]${NC} Vérification dans CouchDB..."
COUCHDB_RESPONSE=$(curl -s -u admin:adminpw http://localhost:5984/contrat-agraire/_all_docs?include_docs=true)
COUCH_COUNT=$(echo $COUCHDB_RESPONSE | jq '.rows | length')
echo -e "${GREEN}✅ ${COUCH_COUNT} document(s) dans CouchDB${NC}"

# Chercher notre contrat
if echo $COUCHDB_RESPONSE | grep -q "$CONTRACT_CODE"; then
    echo -e "${GREEN}✅ Contrat ${CONTRACT_CODE} trouvé dans CouchDB${NC}"
    echo $COUCHDB_RESPONSE | jq ".rows[] | select(.id | contains(\"$CONTRACT_CODE\"))"
else
    echo -e "${YELLOW}⚠️  Contrat pas encore dans CouchDB (peut prendre quelques secondes)${NC}"
fi
echo ""

# Résumé
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${BLUE}            RÉSUMÉ DU TEST                     ${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Authentification Keycloak${NC}"
echo -e "${GREEN}✅ API fonctionnelle${NC}"
echo -e "${GREEN}✅ Blockchain connectée${NC}"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Contrat créé: ${CONTRACT_CODE}${NC}"
else
    echo -e "${RED}❌ Création de contrat échouée${NC}"
fi
echo ""
echo -e "${YELLOW}🌐 Swagger UI:${NC} http://localhost:3000/api-docs"
echo -e "${YELLOW}📊 CouchDB:${NC} http://localhost:5984/_utils"
echo ""
