#!/bin/bash

# Script de test Keycloak pour AFOR Blockchain
# Ce script teste l'authentification complète avec votre instance Keycloak

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Test Authentification Keycloak AFOR Blockchain      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Configuration (extraite de votre .env)
KEYCLOAK_URL="https://auth.digifor2.afor-ci.app"
REALM="for-blockchain"
CLIENT_ID="afor-blockchain-api"
CLIENT_SECRET="SIYIU61c2d0FybVMiBUALc7oWjaNsFQq"
API_URL="http://localhost:3000"

# Demander les credentials utilisateur
echo -e "${YELLOW}📋 Credentials utilisateur Keycloak${NC}"
read -p "Username (ex: admin@afor.ci): " USERNAME
read -sp "Password: " PASSWORD
echo ""
echo ""

# 1. Vérifier Keycloak
echo -e "${YELLOW}[1/6] Vérification de Keycloak...${NC}"
REALM_INFO=$(curl -s "${KEYCLOAK_URL}/realms/${REALM}/.well-known/openid-configuration")
if echo "$REALM_INFO" | grep -q "issuer"; then
    ISSUER=$(echo "$REALM_INFO" | jq -r '.issuer')
    echo -e "${GREEN}✅ Keycloak accessible${NC}"
    echo -e "   Issuer: ${ISSUER}${NC}\n"
else
    echo -e "${RED}❌ Keycloak inaccessible${NC}\n"
    exit 1
fi

# 2. Obtenir un token avec client_credentials (pour service-to-service)
echo -e "${YELLOW}[2/6] Test avec Client Credentials (service-to-service)...${NC}"
CLIENT_TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}")

if echo "$CLIENT_TOKEN_RESPONSE" | grep -q "access_token"; then
    CLIENT_TOKEN=$(echo "$CLIENT_TOKEN_RESPONSE" | jq -r '.access_token')
    echo -e "${GREEN}✅ Token client_credentials obtenu${NC}"
    echo -e "   Token (50 premiers car.): ${CLIENT_TOKEN:0:50}...${NC}\n"
else
    echo -e "${YELLOW}⚠️  Client credentials non disponible (normal si non configuré)${NC}"
    echo -e "   Erreur: $(echo "$CLIENT_TOKEN_RESPONSE" | jq -r '.error_description // .error')${NC}\n"
fi

# 3. Obtenir un token avec password (pour utilisateur)
echo -e "${YELLOW}[3/6] Test avec Password Grant (utilisateur)...${NC}"
USER_TOKEN_RESPONSE=$(curl -s -X POST "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "username=${USERNAME}" \
  -d "password=${PASSWORD}")

if echo "$USER_TOKEN_RESPONSE" | grep -q "access_token"; then
    ACCESS_TOKEN=$(echo "$USER_TOKEN_RESPONSE" | jq -r '.access_token')
    REFRESH_TOKEN=$(echo "$USER_TOKEN_RESPONSE" | jq -r '.refresh_token')
    EXPIRES_IN=$(echo "$USER_TOKEN_RESPONSE" | jq -r '.expires_in')
    
    echo -e "${GREEN}✅ Token utilisateur obtenu avec succès${NC}"
    echo -e "   Expire dans: ${EXPIRES_IN}s${NC}"
    echo -e "   Token (50 premiers car.): ${ACCESS_TOKEN:0:50}...${NC}"
    
    # Décoder le token pour voir son contenu
    TOKEN_PAYLOAD=$(echo "$ACCESS_TOKEN" | cut -d'.' -f2 | base64 -d 2>/dev/null || echo "{}")
    if [ "$TOKEN_PAYLOAD" != "{}" ]; then
        echo -e "\n${BLUE}📊 Contenu du token:${NC}"
        echo "$TOKEN_PAYLOAD" | jq '{
            username: .preferred_username,
            email: .email,
            name: .name,
            roles: .realm_access.roles,
            organization: .organization,
            exp: .exp,
            iat: .iat
        }' 2>/dev/null || echo "   (impossible de décoder)"
    fi
    echo ""
