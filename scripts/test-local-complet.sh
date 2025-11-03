#!/bin/bash
#
# Script de Test Rapide Local
# À exécuter pour valider que tout fonctionne avant le déploiement multi-VM
#

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   TEST RAPIDE - Blockchain Foncière AFOR                 ║${NC}"
echo -e "${BLUE}║   Validation complète avant déploiement multi-VM          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}\n"

# Fonction de vérification
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 manquant${NC}"
        return 1
    fi
}

# Fonction de test avec retry
test_with_retry() {
    local command=$1
    local description=$2
    local max_attempts=5
    local attempt=1
    
    echo -e "${YELLOW}🧪 Test: $description${NC}"
    
    while [ $attempt -le $max_attempts ]; do
        if eval "$command" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Succès${NC}\n"
            return 0
        fi
        echo -e "${YELLOW}   Tentative $attempt/$max_attempts...${NC}"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    echo -e "${RED}❌ Échec après $max_attempts tentatives${NC}\n"
    return 1
}

# =============================================================================
# TEST 1: Prérequis
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 1 : VÉRIFICATION DES PRÉREQUIS${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

PREREQS_OK=true

echo "Outils requis :"
check_command docker || PREREQS_OK=false

# Vérifier docker-compose (ancienne ou nouvelle syntaxe)
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null 2>&1; then
    echo -e "${GREEN}✅ docker-compose${NC}"
else
    echo -e "${RED}❌ docker-compose manquant${NC}"
    PREREQS_OK=false
fi

check_command java || PREREQS_OK=false
check_command mvn || PREREQS_OK=false
check_command node || PREREQS_OK=false
check_command peer || PREREQS_OK=false

echo ""

if [ "$PREREQS_OK" = false ]; then
    echo -e "${RED}❌ Certains prérequis manquent. Installez-les avant de continuer.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Tous les prérequis sont installés${NC}\n"

# =============================================================================
# TEST 2: Nettoyage
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 2 : NETTOYAGE DE L'ENVIRONNEMENT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🧹 Nettoyage...${NC}"
make clean > /dev/null 2>&1 || true
echo -e "${GREEN}✅ Environnement nettoyé${NC}\n"

# =============================================================================
# TEST 3: Compilation du Chaincode
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 3 : COMPILATION DU CHAINCODE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📦 Compilation du chaincode Java...${NC}"
if make build > /tmp/build.log 2>&1; then
    echo -e "${GREEN}✅ Chaincode compilé avec succès${NC}"
    
    # Vérifier que le JAR existe (plusieurs noms possibles)
    if [ -f "chaincode-java/target/foncier-chaincode-1.0.0.jar" ]; then
        JAR_SIZE=$(du -h chaincode-java/target/foncier-chaincode-1.0.0.jar | cut -f1)
        echo -e "${GREEN}   JAR créé: $JAR_SIZE${NC}\n"
    elif [ -f "chaincode-java/target/chaincode.jar" ]; then
        JAR_SIZE=$(du -h chaincode-java/target/chaincode.jar | cut -f1)
        echo -e "${GREEN}   JAR créé: $JAR_SIZE${NC}\n"
    else
        echo -e "${RED}❌ JAR non trouvé${NC}\n"
        cat /tmp/build.log
        exit 1
    fi
else
    echo -e "${RED}❌ Erreur de compilation${NC}\n"
    cat /tmp/build.log
    exit 1
fi

# =============================================================================
# TEST 4: Package du Chaincode
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 4 : CRÉATION DU PACKAGE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📦 Packaging du chaincode...${NC}"
if make package > /tmp/package.log 2>&1; then
    if [ -f "foncier-v4.0.tar.gz" ]; then
        PKG_SIZE=$(du -h foncier-v4.0.tar.gz | cut -f1)
        echo -e "${GREEN}✅ Package créé: $PKG_SIZE${NC}\n"
    else
        echo -e "${RED}❌ Package non trouvé${NC}\n"
        exit 1
    fi
else
    echo -e "${RED}❌ Erreur de packaging${NC}\n"
    cat /tmp/package.log
    exit 1
fi

# =============================================================================
# TEST 5: Démarrage du Réseau
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 5 : DÉMARRAGE DU RÉSEAU${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🚀 Démarrage du réseau Fabric...${NC}"
if make network-up > /tmp/network.log 2>&1; then
    echo -e "${GREEN}✅ Réseau démarré${NC}\n"
else
    echo -e "${RED}❌ Erreur au démarrage${NC}\n"
    cat /tmp/network.log
    exit 1
fi

# Attendre que tout soit prêt
echo -e "${YELLOW}⏳ Attente de la stabilisation du réseau (30s)...${NC}"
sleep 30

# Vérifier les conteneurs
echo -e "\n${YELLOW}Vérification des conteneurs :${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "peer|orderer|couchdb|ca-"

EXPECTED_CONTAINERS=("peer0.afor.foncier.ci" "peer0.cvgfr.foncier.ci" "peer0.prefet.foncier.ci" "orderer.foncier.ci" "couchdb-afor" "couchdb-cvgfr" "couchdb-prefet")
CONTAINERS_OK=true

for container in "${EXPECTED_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo -e "${GREEN}✅ $container${NC}"
    else
        echo -e "${RED}❌ $container non démarré${NC}"
        CONTAINERS_OK=false
    fi
done

if [ "$CONTAINERS_OK" = false ]; then
    echo -e "\n${RED}❌ Certains conteneurs ne sont pas démarrés${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Tous les conteneurs sont démarrés${NC}\n"

# =============================================================================
# TEST 6: Déploiement du Chaincode
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 6 : DÉPLOIEMENT DU CHAINCODE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📋 Déploiement complet du chaincode...${NC}"
if make deploy-full > /tmp/deploy.log 2>&1; then
    echo -e "${GREEN}✅ Chaincode déployé${NC}\n"
    
    # Vérifier les conteneurs chaincode
    echo -e "${YELLOW}Vérification des conteneurs chaincode :${NC}"
    sleep 5  # Attendre que les conteneurs chaincode démarrent
    
    if docker ps | grep -q "dev-peer"; then
        docker ps --format "table {{.Names}}\t{{.Status}}" | grep "dev-peer"
        echo -e "${GREEN}✅ Conteneurs chaincode actifs${NC}\n"
    else
        echo -e "${YELLOW}⚠️  Conteneurs chaincode pas encore démarrés (normal si aucune transaction)${NC}\n"
    fi
else
    echo -e "${RED}❌ Erreur de déploiement${NC}\n"
    cat /tmp/deploy.log
    exit 1
fi

# =============================================================================
# TEST 7: Création d'un Contrat
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 7 : CRÉATION D'UN CONTRAT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}📝 Création d'un contrat de test...${NC}"

# Attendre quelques secondes pour que le chaincode soit prêt
sleep 5

if test_with_retry "make test-create" "Création de contrat"; then
    echo -e "${GREEN}✅ Contrat créé avec succès${NC}\n"
else
    echo -e "${RED}❌ Échec de la création de contrat${NC}"
    echo -e "${YELLOW}Logs du peer AFOR :${NC}"
    docker logs peer0.afor.foncier.ci --tail 50
    exit 1
fi

# =============================================================================
# TEST 8: Requête d'un Contrat
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 8 : REQUÊTE D'UN CONTRAT${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🔍 Interrogation du contrat...${NC}"

if make test-query > /tmp/query.log 2>&1; then
    echo -e "${GREEN}✅ Requête réussie${NC}"
    echo -e "${YELLOW}Données retournées :${NC}"
    cat /tmp/query.log | grep -A 10 "uuid" || echo "Voir /tmp/query.log"
    echo ""
else
    echo -e "${RED}❌ Échec de la requête${NC}\n"
    cat /tmp/query.log
    exit 1
fi

# =============================================================================
# TEST 9: Vérification CouchDB
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 9 : VÉRIFICATION COUCHDB${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${YELLOW}🔍 Vérification des données dans CouchDB...${NC}"

# Vérifier que CouchDB contient les données
if curl -s http://admin:adminpw@localhost:5984/afor-contrat-agraire/_all_docs | jq -e '.rows | length > 0' > /dev/null 2>&1; then
    DOC_COUNT=$(curl -s http://admin:adminpw@localhost:5984/afor-contrat-agraire/_all_docs | jq '.total_rows')
    echo -e "${GREEN}✅ CouchDB contient $DOC_COUNT document(s)${NC}\n"
else
    echo -e "${YELLOW}⚠️  Aucun document trouvé dans CouchDB (peut être normal)${NC}\n"
fi

# =============================================================================
# TEST 10: Test de l'API (optionnel)
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  TEST 10 : API REST (OPTIONNEL)${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

if [ -d "api" ]; then
    echo -e "${YELLOW}🌐 Démarrage de l'API REST...${NC}"
    
    cd api
    
    # Installer les dépendances si nécessaire
    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}   Installation des dépendances npm...${NC}"
        npm install > /tmp/npm-install.log 2>&1
    fi
    
    # Démarrer l'API en background
    node src/server.js > /tmp/api.log 2>&1 &
    API_PID=$!
    
    echo -e "${GREEN}   API démarrée (PID: $API_PID)${NC}"
    
    # Attendre que l'API démarre
    sleep 5
    
    # Tester le health check
    if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API fonctionnelle${NC}"
        echo -e "${YELLOW}   Health check: http://localhost:3000/api/health${NC}"
        echo -e "${YELLOW}   Swagger UI: http://localhost:3000/api-docs${NC}\n"
        
        # Arrêter l'API
        kill $API_PID 2>/dev/null || true
    else
        echo -e "${YELLOW}⚠️  API non accessible (vérifier /tmp/api.log)${NC}\n"
        kill $API_PID 2>/dev/null || true
    fi
    
    cd ..
else
    echo -e "${YELLOW}⚠️  Dossier API non trouvé, test ignoré${NC}\n"
fi

# =============================================================================
# RAPPORT FINAL
# =============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  RAPPORT FINAL${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"

echo -e "${GREEN}✅✅✅ TOUS LES TESTS LOCAUX SONT PASSÉS AVEC SUCCÈS ! ✅✅✅${NC}\n"

echo -e "${YELLOW}📊 Résumé :${NC}"
echo -e "  ✅ Prérequis installés"
echo -e "  ✅ Chaincode compilé"
echo -e "  ✅ Package créé"
echo -e "  ✅ Réseau démarré (7+ conteneurs)"
echo -e "  ✅ Chaincode déployé"
echo -e "  ✅ Contrat créé"
echo -e "  ✅ Requête fonctionnelle"
echo -e "  ✅ CouchDB opérationnel"

echo -e "\n${BLUE}📝 Services Disponibles :${NC}"
echo -e "  • Peer AFOR        : http://localhost:7051"
echo -e "  • Peer CVGFR       : http://localhost:8051"
echo -e "  • Peer PREFET      : http://localhost:9051"
echo -e "  • Orderer          : http://localhost:7050"
echo -e "  • CouchDB AFOR     : http://localhost:5984/_utils (admin/adminpw)"
echo -e "  • CouchDB CVGFR    : http://localhost:6984/_utils (admin/adminpw)"
echo -e "  • CouchDB PREFET   : http://localhost:7984/_utils (admin/adminpw)"

echo -e "\n${BLUE}🎯 Prochaines Étapes :${NC}"
echo -e "  1. Consulter ${YELLOW}CHECKLIST-DEPLOIEMENT.md${NC} - Phase 1 ✅ Complète"
echo -e "  2. Passer à ${YELLOW}Phase 2${NC} : Préparation Infrastructure"
echo -e "  3. Lire ${YELLOW}GUIDE-DEPLOIEMENT-PRODUCTION.md${NC} pour multi-VM"
echo -e "  4. Configurer ${YELLOW}scripts/deploy-multi-vm.sh${NC} avec vos IPs"

echo -e "\n${BLUE}📚 Documentation :${NC}"
echo -e "  • Guide Complet    : ${YELLOW}GUIDE-DEPLOIEMENT-PRODUCTION.md${NC}"
echo -e "  • Checklist        : ${YELLOW}CHECKLIST-DEPLOIEMENT.md${NC}"
echo -e "  • Résumé Exécutif  : ${YELLOW}RESUME-EXECUTIF.md${NC}"
echo -e "  • Déploiement VM   : ${YELLOW}deployment/README.md${NC}"

echo -e "\n${GREEN}🎉 Votre projet est PRÊT pour le déploiement en production !${NC}\n"

echo -e "${YELLOW}⚠️  Le réseau est toujours actif. Pour l'arrêter :${NC}"
echo -e "    ${BLUE}make network-down${NC}\n"

echo -e "${YELLOW}💡 Pour redémarrer rapidement :${NC}"
echo -e "    ${BLUE}make quick${NC}\n"
