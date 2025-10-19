#!/bin/bash

# Script de configuration des Certificate Authorities pour Fabric 3.1.1
# Utilise Fabric CA au lieu de cryptogen (recommandé pour Fabric 3.x)

set -e

# Vérification et configuration de fabric-ca-client
if ! command -v fabric-ca-client &> /dev/null; then
    if [ -f "/home/absolue/fabric-samples/bin/fabric-ca-client" ]; then
        export PATH="/home/absolue/fabric-samples/bin:$PATH"
        echo "✓ fabric-ca-client ajouté au PATH depuis fabric-samples"
    else
        echo "❌ ERREUR: fabric-ca-client n'est pas installé"
        echo "Installez-le avec: curl -sSL https://bit.ly/2ysbOFE | bash -s"
        exit 1
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NETWORK_DIR="$PROJECT_ROOT/network"
ORG_DIR="$NETWORK_DIR/organizations"
DEPLOY_DIR="$PROJECT_ROOT/deploy"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction pour attendre qu'un CA soit prêt
wait_for_ca() {
    local ca_name=$1
    local ca_port=$2
    local max_wait=30
    local wait_time=0
    
    print_info "Attente du démarrage de ${ca_name}..."
    
    while [ $wait_time -lt $max_wait ]; do
        if curl -s -k https://localhost:${ca_port}/cainfo > /dev/null 2>&1; then
            print_success "${ca_name} est prêt"
            return 0
        fi
        sleep 2
        wait_time=$((wait_time + 2))
    done
    
    print_error "${ca_name} n'a pas démarré dans le délai imparti"
    return 1
}

# Fonction pour créer les dossiers nécessaires
create_directories() {
    print_info "Création des dossiers pour les organisations..."
    
    mkdir -p "$ORG_DIR/fabric-ca"/{afor,cvgfr,prefet,orderer}
    mkdir -p "$ORG_DIR/peerOrganizations"/{afor.foncier.ci,cvgfr.foncier.ci,prefet.foncier.ci}
    mkdir -p "$ORG_DIR/ordererOrganizations/foncier.ci"
    
    print_success "Dossiers créés"
}

# Fonction pour créer le docker-compose des CAs
create_ca_compose() {
    print_info "Création du fichier docker-compose-ca.yaml pour Fabric 3.1.1..."
    
    cat > "$DEPLOY_DIR/docker-compose-ca.yaml" << 'EOF'
version: '3.8'

networks:
  foncier:
    name: fabric-ca
    driver: bridge

services:
  
  # ============================================================================
  # CA pour l'organisation AFOR
  # ============================================================================
  ca-afor:
    image: hyperledger/fabric-ca:1.5
    container_name: ca-afor
    labels:
      service: hyperledger-fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-afor
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=7054
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server/ca-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server/ca-key.pem
    ports:
      - "7054:7054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../network/organizations/fabric-ca/afor:/etc/hyperledger/fabric-ca-server
    networks:
      - foncier

  # ============================================================================
  # CA pour l'organisation CVGFR
  # ============================================================================
  ca-cvgfr:
    image: hyperledger/fabric-ca:1.5
    container_name: ca-cvgfr
    labels:
      service: hyperledger-fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-cvgfr
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=8054
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server/ca-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server/ca-key.pem
    ports:
      - "8054:8054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../network/organizations/fabric-ca/cvgfr:/etc/hyperledger/fabric-ca-server
    networks:
      - foncier

  # ============================================================================
  # CA pour l'organisation PREFET
  # ============================================================================
  ca-prefet:
    image: hyperledger/fabric-ca:1.5
    container_name: ca-prefet
    labels:
      service: hyperledger-fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-prefet
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=9054
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server/ca-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server/ca-key.pem
    ports:
      - "9054:9054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../network/organizations/fabric-ca/prefet:/etc/hyperledger/fabric-ca-server
    networks:
      - foncier

  # ============================================================================
  # CA pour l'Orderer Organization
  # ============================================================================
  ca-orderer:
    image: hyperledger/fabric-ca:1.5
    container_name: ca-orderer
    labels:
      service: hyperledger-fabric-ca
    environment:
      - FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server
      - FABRIC_CA_SERVER_CA_NAME=ca-orderer
      - FABRIC_CA_SERVER_TLS_ENABLED=true
      - FABRIC_CA_SERVER_PORT=10054
      - FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server/ca-cert.pem
      - FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server/ca-key.pem
    ports:
      - "10054:10054"
    command: sh -c 'fabric-ca-server start -b admin:adminpw -d'
    volumes:
      - ../network/organizations/fabric-ca/orderer:/etc/hyperledger/fabric-ca-server
    networks:
      - foncier
EOF

    print_success "Fichier docker-compose-ca.yaml créé"
}

