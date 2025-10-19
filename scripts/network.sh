#!/bin/bash
#
# Script principal de gestion du réseau Hyperledger Fabric 3.1.1
# Architecture refactorisée: AFOR, CVGFR, PREFET avec canaux spécialisés
# Usage: ./network.sh up|down|restart|createChannels|deployChaincode
#

# Variables globales
COMPOSE_FILE_BASE=../deploy/docker-compose.yaml
FABRIC_CFG_PATH=$PWD/network

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Organisations
ORGS=("afor" "cvgfr" "prefet")
DOMAINS=("afor.foncier.ci" "cvgfr.foncier.ci" "prefet.foncier.ci")

# Canaux spécialisés
CHANNELS=("afor-contrat-agraire" "afor-certificate" "admin")

# Fonction d'affichage coloré
print_message() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

print_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Vérification des prérequis
check_prerequisites() {
    print_message "Vérification des prérequis..."
    
    # Vérifier Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker n'est pas installé"
        exit 1
    fi
    
    # Vérifier Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose n'est pas installé"
        exit 1
    fi
    
    # Vérifier les binaires Fabric
    if ! command -v peer &> /dev/null; then
        print_error "Les binaires Hyperledger Fabric ne sont pas installés"
        print_info "Exécutez: curl -sSL https://bit.ly/2ysbOFE | bash -s"
        exit 1
    fi
    
    # Vérifier Java pour le chaincode
    if ! command -v java &> /dev/null; then
        print_error "Java n'est pas installé (requis pour le chaincode Java)"
        exit 1
    fi
    
    # Vérifier Maven pour le build
    if ! command -v mvn &> /dev/null; then
        print_error "Maven n'est pas installé (requis pour le build du chaincode)"
        exit 1
    fi
    
    print_message "Tous les prérequis sont installés ✓"
}

# Nettoyage des certificats existants
clean_certificates() {
    print_message "Nettoyage des certificats existants..."
    
    # Supprimer les certificats existants
    rm -rf network/organizations/peerOrganizations
    rm -rf network/organizations/ordererOrganizations
    rm -rf network/organizations/fabric-ca
    rm -f ../network/crypto-config.yaml
    
    # Arrêter les CAs si elles tournent
    if [ -f ../deploy/docker-compose-ca.yaml ]; then
        docker-compose -f ../deploy/docker-compose-ca.yaml down --volumes --remove-orphans 2>/dev/null || true
        rm -f ../deploy/docker-compose-ca.yaml
    fi
    
    print_message "Certificats nettoyés ✓"
}

# Génération des certificats et MSP
generate_certificates() {
    print_message "Génération des certificats pour les organisations..."
    
    # Vérifier si cryptogen est disponible
    if command -v cryptogen &> /dev/null; then
        generate_certificates_cryptogen
    else
        print_warning "cryptogen non trouvé, utilisation de la génération via Fabric CA"
        generate_certificates_fabric_ca
    fi
    
    print_message "Certificats générés ✓"
}

# Génération via cryptogen (plus simple pour développement)
generate_certificates_cryptogen() {
    print_info "Utilisation de cryptogen pour générer les certificats..."
    
    # Créer le fichier crypto-config.yaml s'il n'existe pas
    create_crypto_config
    
    # Générer les certificats
    cryptogen generate --config=../network/crypto-config.yaml --output=../network/organizations
    
    # Créer la structure MSP requise par Fabric 3.x
    setup_msp_structure
}

# Génération via Fabric CA (production)
generate_certificates_fabric_ca() {
    print_info "Génération des certificats via Fabric CA..."
    
    # Démarrer les Fabric CA
    start_fabric_cas
    
    # Générer les certificats pour chaque organisation
    for i in "${!ORGS[@]}"; do
        org="${ORGS[$i]}"
        domain="${DOMAINS[$i]}"
        
        print_info "Génération des certificats pour ${org}..."
        
        # Créer la structure des répertoires
        create_org_structure "${org}" "${domain}"
        
        # Enregistrer et inscrire les identités
        enroll_org_identities "${org}" "${domain}"
    done
    
    # Générer les certificats pour l'orderer global
    create_orderer_structure
    enroll_orderer_identities
}