else
    echo -e "${RED}❌ Échec de l'obtention du token utilisateur${NC}"
    echo -e "   Erreur: $(echo "$USER_TOKEN_RESPONSE" | jq -r '.error_description // .error')${NC}\n"
    exit 1
fi

# 4. Vérifier l'API
echo -e "${YELLOW}[4/6] Vérification de l'API Blockchain...${NC}"
HEALTH=$(curl -s "${API_URL}/api/health")
if echo "$HEALTH" | grep -q "status"; then
    echo -e "${GREEN}✅ API accessible${NC}"
    echo "$HEALTH" | jq '.' 2>/dev/null || echo "$HEALTH"
    echo ""
else
    echo -e "${RED}❌ API inaccessible${NC}\n"
    exit 1
fi

# 5. Tester endpoint protégé SANS token
echo -e "${YELLOW}[5/6] Test endpoint protégé SANS token...${NC}"
NO_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" "${API_URL}/api/contracts")
NO_AUTH_CODE=$(echo "$NO_AUTH_RESPONSE" | tail -n1)
NO_AUTH_BODY=$(echo "$NO_AUTH_RESPONSE" | sed \$d)

if [ "$NO_AUTH_CODE" == "401" ]; then
    echo -e "${GREEN}✅ Accès refusé sans token (401 - comportement attendu)${NC}"
    echo "$NO_AUTH_BODY" | jq '.' 2>/dev/null || echo "$NO_AUTH_BODY"
    echo ""
else
    echo -e "${YELLOW}⚠️  Code HTTP: $NO_AUTH_CODE (401 attendu)${NC}\n"
fi

# 6. Tester endpoint protégé AVEC token
echo -e "${YELLOW}[6/6] Test endpoint protégé AVEC token...${NC}"
WITH_AUTH_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  "${API_URL}/api/contracts")

WITH_AUTH_CODE=$(echo "$WITH_AUTH_RESPONSE" | tail -n1)
WITH_AUTH_BODY=$(echo "$WITH_AUTH_RESPONSE" | sed \$d)

if [ "$WITH_AUTH_CODE" == "200" ]; then
    echo -e "${GREEN}✅ Authentification réussie (200)${NC}"
    echo -e "${BLUE}📋 Contrats sur la blockchain:${NC}"
    echo "$WITH_AUTH_BODY" | jq '.' 2>/dev/null || echo "$WITH_AUTH_BODY"
    echo ""
else
    echo -e "${RED}❌ Échec (code: $WITH_AUTH_CODE)${NC}"
    echo "$WITH_AUTH_BODY" | jq '.' 2>/dev/null || echo "$WITH_AUTH_BODY"
    echo ""
fi

# Résumé
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  ${GREEN}✅ Tests terminés${BLUE}                                       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

echo -e "${YELLOW}🔑 Votre token JWT (à utiliser dans vos requêtes):${NC}"
echo -e "${GREEN}${ACCESS_TOKEN}${NC}\n"

echo -e "${YELLOW}📝 Pour l'utiliser dans Swagger UI:${NC}"
echo -e "   1. Ouvrir: ${API_URL}/api-docs"
echo -e "   2. Cliquer sur 'Authorize' 🔓"
echo -e "   3. Entrer: Bearer ${ACCESS_TOKEN:0:50}..."
echo -e "   4. Tester les endpoints\n"

echo -e "${YELLOW}📝 Pour l'utiliser avec cURL:${NC}"
echo -e "   curl -H \"Authorization: Bearer \$TOKEN\" ${API_URL}/api/contracts\n"

echo -e "${YELLOW}📝 Exemple backend Java:${NC}"
cat << 'EOF'
String token = keycloakService.getAccessToken();
HttpHeaders headers = new HttpHeaders();
headers.set("Authorization", "Bearer " + token);
headers.setContentType(MediaType.APPLICATION_JSON);

HttpEntity<String> entity = new HttpEntity<>(headers);
ResponseEntity<String> response = restTemplate.exchange(
    "http://localhost:3000/api/contracts",
    HttpMethod.GET,
    entity,
    String.class
);
EOF

echo -e "\n${GREEN}✨ Votre système est prêt à recevoir des requêtes authentifiées ! ✨${NC}\n"
