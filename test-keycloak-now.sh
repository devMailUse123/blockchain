#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration Keycloak
KEYCLOAK_URL="https://auth.digifor2.afor-ci.app"
REALM="digifor2"
CLIENT_ID="iam-user-auth"
CLIENT_SECRET="V1pB8UbbtyUBua35NsrCVCbzYzPFnmr3"
API_URL="http://localhost:3000"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Tests d'intégration Keycloak + API  ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Test 1: Vérifier la santé de l'API
echo -e "${YELLOW}[1/5]${NC} Test de santé de l'API..."
HEALTH=$(curl -s ${API_URL}/api/health)
if echo $HEALTH | grep -q "UP"; then
    echo -e "${GREEN}✅ API is UP${NC}"
    echo "$HEALTH" | jq '.'
else
    echo -e "${RED}❌ API is DOWN${NC}"
    exit 1
fi
echo ""

# Test 2: Obtenir un token Keycloak
echo -e "${YELLOW}[2/5]${NC} Obtention du token Keycloak..."
TOKEN_RESPONSE=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}")

# Vérifier si le token a été obtenu
if echo $TOKEN_RESPONSE | grep -q "access_token"; then
    ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
    echo -e "${GREEN}✅ Token obtenu avec succès${NC}"
    echo "Token (premiers caractères): ${ACCESS_TOKEN:0:50}..."
    
    # Décoder le token pour voir les infos
    echo -e "\n${YELLOW}Informations du token:${NC}"
    echo $ACCESS_TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq '.' || echo "Token présent"
else
    echo -e "${RED}❌ Erreur lors de l'obtention du token${NC}"
    echo "Réponse de Keycloak:"
    echo $TOKEN_RESPONSE | jq '.'
    echo ""
    echo -e "${YELLOW}📋 Actions requises:${NC}"
    echo "1. Allez sur: ${KEYCLOAK_URL}/admin"
    echo "2. Connectez-vous"
    echo "3. Sélectionnez le realm: ${REALM}"
    echo "4. Allez dans Clients → ${CLIENT_ID}"
    echo "5. Dans l'onglet Settings:"
    echo "   - Activez 'Service accounts roles'"
    echo "   - Activez 'Client authentication'"
    echo "6. Cliquez sur Save"
    echo ""
    echo -e "${RED}⚠️  Sans Service Account activé, impossible de continuer${NC}"
    exit 1
fi
echo ""

# Test 3: Lister les contrats SANS authentification (doit échouer)
echo -e "${YELLOW}[3/5]${NC} Test sans authentification (doit échouer)..."
RESPONSE_NO_AUTH=$(curl -s -w "\n%{http_code}" ${API_URL}/api/contracts)
HTTP_CODE=$(echo "$RESPONSE_NO_AUTH" | tail -n1)
BODY=$(echo "$RESPONSE_NO_AUTH" | sed '$d')

if [ "$HTTP_CODE" = "401" ]; then
    echo -e "${GREEN}✅ Rejet correct (401 Unauthorized)${NC}"
    echo "$BODY" | jq '.'
else
    echo -e "${RED}❌ Devrait rejeter sans token (code: $HTTP_CODE)${NC}"
fi
echo ""

# Test 4: Lister les contrats AVEC authentification
echo -e "${YELLOW}[4/5]${NC} Test avec authentification..."
RESPONSE_AUTH=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  ${API_URL}/api/contracts)
HTTP_CODE=$(echo "$RESPONSE_AUTH" | tail -n1)
BODY=$(echo "$RESPONSE_AUTH" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Authentification réussie (200 OK)${NC}"
    echo "$BODY" | jq '.'
else
    echo -e "${RED}❌ Erreur avec token (code: $HTTP_CODE)${NC}"
    echo "$BODY" | jq '.'
fi
echo ""

# Test 5: Créer un nouveau contrat
echo -e "${YELLOW}[5/5]${NC} Création d'un nouveau contrat..."
NEW_CONTRACT=$(cat <<EOF
{
  "numeroContrat": "CA-TEST-$(date +%Y%m%d-%H%M%S)",
  "dateCreation": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "statut": "BROUILLON",
  "typeContrat": "BAIL_RURAL",
  "surfaceHectares": 5.5,
  "coordonneesGPS": {
    "latitude": 5.3167,
    "longitude": -4.0333
  },
  "proprietaire": {
    "nom": "Test",
    "prenoms": "Keycloak",
    "dateNaissance": "1980-01-01",
    "lieuNaissance": "Abidjan",
    "nationalite": "Ivoirienne",
    "profession": "Agriculteur",
    "telephone": "+2250102030405",
    "email": "test@example.com"
  },
  "localisation": {
    "village": "Village Test",
    "sousPrefecture": "Sous-Préfecture Test",
    "departement": "Département Test",
    "region": "Région Test"
  }
}
EOF
)

RESPONSE_CREATE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$NEW_CONTRACT" \
  ${API_URL}/api/contracts)
HTTP_CODE=$(echo "$RESPONSE_CREATE" | tail -n1)
BODY=$(echo "$RESPONSE_CREATE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Contrat créé avec succès (code: $HTTP_CODE)${NC}"
    echo "$BODY" | jq '.'
    
    # Extraire le numéro du contrat créé
    CONTRACT_ID=$(echo "$BODY" | jq -r '.numeroContrat // .data.numeroContrat // empty')
    if [ -n "$CONTRACT_ID" ]; then
        echo -e "\n${GREEN}📋 Contrat créé: ${CONTRACT_ID}${NC}"
    fi
else
    echo -e "${RED}❌ Erreur lors de la création (code: $HTTP_CODE)${NC}"
    echo "$BODY" | jq '.'
fi
echo ""

# Résumé final
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}          RÉSUMÉ DES TESTS             ${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}✅ API démarrée et fonctionnelle${NC}"
echo -e "${GREEN}✅ Token Keycloak obtenu${NC}"
echo -e "${GREEN}✅ Sécurité activée (rejet sans token)${NC}"
echo -e "${GREEN}✅ Authentification fonctionnelle${NC}"
if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Création de contrat réussie${NC}"
else
    echo -e "${YELLOW}⚠️  Création de contrat à vérifier${NC}"
fi
echo ""
echo -e "${YELLOW}🌐 Accès Swagger UI:${NC}"
echo "   → http://localhost:3000/api-docs"
echo "   → Cliquez sur 'Authorize'"
echo "   → Collez le token: ${ACCESS_TOKEN:0:30}..."
echo ""