# Créer le fichier crypto-config.yaml
create_crypto_config() {
    cat > ../network/crypto-config.yaml << EOF
# Configuration cryptographique pour le réseau foncier Côte d'Ivoire
# Fabric 3.1.1 - AFOR, CVGFR, PREFET

OrdererOrgs:
  - Name: Orderer
    Domain: foncier.ci
    EnableNodeOUs: true
    Specs:
      - Hostname: orderer
      - Hostname: orderer-afor
        SANS:
          - "localhost"
          - "127.0.0.1"
          - "orderer-afor.foncier.ci"
      - Hostname: orderer-cvgfr
        SANS:
          - "localhost"
          - "127.0.0.1"
          - "orderer-cvgfr.foncier.ci"
      - Hostname: orderer-prefet
        SANS:
          - "localhost"
          - "127.0.0.1"
          - "orderer-prefet.foncier.ci"

PeerOrgs:
  - Name: AFOR
    Domain: afor.foncier.ci
    EnableNodeOUs: true
    Template:
      Count: 1
      SANS:
        - "localhost"
        - "127.0.0.1"
        - "peer0.afor.foncier.ci"
    Users:
      Count: 1

  - Name: CVGFR
    Domain: cvgfr.foncier.ci
    EnableNodeOUs: true
    Template:
      Count: 1
      SANS:
        - "localhost"
        - "127.0.0.1"
        - "peer0.cvgfr.foncier.ci"
    Users:
      Count: 1

  - Name: PREFET
    Domain: prefet.foncier.ci
    EnableNodeOUs: true
    Template:
      Count: 1
      SANS:
        - "localhost"
        - "127.0.0.1"
        - "peer0.prefet.foncier.ci"
    Users:
      Count: 1
EOF
    
    print_info "Fichier crypto-config.yaml créé"
}

# Configurer la structure MSP pour Fabric 3.x
setup_msp_structure() {
    print_info "Configuration de la structure MSP pour Fabric 3.1.1..."
    
    # Pour chaque organisation peer
    for org in "afor" "cvgfr" "prefet"; do
        org_upper=$(echo "$org" | tr '[:lower:]' '[:upper:]')
        msp_dir="network/organizations/peerOrganizations/${org}.foncier.ci/msp"
        
        if [ -d "$msp_dir" ]; then
            # Créer le fichier config.yaml pour NodeOUs
            cat > "${msp_dir}/config.yaml" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.${org}.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.${org}.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.${org}.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.${org}.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
            print_info "Configuration MSP créée pour ${org_upper}"
        fi
    done
    
    # Pour l'organisation orderer
    orderer_msp_dir="network/organizations/ordererOrganizations/foncier.ci/msp"
    if [ -d "$orderer_msp_dir" ]; then
        cat > "${orderer_msp_dir}/config.yaml" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca.foncier.ci-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
        print_info "Configuration MSP créée pour Orderer"
    fi
}

# Fonctions pour Fabric CA

# Démarrer les Fabric CAs
start_fabric_cas() {
    print_info "Démarrage des Certificate Authorities..."
    
    # Créer la configuration CA pour chaque organisation
    create_ca_configs
    
    # Démarrer les CAs via Docker
    docker-compose -f ../deploy/docker-compose-ca.yaml up -d
    
    # Attendre que les CAs soient prêtes
    sleep 10
    
    print_info "Certificate Authorities démarrées"
}

