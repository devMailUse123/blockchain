#!/bin/bash
#
# Script de déploiement simplifié pour VM de production
# Utilise les images Docker pré-built depuis le registry
#
# Usage:
#   ./deploy-production.sh [version]
#
# Exemple:
#   ./deploy-production.sh v1.0.0
#   ./deploy-production.sh latest

set -e

VERSION="${1:-latest}"
REGISTRY="${REGISTRY:-ghcr.io/aforinnov}"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DÉPLOIEMENT PRODUCTION - HYPERLEDGER FABRIC"
echo "  Version: ${VERSION}"
echo "  Registry: ${REGISTRY}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker non installé${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker $(docker --version | cut -d' ' -f3)${NC}"

# Vérifier Docker Compose
if ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose non disponible${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Docker Compose OK${NC}"

# Télécharger docker-compose.ci.yml
echo -e "${YELLOW}📥 Téléchargement configuration...${NC}"
curl -fsSL https://raw.githubusercontent.com/AforInnov/afor-blockchain/main/docker-compose.ci.yml \
    -o docker-compose.yml || {
    echo -e "${RED}❌ Échec téléchargement docker-compose${NC}"
    exit 1
}

echo -e "${GREEN}✅ Configuration téléchargée${NC}"

# Login au registry (si besoin)
if [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}🔐 Login au registry...${NC}"
    echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_ACTOR" --password-stdin
    echo -e "${GREEN}✅ Authentifié${NC}"
fi

# Pull des images
echo -e "${YELLOW}📦 Pull des images Docker...${NC}"
export REGISTRY VERSION
docker compose pull

echo -e "${GREEN}✅ Images téléchargées${NC}"

# Arrêter anciennes instances
echo -e "${YELLOW}🛑 Arrêt des anciens conteneurs...${NC}"
docker compose down -v 2>/dev/null || true

# Démarrer le réseau
echo -e "${YELLOW}🚀 Démarrage du réseau Fabric...${NC}"
docker compose up -d

# Attendre l'API
echo -e "${YELLOW}⏳ Attente de l'API (60 secondes)...${NC}"
sleep 60

# Vérifier l'API
echo -e "${YELLOW}🔍 Vérification de l'API...${NC}"
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API opérationnelle${NC}"
else
    echo -e "${YELLOW}⚠️  API pas encore prête, vérifier les logs${NC}"
    echo "docker logs api-rest"
fi

# Résumé
echo ""
echo -e "${BLUE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ DÉPLOIEMENT TERMINÉ"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${NC}"

echo -e "${GREEN}Services déployés :${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "orderer|peer|couchdb|api"

echo ""
echo -e "${GREEN}API REST :${NC}"
echo "  • Health:  http://localhost:3000/health"
echo "  • Swagger: http://localhost:3000/api-docs"
echo ""

echo -e "${GREEN}Commandes utiles :${NC}"
echo "  • Logs API:      docker logs -f api-rest"
echo "  • Logs réseau:   docker compose logs -f"
echo "  • Arrêter:       docker compose down"
echo "  • Restart:       docker compose restart api-rest"
echo ""