# Fonction pour démarrer les CAs
start_cas() {
    print_info "Démarrage des Certificate Authorities..."
    cd "$PROJECT_ROOT/deploy"
    docker-compose -f docker-compose-ca.yaml up -d
    sleep 5
    print_success "CAs démarrées"
}

# Fonction pour arrêter les CAs
stop_cas() {
    print_info "Arrêt des Certificate Authorities..."
    cd "$PROJECT_ROOT/deploy"
    if [ -f docker-compose-ca.yaml ]; then
        docker-compose -f docker-compose-ca.yaml down --volumes
        rm -f docker-compose-ca.yaml
    fi
    print_success "CAs arrêtées"
}

# Fonction pour créer la structure des organisations
create_org_structure() {
    print_info "Création de la structure des organisations..."
    
    # Créer les dossiers de base
    mkdir -p "$ORG_DIR/fabric-ca"/{afor,cvgfr,prefet,orderer}
    mkdir -p "$ORG_DIR/peerOrganizations"/{afor.foncier.ci,cvgfr.foncier.ci,prefet.foncier.ci}
    mkdir -p "$ORG_DIR/ordererOrganizations/foncier.ci"
    
    print_success "Structure des organisations créée"
}

# Fonction pour créer le config NodeOUs
create_nodeou_config() {
    local msp_dir=$1
    
    cat > "$msp_dir/config.yaml" << EOF
NodeOUs:
  Enable: true
  ClientOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: client
  PeerOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: peer
  AdminOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: admin
  OrdererOUIdentifier:
    Certificate: cacerts/ca-cert.pem
    OrganizationalUnitIdentifier: orderer
EOF
}

# Fonction pour enregistrer et enroller l'Orderer
enroll_orderer() {
    print_info "Enrollment de l'Orderer Organization..."
    
    export FABRIC_CA_CLIENT_HOME="$ORG_DIR/ordererOrganizations/foncier.ci"
    
    # Enroll CA admin
    fabric-ca-client enroll -u https://admin:adminpw@localhost:10054 \
        --caname ca-orderer --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    # Create NodeOUs config
    create_nodeou_config "$ORG_DIR/ordererOrganizations/foncier.ci/msp"
    
    # Register orderer
    fabric-ca-client register --caname ca-orderer \
        --id.name orderer --id.secret ordererpw --id.type orderer \
        --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    # Register orderer admin
    fabric-ca-client register --caname ca-orderer \
        --id.name ordererAdmin --id.secret ordererAdminpw --id.type admin \
        --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    # Enroll orderer
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10054 \
        --caname ca-orderer -M "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp" \
        --csr.hosts orderer.foncier.ci --csr.hosts localhost \
        --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    # Copy NodeOUs config
    cp "$ORG_DIR/ordererOrganizations/foncier.ci/msp/config.yaml" \
       "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/config.yaml"
    
    # Enroll TLS
    fabric-ca-client enroll -u https://orderer:ordererpw@localhost:10054 \
        --caname ca-orderer -M "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls" \
        --enrollment.profile tls --csr.hosts orderer.foncier.ci --csr.hosts localhost \
        --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    # Rename TLS files
    cp "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/tlscacerts/"* \
       "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/ca.crt"
    cp "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/signcerts/"* \
       "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.crt"
    cp "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/keystore/"* \
       "$ORG_DIR/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/tls/server.key"
    
    # Enroll admin
    fabric-ca-client enroll -u https://ordererAdmin:ordererAdminpw@localhost:10054 \
        --caname ca-orderer -M "$ORG_DIR/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp" \
        --tls.certfiles "$ORG_DIR/fabric-ca/orderer/ca-cert.pem"
    
    cp "$ORG_DIR/ordererOrganizations/foncier.ci/msp/config.yaml" \
       "$ORG_DIR/ordererOrganizations/foncier.ci/users/Admin@foncier.ci/msp/config.yaml"
    
    print_success "Orderer Organization enrollé"
}