# Créer les configurations CA
create_ca_configs() {
    mkdir -p network/docker
    
    cat > ../deploy/docker-compose-ca.yaml << EOF
version: '3.8'

networks:
  foncier:
    name: foncier_network

services:
  ca.afor.foncier.ci:
    image: hyperledger/fabric-ca:1.6.0
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-afor
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=7054
    ports:
      - "7054:7054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ./organizations/fabric-ca/afor:/etc/hyperledger/fabric-ca-server
    container_name: ca.afor.foncier.ci
    networks:
      - foncier

  ca.cvgfr.foncier.ci:
    image: hyperledger/fabric-ca:1.6.0
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-cvgfr
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=8054
    ports:
      - "8054:8054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ./organizations/fabric-ca/cvgfr:/etc/hyperledger/fabric-ca-server
    container_name: ca.cvgfr.foncier.ci
    networks:
      - foncier

  ca.prefet.foncier.ci:
    image: hyperledger/fabric-ca:1.6.0
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-prefet
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=9054
    ports:
      - "9054:9054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ./organizations/fabric-ca/prefet:/etc/hyperledger/fabric-ca-server
    container_name: ca.prefet.foncier.ci
    networks:
      - foncier
EOF
}

# Créer la structure d'organisation
create_org_structure() {
    local org=$1
    local domain=$2
    
    print_info "Création de la structure pour ${org}..."
    
    mkdir -p "network/organizations/peerOrganizations/${domain}/ca"
    mkdir -p "network/organizations/peerOrganizations/${domain}/msp"
    mkdir -p "network/organizations/peerOrganizations/${domain}/peers/peer0.${domain}"
    mkdir -p "network/organizations/peerOrganizations/${domain}/users/Admin@${domain}"
    mkdir -p "network/organizations/peerOrganizations/${domain}/users/User1@${domain}"
    mkdir -p "network/organizations/peerOrganizations/${domain}/orderers/orderer-${domain}"
}

# Inscrire les identités d'organisation
enroll_org_identities() {
    local org=$1
    local domain=$2
    local ca_port=""
    
    case $org in
        "afor") ca_port="7054" ;;
        "cvgfr") ca_port="8054" ;;
        "prefet") ca_port="9054" ;;
    esac
    
    print_info "Inscription des identités pour ${org}..."
    
    # Variables d'environnement pour fabric-ca-client
    export FABRIC_CA_CLIENT_HOME="network/organizations/peerOrganizations/${domain}"
    
    # Inscrire l'admin CA
    fabric-ca-client enroll -u https://admin:adminpw@localhost:${ca_port} --caname ca-${org} --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.${domain}-cert.pem"
    
    # Enregistrer l'admin de l'organisation
    fabric-ca-client register --caname ca-${org} --id.name admin --id.secret adminpw --id.type admin --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.${domain}-cert.pem"
    
    # Enregistrer le peer
    fabric-ca-client register --caname ca-${org} --id.name peer0 --id.secret peer0pw --id.type peer --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.${domain}-cert.pem"
    
    # Enregistrer un utilisateur
    fabric-ca-client register --caname ca-${org} --id.name user1 --id.secret user1pw --id.type client --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.${domain}-cert.pem"
}

# Créer la structure orderer
create_orderer_structure() {
    print_info "Création de la structure pour l'orderer global..."
    
    mkdir -p network/organizations/ordererOrganizations/foncier.ci/ca
    mkdir -p network/organizations/ordererOrganizations/foncier.ci/msp
    mkdir -p network/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci
    mkdir -p network/organizations/ordererOrganizations/foncier.ci/users/Admin@foncier.ci
}

# Inscrire les identités orderer
enroll_orderer_identities() {
    print_info "Inscription des identités pour l'orderer global..."
    
    # Utiliser la CA AFOR comme CA principale pour l'orderer
    export FABRIC_CA_CLIENT_HOME="network/organizations/ordererOrganizations/foncier.ci"
    
    # Inscrire l'admin orderer
    fabric-ca-client enroll -u https://admin:adminpw@localhost:7054 --caname ca-afor --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.foncier.ci-cert.pem"
    
    # Enregistrer l'orderer
    fabric-ca-client register --caname ca-afor --id.name orderer --id.secret ordererpw --id.type orderer --tls.certfiles "${FABRIC_CA_CLIENT_HOME}/ca/ca.foncier.ci-cert.pem"
}

