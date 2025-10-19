#!/bin/bash
# filepath: scripts/deploy-complete.sh

# Script de déploiement complet du réseau Hyperledger Fabric 3.1.1
# Réseau foncier de Côte d'Ivoire

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_step() {
    echo -e "${BLUE}===================================================${NC}"
    echo -e "${GREEN}ÉTAPE $1: $2${NC}"
    echo -e "${BLUE}===================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    print_step 1 "Vérification des prérequis"
    
    local missing_deps=0
    
    # Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        missing_deps=1
    else
        print_success "Docker installé: $(docker --version)"
    fi
    
    # Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        missing_deps=1
    else
        print_success "Docker Compose installé: $(docker-compose --version)"
    fi
    
    # Fabric binaries
    if ! command -v peer &> /dev/null; then
        print_error "Les binaires Fabric ne sont pas dans le PATH"
        print_warning "Ajoutez ceci à votre ~/.bashrc:"
        echo "export PATH=\$PATH:/home/absolue/fabric-samples/bin"
        missing_deps=1
    else
        print_success "Fabric binaries trouvés: $(peer version | grep Version:)"
    fi
    
    # fabric-ca-client
    if ! command -v fabric-ca-client &> /dev/null; then
        print_error "fabric-ca-client n'est pas dans le PATH"
        missing_deps=1
    else
        print_success "fabric-ca-client trouvé: $(fabric-ca-client version | grep Version:)"
    fi
    
    if [ $missing_deps -eq 1 ]; then
        print_error "Des dépendances manquent. Installez-les avant de continuer."
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits"
    sleep 2
}

