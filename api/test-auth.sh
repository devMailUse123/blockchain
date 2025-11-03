#!/bin/bash

# Script de test de l'authentification Keycloak
# Usage: ./test-auth.sh [keycloak_url] [realm] [client_id] [client_secret] [username] [password]

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Paramètres par défaut
KEYCLOAK_URL="${1:-http://localhost:8080/auth}"
REALM="${2:-afor-realm}"
CLIENT_ID="${3:-afor-api}"
CLIENT_SECRET="${4:-your-client-secret}"
USERNAME="${5:-admin@afor.ci}"
PASSWORD="${6:-admin123}"
API_URL="${7:-http://localhost:3000}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Test d'Authentification Keycloak + API Blockchain      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# 1. Vérifier que Keycloak est accessible
echo -e "${YELLOW}[1/5] Vérification de Keycloak...${NC}"
if curl -s -f "${KEYCLOAK_URL}" > /dev/null; then
    echo -e "${GREEN}✅ Keycloak accessible${NC}\n"
else
    echo -e "${RED}❌ Keycloak inaccessible à ${KEYCLOAK_URL}${NC}"
    echo -e "${YELLOW}💡 Assurez-vous que Keycloak est démarré${NC}\n"
    exit 1
fi

# 2. Obtenir un token JWT
echo -e "${YELLOW}[2/5] Obtention du token JWT...${NC}"
TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}")

if echo "$TOKEN_RESPONSE" | grep -q "access_token"; then
    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"\(.*\)"/\1/')
    EXPIRES_IN=$(echo "$TOKEN_RESPONSE" | grep -o '"expires_in":[0-9]*' | sed 's/"expires_in"://')
    echo -e "${GREEN}✅ Token obtenu avec succès${NC}"
    echo -e "   Expire dans: ${EXPIRES_IN}s"
    echo -e "   Token (100 premiers caractères): ${ACCESS_TOKEN:0:100}...${NC}\n"
else
    echo -e "${RED}❌ Échec de l'obtention du token${NC}"
    echo -e "${YELLOW}Réponse: ${TOKEN_RESPONSE}${NC}\n"
    exit 1
fi

# 3. Vérifier que l'API est accessible
echo -e "${YELLOW}[3/5] Vérification de l'API Blockchain...${NC}"
if curl -s -f "${API_URL}/api/health" > /dev/null; then
    echo -e "${GREEN}✅ API accessible${NC}\n"
else
    echo -e "${RED}❌ API inaccessible à ${API_URL}${NC}"
    echo -e "${YELLOW}💡 Démarrez l'API avec: npm start${NC}\n"
    exit 1
fi

# 4. Tester un endpoint public (sans authentification)
echo -e "${YELLOW}[4/5] Test endpoint public /api/health...${NC}"
HEALTH_RESPONSE=$(curl -s "${API_URL}/api/health")
echo -e "${GREEN}✅ Endpoint public accessible${NC}"
echo -e "   Réponse: ${HEALTH_RESPONSE}\n"

# 5. Tester un endpoint protégé (avec authentification)
echo -e "${YELLOW}[5/5] Test endpoint protégé /api/contracts...${NC}"

# Test sans token (doit échouer)
echo -e "${YELLOW}   Test sans token...${NC}"
NO_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/api/contracts")
HTTP_CODE=$(echo "$NO_TOKEN_RESPONSE" | tail -n1)
BODY=$(echo "$NO_TOKEN_RESPONSE" | sed \$d)

if [ "$HTTP_CODE" == "401" ]; then
    echo -e "${GREEN}   ✅ Rejeté sans token (401 attendu)${NC}"
    echo -e "      Réponse: ${BODY}\n"
else
    echo -e "${RED}   ⚠️  Code HTTP inattendu: $HTTP_CODE (401 attendu)${NC}\n"
fi

# Test avec token (doit réussir)
echo -e "${YELLOW}   Test avec token JWT...${NC}"
WITH_TOKEN_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${API_URL}/api/contracts")

HTTP_CODE=$(echo "$WITH_TOKEN_RESPONSE" | tail -n1)
BODY=$(echo "$WITH_TOKEN_RESPONSE" | sed \$d)

if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}   ✅ Authentification réussie (200)${NC}"
    echo -e "      Réponse: ${BODY}\n"
else
    echo -e "${RED}   ❌ Échec de l'authentification (code: $HTTP_CODE)${NC}"
    echo -e "      Réponse: ${BODY}\n"
fi

# Résumé
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}✅ Tests terminés${BLUE}                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}📝 Pour tester avec Swagger UI:${NC}"
echo -e "   1. Ouvrir: ${API_URL}/api-docs"
echo -e "   2. Cliquer sur 'Authorize' 🔓"
echo -e "   3. Entrer: Bearer ${ACCESS_TOKEN:0:50}..."
echo -e "   4. Tester les endpoints\n"

echo -e "${YELLOW}📝 Pour utiliser dans votre backend Java:${NC}"
echo -e "   String token = \"${ACCESS_TOKEN:0:50}...\";"
echo -e "   HttpHeaders headers = new HttpHeaders();"
echo -e "   headers.set(\"Authorization\", \"Bearer \" + token);\n"