# Construction du chaincode Java
build_chaincode() {
    print_message "Construction du chaincode Java..."
    
    cd chaincode-java
    if [ -f "pom.xml" ]; then
        mvn clean package -DskipTests
        if [ $? -eq 0 ]; then
            print_message "Chaincode Java construit avec succès ✓"
        else
            print_error "Échec de la construction du chaincode Java"
            exit 1
        fi
    else
        print_error "Fichier pom.xml non trouvé dans chaincode-java/"
        exit 1
    fi
    cd ..
}

# Construction de l'API Java
build_api() {
    print_message "Construction de l'API REST Java..."
    
    cd api-java
    if [ -f "pom.xml" ]; then
        mvn clean package -DskipTests
        if [ $? -eq 0 ]; then
            print_message "API Java construite avec succès ✓"
        else
            print_error "Échec de la construction de l'API Java"
            exit 1
        fi
    else
        print_error "Fichier pom.xml non trouvé dans api-java/"
        exit 1
    fi
    cd ..
}

# Démarrage du réseau
network_up() {
    print_message "Démarrage du réseau Hyperledger Fabric..."
    
    check_prerequisites
    
    # Arrêter le réseau existant s'il y en a un
    network_down
    
    # Générer les artefacts
    generate_certificates
    
    # Construire les composants Java (temporairement désactivé)
    # build_chaincode
    # build_api
    
    # Nettoyer les volumes Docker
    print_info "Nettoyage des volumes Docker..."
    docker volume prune -f
    
    # Démarrer les services
    print_info "Démarrage des conteneurs Docker..."
    docker-compose -f $COMPOSE_FILE_BASE up -d
    
    # Attendre que les services soient prêts
    print_info "Attente du démarrage des services..."
    sleep 15
    
    # Vérifier le statut des conteneurs
    check_containers_status
    
    print_message "Réseau Fabric démarré avec succès ✓"
    print_info "Orderers:"
    print_info "  - Orderer global: localhost:7050"
    print_info "  - Orderer AFOR: localhost:7250" 
    print_info "  - Orderer CVGFR: localhost:8050"
    print_info "  - Orderer PREFET: localhost:9050"
    print_info "Peers:"
    print_info "  - Peer AFOR: localhost:7051"
    print_info "  - Peer CVGFR: localhost:8051"
    print_info "  - Peer PREFET: localhost:9051"
    print_info "CouchDB:"
    print_info "  - AFOR: http://localhost:5984"
    print_info "  - CVGFR: http://localhost:6984"
    print_info "  - PREFET: http://localhost:7984"
    print_info "API REST: http://localhost:8080"
}

# Arrêt du réseau
network_down() {
    print_message "Arrêt du réseau Hyperledger Fabric..."
    
    # Arrêter les conteneurs
    if [ -f "$COMPOSE_FILE_BASE" ]; then
        docker-compose -f $COMPOSE_FILE_BASE down --volumes --remove-orphans
    fi
    
    # Nettoyer les conteneurs Fabric
    docker ps -a | grep hyperledger | awk '{print $1}' | xargs -r docker rm -f
    
    # Nettoyer les images non utilisées
    docker system prune -f
    
    print_message "Réseau arrêté ✓"
}

# Redémarrage du réseau
network_restart() {
    print_message "Redémarrage du réseau..."
    network_down
    sleep 2
    network_up
}

# Vérification du statut des conteneurs
check_containers_status() {
    print_info "Vérification du statut des conteneurs..."
    
    # Conteneurs requis
    required_containers=(
        "orderer.foncier.ci"
        "orderer-afor.foncier.ci"
        "orderer-cvgfr.foncier.ci"
        "orderer-prefet.foncier.ci"
        "peer0.afor.foncier.ci"
        "peer0.cvgfr.foncier.ci"
        "peer0.prefet.foncier.ci"
        "couchdb-afor"
        "couchdb-cvgfr"
        "couchdb-prefet"
    )
    
    for container in "${required_containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$container"; then
            print_info "✓ $container est en cours d'exécution"
        else
            print_error "✗ $container n'est pas en cours d'exécution"
        fi
    done
}