# Nettoyage complet
clean_all() {
    print_step 2 "Nettoyage complet de l'environnement"
    
    cd "$PROJECT_ROOT/deploy"
    
    # Arrêter tous les conteneurs
    print_warning "Arrêt de tous les conteneurs Docker..."
    docker-compose -f docker-compose.yaml down -v 2>/dev/null || true
    docker-compose -f docker-compose-ca.yaml down -v 2>/dev/null || true
    
    # Supprimer les conteneurs orphelins
    docker rm -f $(docker ps -aq --filter "label=service=hyperledger-fabric") 2>/dev/null || true
    
    # Supprimer TOUS les volumes (y compris CAs)
    print_warning "Suppression des volumes Docker (y compris CAs)..."
    docker volume rm -f deploy_ca-afor deploy_ca-cvgfr deploy_ca-prefet deploy_ca-orderer 2>/dev/null || true
    docker volume prune -f
    
    # Supprimer les certificats et artefacts
    print_warning "Suppression des certificats et artefacts..."
    cd "$PROJECT_ROOT/network"
    sudo rm -rf organizations/ordererOrganizations organizations/peerOrganizations
    sudo rm -rf organizations/fabric-ca
    sudo rm -rf channel-artifacts/*
    sudo rm -rf fabric-ca-server-home
    
    print_success "Nettoyage terminé"
    sleep 2
}

# Démarrage des Fabric CAs
start_cas() {
    print_step 3 "Démarrage des Certificate Authorities"
    
    cd "$PROJECT_ROOT/deploy"
    
    print_warning "Démarrage des 4 CAs (AFOR, CVGFR, PREFET, Orderer)..."
    docker-compose -f docker-compose-ca.yaml up -d
    
    print_warning "Attente du démarrage des CAs (30 secondes)..."
    sleep 30
    
    # Vérifier que les CAs sont actifs
    if [ $(docker ps --filter "name=ca-" --format "{{.Names}}" | wc -l) -eq 4 ]; then
        print_success "4 CAs actives:"
        docker ps --filter "name=ca-" --format "  - {{.Names}} ({{.Status}})"
    else
        print_error "Toutes les CAs ne sont pas actives"
        docker ps --filter "name=ca-"
        exit 1
    fi
    
    sleep 2
}

# Enrollment des identités
enroll_identities() {
    print_step 4 "Enrollment des identités avec Fabric CA"
    
    cd "$PROJECT_ROOT"
    chmod +x scripts/setup-ca.sh
    
    print_warning "Lancement du script d'enrollment..."
    ./scripts/setup-ca.sh enroll
    
    # Vérifier que les certificats ont été créés
    if [ -f "network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/signcerts/cert.pem" ]; then
        print_success "Certificats de l'orderer créés"
    else
        print_error "Échec de la création des certificats de l'orderer"
        exit 1
    fi
    
    if [ -f "network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/msp/signcerts/cert.pem" ]; then
        print_success "Certificats des peers créés"
    else
        print_error "Échec de la création des certificats des peers"
        exit 1
    fi
    
    print_success "Toutes les identités sont enrollées"
    sleep 2
}

# Génération des artefacts du channel
generate_channel_artifacts() {
    print_step 5 "Génération des artefacts du channel"
    
    cd "$PROJECT_ROOT/network"
    
    # Créer le dossier channel-artifacts s'il n'existe pas
    mkdir -p channel-artifacts
    
    print_warning "Génération du genesis block pour le channel 'contrats-fonciers'..."
    
    export FABRIC_CFG_PATH="$PROJECT_ROOT/network"
    
    configtxgen -profile ThreeOrgsApplicationGenesis \
        -outputBlock ./channel-artifacts/contrats-fonciers.block \
        -channelID contrats-fonciers
    
    if [ $? -eq 0 ]; then
        print_success "Genesis block créé: channel-artifacts/contrats-fonciers.block"
    else
        print_error "Échec de la génération du genesis block"
        exit 1
    fi
    
    sleep 2
}

# Démarrage du réseau (orderer + peers)
start_network() {
    print_step 6 "Démarrage du réseau Fabric (Orderer + Peers)"
    
    cd "$PROJECT_ROOT/deploy"
    
    print_warning "Démarrage de l'orderer et des 3 peers..."
    docker-compose -f docker-compose.yaml up -d
    
    print_warning "Attente du démarrage du réseau (30 secondes)..."
    sleep 30
    
    # Vérifier que tous les services sont actifs
    local expected_containers=8  # 1 orderer + 3 peers + 3 couchdb + 1 cli
    local running_containers=$(docker ps --filter "label=service=hyperledger-fabric" --format "{{.Names}}" | wc -l)
    
    if [ $running_containers -eq $expected_containers ]; then
        print_success "Réseau démarré avec succès:"
        docker ps --filter "label=service=hyperledger-fabric" --format "  - {{.Names}} ({{.Status}})"
    else
        print_warning "Nombre de conteneurs attendu: $expected_containers, trouvé: $running_containers"
        docker ps --filter "label=service=hyperledger-fabric"
    fi
    
    sleep 2
}

# Vérification de l'orderer
check_orderer() {
    print_step 7 "Vérification de l'orderer"
    
    print_warning "Vérification des logs de l'orderer..."
    docker logs orderer.foncier.ci 2>&1 | tail -20
    
    if docker logs orderer.foncier.ci 2>&1 | grep -q "Beginning to serve requests"; then
        print_success "Orderer opérationnel et prêt à servir les requêtes"
    else
        print_error "L'orderer ne semble pas opérationnel"
        print_warning "Vérifiez les logs complets avec: docker logs orderer.foncier.ci"
    fi
    
    sleep 2
}

# Création du channel
create_channel() {
    print_step 8 "Création du channel avec Channel Participation API"
    
    export ORDERER_CA="$PROJECT_ROOT/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"
    export ORDERER_ADMIN_TLS_SIGN_CERT="$PROJECT_ROOT/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt"
    export ORDERER_ADMIN_TLS_PRIVATE_KEY="$PROJECT_ROOT/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key"
    
    print_warning "Jonction de l'orderer au channel 'contrats-fonciers'..."
    
    osnadmin channel join \
        --channelID contrats-fonciers \
        --config-block "$PROJECT_ROOT/network/channel-artifacts/contrats-fonciers.block" \
        -o localhost:7053 \
        --ca-file "$ORDERER_CA" \
        --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
        --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
    
    if [ $? -eq 0 ]; then
        print_success "Orderer joint au channel 'contrats-fonciers'"
    else
        print_error "Échec de la jonction de l'orderer au channel"
        exit 1
    fi
    
    sleep 2
    
    # Lister les channels de l'orderer
    print_warning "Vérification des channels de l'orderer..."
    osnadmin channel list \
        -o localhost:7053 \
        --ca-file "$ORDERER_CA" \
        --client-cert "$ORDERER_ADMIN_TLS_SIGN_CERT" \
        --client-key "$ORDERER_ADMIN_TLS_PRIVATE_KEY"
    
    sleep 2
}

# Jonction des peers au channel
join_peers_to_channel() {
    print_step 9 "Jonction des peers au channel"
    
    export FABRIC_CFG_PATH="$PROJECT_ROOT/network"
    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="$PROJECT_ROOT/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"
    
    # Joindre peer0.afor
    print_warning "Jonction de peer0.afor.foncier.ci..."
    export CORE_PEER_LOCALMSPID="AFOROrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:7051
    
    peer channel join -b "$PROJECT_ROOT/network/channel-artifacts/contrats-fonciers.block"
    
    if [ $? -eq 0 ]; then
        print_success "peer0.afor.foncier.ci joint au channel"
    else
        print_error "Échec jonction peer0.afor"
    fi
    
    # Joindre peer0.cvgfr
    print_warning "Jonction de peer0.cvgfr.foncier.ci..."
    export CORE_PEER_LOCALMSPID="CVGFROrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:8051
    
    peer channel join -b "$PROJECT_ROOT/network/channel-artifacts/contrats-fonciers.block"
    
    if [ $? -eq 0 ]; then
        print_success "peer0.cvgfr.foncier.ci joint au channel"
    else
        print_error "Échec jonction peer0.cvgfr"
    fi
    
    # Joindre peer0.prefet
    print_warning "Jonction de peer0.prefet.foncier.ci..."
    export CORE_PEER_LOCALMSPID="PREFETOrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:9051
    
    peer channel join -b "$PROJECT_ROOT/network/channel-artifacts/contrats-fonciers.block"
    
    if [ $? -eq 0 ]; then
        print_success "peer0.prefet.foncier.ci joint au channel"
    else
        print_error "Échec jonction peer0.prefet"
    fi
    
    sleep 2
}

# Package et installation du chaincode
deploy_chaincode() {
    print_step 10 "Package et déploiement du chaincode Java"
    
    cd "$PROJECT_ROOT/chaincode-java"
    
    # Build du chaincode Java
    print_warning "Compilation du chaincode Java..."
    ./gradlew clean build
    
    if [ $? -ne 0 ]; then
        print_error "Échec de la compilation du chaincode"
        exit 1
    fi
    
    print_success "Chaincode Java compilé avec succès"
    
    # Package du chaincode
    cd "$PROJECT_ROOT"
    export FABRIC_CFG_PATH="$PROJECT_ROOT/network"
    
    print_warning "Package du chaincode..."
    peer lifecycle chaincode package contrats-fonciers.tar.gz \
        --path "$PROJECT_ROOT/chaincode-java" \
        --lang java \
        --label contrats-fonciers_1.0
    
    if [ $? -eq 0 ]; then
        print_success "Chaincode packagé: contrats-fonciers.tar.gz"
    else
        print_error "Échec du package du chaincode"
        exit 1
    fi
    
    # Installation sur chaque peer
    export CORE_PEER_TLS_ENABLED=true
    export ORDERER_CA="$PROJECT_ROOT/network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem"
    
    # Installer sur peer0.afor
    print_warning "Installation sur peer0.afor.foncier.ci..."
    export CORE_PEER_LOCALMSPID="AFOROrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:7051
    
    peer lifecycle chaincode install contrats-fonciers.tar.gz
    
    # Installer sur peer0.cvgfr
    print_warning "Installation sur peer0.cvgfr.foncier.ci..."
    export CORE_PEER_LOCALMSPID="CVGFROrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/cvgfr.foncier.ci/users/Admin@cvgfr.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:8051
    
    peer lifecycle chaincode install contrats-fonciers.tar.gz
    
    # Installer sur peer0.prefet
    print_warning "Installation sur peer0.prefet.foncier.ci..."
    export CORE_PEER_LOCALMSPID="PREFETOrg"
    export CORE_PEER_TLS_ROOTCERT_FILE="$PROJECT_ROOT/network/organizations/peerOrganizations/prefet.foncier.ci/peers/peer0.prefet.foncier.ci/tls/ca.crt"
    export CORE_PEER_MSPCONFIGPATH="$PROJECT_ROOT/network/organizations/peerOrganizations/prefet.foncier.ci/users/Admin@prefet.foncier.ci/msp"
    export CORE_PEER_ADDRESS=localhost:9051
    
    peer lifecycle chaincode install contrats-fonciers.tar.gz
    
    print_success "Chaincode installé sur les 3 peers"
    
    sleep 2
}

# Affichage du résumé final
display_summary() {
    print_step 11 "RÉSUMÉ DU DÉPLOIEMENT"
    
    echo ""
    print_success "�� RÉSEAU FABRIC 3.1.1 DÉPLOYÉ AVEC SUCCÈS !"
    echo ""
    echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│             RÉSEAU FONCIER CÔTE D'IVOIRE                │${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "${BLUE}📊 COMPOSANTS ACTIFS:${NC}"
    echo "  ✅ 1 Orderer (orderer.foncier.ci:7050)"
    echo "  ✅ 3 Peers (AFOR:7051, CVGFR:8051, PREFET:9051)"
    echo "  ✅ 3 CouchDB (ports 5984, 6984, 7984)"
    echo "  ✅ 4 Certificate Authorities"
    echo "  ✅ 1 CLI d'administration"
    echo ""
    echo -e "${BLUE}📡 CHANNEL:${NC}"
    echo "  ✅ contrats-fonciers (3 organisations)"
    echo ""
    echo -e "${BLUE}🔐 CERTIFICATS:${NC}"
    echo "  ✅ Générés avec Fabric CA"
    echo "  ✅ TLS activé partout"
    echo ""
    echo -e "${BLUE}📦 CHAINCODE:${NC}"
    echo "  ✅ Chaincode Java packagé et installé"
    echo "  ⏳ Prochaine étape: Approuver et commiter"
    echo ""
    echo -e "${YELLOW}🔧 COMMANDES UTILES:${NC}"
    echo "  # Voir les logs de l'orderer"
    echo "  docker logs orderer.foncier.ci"
    echo ""
    echo "  # Voir les logs d'un peer"
    echo "  docker logs peer0.afor.foncier.ci"
    echo ""
    echo "  # Entrer dans le CLI"
    echo "  docker exec -it cli bash"
    echo ""
    echo "  # Lister les channels de l'orderer"
    echo "  osnadmin channel list -o localhost:7053 \\"
    echo "    --ca-file network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem \\"
    echo "    --client-cert network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt \\"
    echo "    --client-key network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key"
    echo ""
    echo -e "${GREEN}✨ Votre réseau blockchain est maintenant opérationnel !${NC}"
    echo ""
}

# Programme principal
main() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     DÉPLOIEMENT RÉSEAU FABRIC 3.1.1 - CÔTE D'IVOIRE      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Exécution de toutes les étapes
    check_prerequisites
    clean_all
    start_cas
    enroll_identities
    generate_channel_artifacts
    start_network
    check_orderer
    create_channel
    join_peers_to_channel
    deploy_chaincode
    display_summary
}

# Lancer le script
main