# Fonction pour enroller une organisation peer
enroll_peer_org() {
    local org_name=$1
    local org_domain=$2
    local ca_port=$3
    local ca_name="ca-$(echo $org_name | tr '[:upper:]' '[:lower:]')"
    
    print_info "Enrollment de l'organisation ${org_name}..."
    
    export FABRIC_CA_CLIENT_HOME="$ORG_DIR/peerOrganizations/$org_domain"
    
    # Enroll CA admin
    fabric-ca-client enroll -u https://admin:adminpw@localhost:$ca_port \
        --caname $ca_name --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    # Create NodeOUs config
    create_nodeou_config "$ORG_DIR/peerOrganizations/$org_domain/msp"
    
    # Register peer
    fabric-ca-client register --caname $ca_name \
        --id.name peer0 --id.secret peer0pw --id.type peer \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    # Register user
    fabric-ca-client register --caname $ca_name \
        --id.name user1 --id.secret user1pw --id.type client \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    # Register admin
    fabric-ca-client register --caname $ca_name \
        --id.name org${org_name}admin --id.secret org${org_name}adminpw --id.type admin \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    # Enroll peer
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:$ca_port \
        --caname $ca_name -M "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/msp" \
        --csr.hosts peer0.$org_domain --csr.hosts localhost \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    cp "$ORG_DIR/peerOrganizations/$org_domain/msp/config.yaml" \
       "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/msp/config.yaml"
    
    # Enroll TLS
    fabric-ca-client enroll -u https://peer0:peer0pw@localhost:$ca_port \
        --caname $ca_name -M "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls" \
        --enrollment.profile tls --csr.hosts peer0.$org_domain --csr.hosts localhost \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    # Rename TLS files
    cp "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/tlscacerts/"* \
       "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/ca.crt"
    cp "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/signcerts/"* \
       "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/server.crt"
    cp "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/keystore/"* \
       "$ORG_DIR/peerOrganizations/$org_domain/peers/peer0.$org_domain/tls/server.key"
    
    # Enroll user
    fabric-ca-client enroll -u https://user1:user1pw@localhost:$ca_port \
        --caname $ca_name -M "$ORG_DIR/peerOrganizations/$org_domain/users/User1@$org_domain/msp" \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    cp "$ORG_DIR/peerOrganizations/$org_domain/msp/config.yaml" \
       "$ORG_DIR/peerOrganizations/$org_domain/users/User1@$org_domain/msp/config.yaml"
    
    # Enroll admin
    fabric-ca-client enroll -u https://org${org_name}admin:org${org_name}adminpw@localhost:$ca_port \
        --caname $ca_name -M "$ORG_DIR/peerOrganizations/$org_domain/users/Admin@$org_domain/msp" \
        --tls.certfiles "$ORG_DIR/fabric-ca/$(echo $org_name | tr '[:upper:]' '[:lower:]')/ca-cert.pem"
    
    cp "$ORG_DIR/peerOrganizations/$org_domain/msp/config.yaml" \
       "$ORG_DIR/peerOrganizations/$org_domain/users/Admin@$org_domain/msp/config.yaml"
    
    print_success "Organisation ${org_name} enrollée"
}

# Fonction pour enroller toutes les identités
enroll_all_identities() {
    print_info "Enrollment de toutes les identités..."
    
    # Wait for CAs to be ready
    wait_for_ca "ca-orderer" "10054"
    wait_for_ca "ca-afor" "7054"
    wait_for_ca "ca-cvgfr" "8054"
    wait_for_ca "ca-prefet" "9054"
    
    # Enroll orderer
    enroll_orderer
    
    # Enroll peer orgs
    enroll_peer_org "AFOR" "afor.foncier.ci" "7054"
    enroll_peer_org "CVGFR" "cvgfr.foncier.ci" "8054"
    enroll_peer_org "PREFET" "prefet.foncier.ci" "9054"
    
    print_success "Toutes les identités ont été enrollées"
}

# Main
case "$1" in
    start)
        create_directories
        create_ca_compose
        start_cas
        print_success "CAs démarrées avec succès"
        print_info "AFOR CA: https://localhost:7054"
        print_info "CVGFR CA: https://localhost:8054"
        print_info "PREFET CA: https://localhost:9054"
        print_info "Orderer CA: https://localhost:10054"
        ;;
    stop)
        stop_cas
        ;;
    enroll)
        enroll_all_identities
        ;;
    full)
        create_directories
        create_ca_compose
        start_cas
        sleep 5
        enroll_all_identities
        print_success "CAs démarrées et identités enrollées"
        ;;
    *)
        echo "Usage: $0 {start|stop|enroll|full}"
        echo "  start  - Démarre les CAs"
        echo "  stop   - Arrête les CAs"
        echo "  enroll - Enroll toutes les identités (CAs doivent être démarrées)"
        echo "  full   - Démarre les CAs et enroll les identités"
        exit 1
        ;;
esac