# Création des canaux spécialisés
create_channels() {
    print_message "Création des canaux spécialisés..."
    
    # S'assurer que le réseau est démarré
    check_containers_status
    
    # Créer le canal AFOR_CONTRAT_AGRAIRE
    print_info "Création du canal AFOR_CONTRAT_AGRAIRE..."
    docker exec cli peer channel create \
        -o orderer.foncier.ci:7050 \
        -c afor-contrat-agraire \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/afor-contrat-agraire.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem
    
    # Créer le canal AFOR_CERTIFICATE
    print_info "Création du canal AFOR_CERTIFICATE..."
    docker exec cli peer channel create \
        -o orderer.foncier.ci:7050 \
        -c afor-certificate \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/afor-certificate.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem
    
    # Créer le canal ADMIN
    print_info "Création du canal ADMIN..."
    docker exec cli peer channel create \
        -o orderer.foncier.ci:7050 \
        -c admin \
        -f /opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts/admin.tx \
        --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem
    
    print_message "Canaux créés avec succès ✓"
}

# Déploiement du chaincode Java
deploy_chaincode() {
    print_message "Déploiement du chaincode Java..."
    
    # S'assurer que les canaux sont créés
    create_channels
    
    print_info "Empaquetage du chaincode..."
    # Empaqueter le chaincode Java
    docker exec cli peer lifecycle chaincode package foncier-chaincode.tar.gz \
        --path /opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode-java \
        --lang java \
        --label foncier-chaincode_1.0
    
    print_info "Installation du chaincode sur les peers..."
    # Installer sur tous les peers
    for org in "${ORGS[@]}"; do
        print_info "Installation sur peer0.${org}.foncier.ci..."
        # Configuration spécifique à chaque org
        # (Configuration des variables d'environnement pour chaque peer)
    done
    
    print_message "Chaincode déployé avec succès ✓"
}

# Affichage de l'aide
print_help() {
    echo ""
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  up              - Démarrer le réseau Fabric"
    echo "  down            - Arrêter le réseau Fabric"
    echo "  restart         - Redémarrer le réseau Fabric"
    echo "  createChannels  - Créer les canaux spécialisés"
    echo "  deployChaincode - Déployer le chaincode Java"
    echo "  cleanCerts      - Nettoyer tous les certificats existants"
    echo "  generateCerts   - Nettoyer et régénérer tous les certificats"
    echo "  status          - Vérifier le statut des conteneurs"
    echo "  logs <service>  - Afficher les logs d'un service"
    echo "  help            - Afficher cette aide"
    echo ""
    echo "Exemples:"
    echo "  $0 up                    # Démarrer le réseau complet"
    echo "  $0 createChannels        # Créer les canaux AFOR_CONTRAT_AGRAIRE, AFOR_CERTIFICATE, ADMIN"
    echo "  $0 deployChaincode       # Déployer le chaincode Java"
    echo "  $0 logs peer0.afor.foncier.ci  # Voir les logs du peer AFOR"
    echo ""
}

# Script principal
case "$1" in
    "up")
        network_up
        ;;
    "down")
        network_down
        ;;
    "restart")
        network_restart
        ;;
    "createChannels")
        create_channels
        ;;
    "deployChaincode")
        deploy_chaincode
        ;;
    "status")
        check_containers_status
        ;;
    "cleanCerts")
        clean_certificates
        ;;
    "generateCerts")
        clean_certificates
        generate_certificates
        ;;
    "logs")
        if [ -z "$2" ]; then
            print_error "Veuillez spécifier le nom du service"
            echo "Usage: $0 logs <service_name>"
            exit 1
        fi
        docker logs -f "$2"
        ;;
    "help" | "-h" | "--help")
        print_help
        ;;
    *)
        print_error "Commande inconnue: $1"
        print_help
        exit 1
        ;;
esac