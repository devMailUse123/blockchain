#!/bin/bash
#
# Entrypoint pour l'image deployer
# Commandes disponibles : generate-crypto, create-channel, deploy-chaincode, deploy-all
#

set -e

PROJECT_ROOT=${PROJECT_ROOT:-/opt/blockchain}
FABRIC_CFG_PATH=${FABRIC_CFG_PATH:-/etc/hyperledger/fabric}

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Fonction : Générer les certificats
generate_crypto() {
    log_info "Génération des certificats MSP..."
    cd ${PROJECT_ROOT}
    
    if [ -d "network/organizations/ordererOrganizations" ]; then
        log_warning "Certificats déjà existants, skip"
        return 0
    fi
    
    # Utiliser cryptogen
    cryptogen generate \
        --config=${FABRIC_CFG_PATH}/crypto-config.yaml \
        --output=${PROJECT_ROOT}/network/organizations
    
    log_success "Certificats générés"
}

# Fonction : Créer le genesis block et channel
create_channel_artifacts() {
    log_info "Création des artefacts du channel..."
    cd ${PROJECT_ROOT}
    
    if [ -f "network/channel-artifacts/${CHANNEL_NAME}.block" ]; then
        log_warning "Genesis block existe déjà, skip"
        return 0
    fi
    
    # Genesis block pour le channel
    configtxgen \
        -profile ThreeOrgsChannel \
        -outputBlock network/channel-artifacts/${CHANNEL_NAME}.block \
        -channelID ${CHANNEL_NAME} \
        -configPath ${FABRIC_CFG_PATH}
    
    log_success "Genesis block créé : ${CHANNEL_NAME}.block"
}

# Fonction : Packager le chaincode
package_chaincode() {
    log_info "Packaging du chaincode..."
    cd ${PROJECT_ROOT}
    
    local PACKAGE_FILE="chaincode/packages/${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz"
    
    if [ -f "${PACKAGE_FILE}" ]; then
        log_warning "Chaincode package existe déjà"
        return 0
    fi
    
    # Vérifier si le JAR existe
    local JAR_FILE=$(find chaincode -name "*.jar" -type f | head -1)
    
    if [ -z "$JAR_FILE" ]; then
        log_error "Aucun JAR trouvé dans chaincode/"
        return 1
    fi
    
    log_info "Utilisation du JAR : ${JAR_FILE}"
    
    # Créer metadata.json
    cat > chaincode/metadata.json <<EOF
{
    "type": "java",
    "label": "${CHAINCODE_NAME}_${CHAINCODE_VERSION}"
}
EOF
    
    # Créer connection.json
    mkdir -p chaincode/connection
    cat > chaincode/connection/connection.json <<EOF
{
    "address": "${CHAINCODE_NAME}:9999",
    "dial_timeout": "10s",
    "tls_required": false
}
EOF
    
    # Créer le package
    cd chaincode
    tar czf "packages/${CHAINCODE_NAME}_${CHAINCODE_VERSION}.tar.gz" \
        metadata.json \
        connection/connection.json \
        $(basename ${JAR_FILE})
    
    cd ${PROJECT_ROOT}
    log_success "Chaincode packagé : ${PACKAGE_FILE}"
}

# Fonction : Attendre que les peers soient prêts
wait_for_peers() {
    log_info "Attente des peers..."
    
    local PEERS=(
        "peer0.afor.foncier.ci:7051"
        "peer0.cvgfr.foncier.ci:8051"
        "peer0.prefet.foncier.ci:9051"
    )
    
    for PEER in "${PEERS[@]}"; do
        local HOST=$(echo $PEER | cut -d: -f1)
        local PORT=$(echo $PEER | cut -d: -f2)
        
        log_info "Vérification $HOST:$PORT..."
        
        local RETRY=0
        local MAX_RETRY=30
        
        until nc -z $HOST $PORT || [ $RETRY -eq $MAX_RETRY ]; do
            RETRY=$((RETRY + 1))
            log_warning "Tentative $RETRY/$MAX_RETRY..."
            sleep 2
        done
        
        if [ $RETRY -eq $MAX_RETRY ]; then
            log_error "Peer $HOST:$PORT inaccessible"
            return 1
        fi
        
        log_success "Peer $HOST:$PORT prêt"
    done
}

# Fonction : Déploiement complet
deploy_all() {
    log_info "Déploiement complet du réseau Fabric..."
    
    generate_crypto
    create_channel_artifacts
    package_chaincode
    
    log_success "Préparation terminée !"
    log_info "Les peers peuvent maintenant être démarrés"
    log_info "Ensuite, exécuter 'join-channel' et 'install-chaincode'"
}

# Fonction : Join channel (à exécuter après démarrage peers)
join_channel() {
    log_info "Join du channel par les peers..."
    wait_for_peers
    
    cd ${PROJECT_ROOT}/scripts
    ./join-channels.sh
    
    log_success "Peers ont rejoint le channel"
}

# Fonction : Installer et approuver chaincode
install_chaincode() {
    log_info "Installation et approbation du chaincode..."
    wait_for_peers
    
    cd ${PROJECT_ROOT}/scripts
    ./package-chaincode.sh
    
    log_success "Chaincode déployé"
}

# Afficher l'aide
show_help() {
    cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  DEPLOYER IMAGE - Hyperledger Fabric
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commandes disponibles :

  generate-crypto       Générer les certificats MSP
  create-channel        Créer genesis block et artefacts channel
  package-chaincode     Packager le chaincode en .tar.gz
  deploy-all           Exécuter toutes les étapes ci-dessus
  
  join-channel         Joindre le channel (après démarrage peers)
  install-chaincode    Installer et approuver le chaincode
  
  help                 Afficher cette aide

Usage:
  docker run foncier-deployer:1.0 <commande>

Exemples:
  docker run -v fabric-data:/opt/blockchain/network foncier-deployer:1.0 deploy-all
  docker run foncier-deployer:1.0 join-channel

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# Router les commandes
case "$1" in
    generate-crypto)
        generate_crypto
        ;;
    create-channel)
        create_channel_artifacts
        ;;
    package-chaincode)
        package_chaincode
        ;;
    deploy-all)
        deploy_all
        ;;
    join-channel)
        join_channel
        ;;
    install-chaincode)
        install_chaincode
        ;;
    help|*)
        show_help
        ;;
esac
