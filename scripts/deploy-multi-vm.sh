#!/bin/bash
#
# Script de déploiement automatisé multi-VM
# Blockchain Foncière - Côte d'Ivoire
# 
# Usage: ./deploy-multi-vm.sh [init|deploy|start|stop|clean]
#

set -e

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration des VMs
# ⚠️ MODIFIER CES IP AVEC VOS VRAIES IPS
VM1_IP="REMPLACER_PAR_IP_VM1"  # AFOR
VM2_IP="REMPLACER_PAR_IP_VM2"  # CVGFR
VM3_IP="REMPLACER_PAR_IP_VM3"  # PREFET
VM4_IP="REMPLACER_PAR_IP_VM4"  # Orderer

VM1_USER="ubuntu"
VM2_USER="ubuntu"
VM3_USER="ubuntu"
VM4_USER="ubuntu"

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_rsa}"

# Vérifier la configuration
check_config() {
    echo -e "${YELLOW}📋 Vérification de la configuration...${NC}"
    
    if [[ "$VM1_IP" == "REMPLACER_PAR_IP_VM1" ]]; then
        echo -e "${RED}❌ Erreur: Vous devez configurer les IPs des VMs dans le script${NC}"
        echo -e "${YELLOW}   Éditez ce fichier et remplacez REMPLACER_PAR_IP_VMX par les vraies IPs${NC}"
        exit 1
    fi
    
    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}❌ Erreur: Clé SSH non trouvée: $SSH_KEY${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Configuration OK${NC}\n"
}

# Fonction pour exécuter une commande sur une VM
run_on_vm() {
    local vm_ip=$1
    local vm_user=$2
    local command=$3
    
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "${vm_user}@${vm_ip}" "$command"
}

# Fonction pour copier un fichier vers une VM
copy_to_vm() {
    local vm_ip=$1
    local vm_user=$2
    local src=$3
    local dest=$4
    
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -r "$src" "${vm_user}@${vm_ip}:${dest}"
}

# =============================================================================
# ÉTAPE 1: Initialisation des VMs
# =============================================================================
init_vms() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ÉTAPE 1: INITIALISATION DES VMs${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    local vms=("$VM1_IP:$VM1_USER:AFOR" "$VM2_IP:$VM2_USER:CVGFR" "$VM3_IP:$VM3_USER:PREFET" "$VM4_IP:$VM4_USER:Orderer")
    
    for vm_info in "${vms[@]}"; do
        IFS=':' read -r vm_ip vm_user vm_name <<< "$vm_info"
        
        echo -e "${YELLOW}📦 Configuration de $vm_name ($vm_ip)...${NC}"
        
        # Créer les répertoires
        run_on_vm "$vm_ip" "$vm_user" "sudo mkdir -p /opt/fabric/{organizations,chaincode,channel-artifacts,api} && sudo chown -R ${vm_user}:${vm_user} /opt/fabric"
        
        # Installer Docker si non présent
        run_on_vm "$vm_ip" "$vm_user" "which docker || (curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh && sudo usermod -aG docker ${vm_user})"
        
        # Installer Docker Compose si non présent
        run_on_vm "$vm_ip" "$vm_user" "which docker-compose || sudo curl -L 'https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)' -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
        
        echo -e "${GREEN}✅ $vm_name configurée${NC}\n"
    done
    
    echo -e "${GREEN}✅ Toutes les VMs sont initialisées${NC}\n"
}

# =============================================================================
# ÉTAPE 2: Génération et distribution des certificats
# =============================================================================
generate_certificates() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ÉTAPE 2: GÉNÉRATION DES CERTIFICATS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}🔐 Génération des certificats avec cryptogen...${NC}"
    
    # Vérifier que cryptogen est installé
    if ! command -v cryptogen &> /dev/null; then
        echo -e "${RED}❌ cryptogen non trouvé. Installer les binaries Hyperledger Fabric${NC}"
        echo -e "${YELLOW}   curl -sSL https://bit.ly/2ysbOFE | bash -s -- 3.1.1 1.5.15${NC}"
        exit 1
    fi
    
    # Générer les certificats
    cd "$(dirname "$0")/.."
    cryptogen generate --config=./network/crypto-config.yaml --output=./network/organizations
    
    echo -e "${GREEN}✅ Certificats générés${NC}\n"
}

distribute_certificates() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ÉTAPE 3: DISTRIBUTION DES CERTIFICATS${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    cd "$(dirname "$0")/.."
    
    echo -e "${YELLOW}📦 Copie des certificats vers VM1 (AFOR)...${NC}"
    copy_to_vm "$VM1_IP" "$VM1_USER" "./network/organizations/peerOrganizations/afor.foncier.ci" "/opt/fabric/organizations/"
    copy_to_vm "$VM1_IP" "$VM1_USER" "./network/organizations/ordererOrganizations" "/opt/fabric/organizations/"
    
    echo -e "${YELLOW}📦 Copie des certificats vers VM2 (CVGFR)...${NC}"
    copy_to_vm "$VM2_IP" "$VM2_USER" "./network/organizations/peerOrganizations/cvgfr.foncier.ci" "/opt/fabric/organizations/"
    copy_to_vm "$VM2_IP" "$VM2_USER" "./network/organizations/ordererOrganizations" "/opt/fabric/organizations/"
    
    echo -e "${YELLOW}📦 Copie des certificats vers VM3 (PREFET)...${NC}"
    copy_to_vm "$VM3_IP" "$VM3_USER" "./network/organizations/peerOrganizations/prefet.foncier.ci" "/opt/fabric/organizations/"
    copy_to_vm "$VM3_IP" "$VM3_USER" "./network/organizations/ordererOrganizations" "/opt/fabric/organizations/"
    
    echo -e "${YELLOW}📦 Copie des certificats vers VM4 (Orderer)...${NC}"
    copy_to_vm "$VM4_IP" "$VM4_USER" "./network/organizations/ordererOrganizations/foncier.ci" "/opt/fabric/organizations/"
    copy_to_vm "$VM4_IP" "$VM4_USER" "./network/organizations/peerOrganizations" "/opt/fabric/organizations/"
    
    echo -e "${GREEN}✅ Certificats distribués${NC}\n"
}

# =============================================================================
# ÉTAPE 4: Configuration des docker-compose
# =============================================================================
configure_docker_compose() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ÉTAPE 4: CONFIGURATION DOCKER COMPOSE${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    cd "$(dirname "$0")/.."
    
    # Copier et configurer docker-compose pour chaque VM
    echo -e "${YELLOW}📝 Configuration VM1 (AFOR)...${NC}"
    cp ./deployment/vm1-afor/docker-compose.yml /tmp/docker-compose-vm1.yml
    sed -i "s/ORDERER_IP_HERE/$VM4_IP/g" /tmp/docker-compose-vm1.yml
    sed -i "s/CVGFR_IP_HERE/$VM2_IP/g" /tmp/docker-compose-vm1.yml
    sed -i "s/PREFET_IP_HERE/$VM3_IP/g" /tmp/docker-compose-vm1.yml
    copy_to_vm "$VM1_IP" "$VM1_USER" "/tmp/docker-compose-vm1.yml" "/opt/fabric/docker-compose.yml"
    
    echo -e "${YELLOW}📝 Configuration VM2 (CVGFR)...${NC}"
    cp ./deployment/vm2-cvgfr/docker-compose.yml /tmp/docker-compose-vm2.yml
    sed -i "s/ORDERER_IP_HERE/$VM4_IP/g" /tmp/docker-compose-vm2.yml
    sed -i "s/AFOR_IP_HERE/$VM1_IP/g" /tmp/docker-compose-vm2.yml
    sed -i "s/PREFET_IP_HERE/$VM3_IP/g" /tmp/docker-compose-vm2.yml
    copy_to_vm "$VM2_IP" "$VM2_USER" "/tmp/docker-compose-vm2.yml" "/opt/fabric/docker-compose.yml"
    
    echo -e "${YELLOW}📝 Configuration VM3 (PREFET)...${NC}"
    cp ./deployment/vm3-prefet/docker-compose.yml /tmp/docker-compose-vm3.yml
    sed -i "s/ORDERER_IP_HERE/$VM4_IP/g" /tmp/docker-compose-vm3.yml
    sed -i "s/AFOR_IP_HERE/$VM1_IP/g" /tmp/docker-compose-vm3.yml
    sed -i "s/CVGFR_IP_HERE/$VM2_IP/g" /tmp/docker-compose-vm3.yml
    copy_to_vm "$VM3_IP" "$VM3_USER" "/tmp/docker-compose-vm3.yml" "/opt/fabric/docker-compose.yml"
    
    echo -e "${YELLOW}📝 Configuration VM4 (Orderer)...${NC}"
    cp ./deployment/vm4-orderer/docker-compose.yml /tmp/docker-compose-vm4.yml
    sed -i "s/AFOR_IP_HERE/$VM1_IP/g" /tmp/docker-compose-vm4.yml
    sed -i "s/CVGFR_IP_HERE/$VM2_IP/g" /tmp/docker-compose-vm4.yml
    sed -i "s/PREFET_IP_HERE/$VM3_IP/g" /tmp/docker-compose-vm4.yml
    copy_to_vm "$VM4_IP" "$VM4_USER" "/tmp/docker-compose-vm4.yml" "/opt/fabric/docker-compose.yml"
    
    echo -e "${GREEN}✅ Docker Compose configurés${NC}\n"
}

# =============================================================================
# ÉTAPE 5: Démarrage du réseau
# =============================================================================
start_network() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ÉTAPE 5: DÉMARRAGE DU RÉSEAU${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    # Démarrer l'orderer en premier
    echo -e "${YELLOW}🚀 Démarrage Orderer (VM4)...${NC}"
    run_on_vm "$VM4_IP" "$VM4_USER" "cd /opt/fabric && docker-compose up -d"
    sleep 10
    
    # Démarrer les peers
    echo -e "${YELLOW}🚀 Démarrage Peer AFOR (VM1)...${NC}"
    run_on_vm "$VM1_IP" "$VM1_USER" "cd /opt/fabric && docker-compose up -d"
    
    echo -e "${YELLOW}🚀 Démarrage Peer CVGFR (VM2)...${NC}"
    run_on_vm "$VM2_IP" "$VM2_USER" "cd /opt/fabric && docker-compose up -d"
    
    echo -e "${YELLOW}🚀 Démarrage Peer PREFET (VM3)...${NC}"
    run_on_vm "$VM3_IP" "$VM3_USER" "cd /opt/fabric && docker-compose up -d"
    
    echo -e "\n${GREEN}✅ Réseau démarré${NC}\n"
    
    # Vérifier le statut
    echo -e "${YELLOW}📊 Statut des conteneurs:${NC}\n"
    echo -e "${BLUE}VM1 (AFOR):${NC}"
    run_on_vm "$VM1_IP" "$VM1_USER" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
    echo ""
    echo -e "${BLUE}VM2 (CVGFR):${NC}"
    run_on_vm "$VM2_IP" "$VM2_USER" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
    echo ""
    echo -e "${BLUE}VM3 (PREFET):${NC}"
    run_on_vm "$VM3_IP" "$VM3_USER" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
    echo ""
    echo -e "${BLUE}VM4 (Orderer):${NC}"
    run_on_vm "$VM4_IP" "$VM4_USER" "docker ps --format 'table {{.Names}}\t{{.Status}}'"
}

# =============================================================================
# ÉTAPE 6: Arrêt du réseau
# =============================================================================
stop_network() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  ARRÊT DU RÉSEAU${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}🛑 Arrêt VM1 (AFOR)...${NC}"
    run_on_vm "$VM1_IP" "$VM1_USER" "cd /opt/fabric && docker-compose down"
    
    echo -e "${YELLOW}🛑 Arrêt VM2 (CVGFR)...${NC}"
    run_on_vm "$VM2_IP" "$VM2_USER" "cd /opt/fabric && docker-compose down"
    
    echo -e "${YELLOW}🛑 Arrêt VM3 (PREFET)...${NC}"
    run_on_vm "$VM3_IP" "$VM3_USER" "cd /opt/fabric && docker-compose down"
    
    echo -e "${YELLOW}🛑 Arrêt VM4 (Orderer)...${NC}"
    run_on_vm "$VM4_IP" "$VM4_USER" "cd /opt/fabric && docker-compose down"
    
    echo -e "${GREEN}✅ Réseau arrêté${NC}\n"
}

# =============================================================================
# ÉTAPE 7: Nettoyage complet
# =============================================================================
clean_all() {
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  NETTOYAGE COMPLET${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${RED}⚠️  Cette action va supprimer toutes les données !${NC}"
    read -p "Êtes-vous sûr ? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}Annulé${NC}"
        exit 0
    fi
    
    local vms=("$VM1_IP:$VM1_USER:AFOR" "$VM2_IP:$VM2_USER:CVGFR" "$VM3_IP:$VM3_USER:PREFET" "$VM4_IP:$VM4_USER:Orderer")
    
    for vm_info in "${vms[@]}"; do
        IFS=':' read -r vm_ip vm_user vm_name <<< "$vm_info"
        
        echo -e "${YELLOW}🧹 Nettoyage $vm_name ($vm_ip)...${NC}"
        run_on_vm "$vm_ip" "$vm_user" "cd /opt/fabric && docker-compose down -v && docker system prune -af && sudo rm -rf /opt/fabric/*"
    done
    
    echo -e "${GREEN}✅ Nettoyage terminé${NC}\n"
}

# =============================================================================
# Afficher l'aide
# =============================================================================
show_help() {
    cat << EOF
${BLUE}═══════════════════════════════════════════════════════════${NC}
${BLUE}  Script de Déploiement Multi-VM${NC}
${BLUE}  Blockchain Foncière - Côte d'Ivoire${NC}
${BLUE}═══════════════════════════════════════════════════════════${NC}

${YELLOW}Usage:${NC}
  $0 [commande]

${YELLOW}Commandes:${NC}
  ${GREEN}init${NC}        Initialiser les VMs (Docker, répertoires)
  ${GREEN}certs${NC}       Générer les certificats
  ${GREEN}distribute${NC}  Distribuer les certificats sur les VMs
  ${GREEN}configure${NC}   Configurer les docker-compose
  ${GREEN}start${NC}       Démarrer le réseau Fabric
  ${GREEN}stop${NC}        Arrêter le réseau
  ${GREEN}clean${NC}       Nettoyer toutes les VMs
  ${GREEN}deploy${NC}      Déploiement complet (certs + distribute + configure + start)
  ${GREEN}help${NC}        Afficher cette aide

${YELLOW}Exemples:${NC}
  # Déploiement complet
  $0 deploy
  
  # Redémarrage
  $0 stop && $0 start
  
  # Nettoyage
  $0 clean

${YELLOW}Configuration:${NC}
  Avant d'utiliser ce script, éditez-le et remplacez:
  - VM1_IP, VM2_IP, VM3_IP, VM4_IP par vos vraies IPs
  - SSH_KEY si vous utilisez une clé différente

EOF
}

# =============================================================================
# Main
# =============================================================================
main() {
    case "$1" in
        init)
            check_config
            init_vms
            ;;
        certs)
            generate_certificates
            ;;
        distribute)
            check_config
            distribute_certificates
            ;;
        configure)
            check_config
            configure_docker_compose
            ;;
        start)
            check_config
            start_network
            ;;
        stop)
            check_config
            stop_network
            ;;
        clean)
            check_config
            clean_all
            ;;
        deploy)
            check_config
            generate_certificates
            distribute_certificates
            configure_docker_compose
            start_network
            echo -e "\n${GREEN}✅✅✅ DÉPLOIEMENT MULTI-VM TERMINÉ AVEC SUCCÈS ! ✅✅✅${NC}\n"
            ;;
        help|--help|-h|"")
            show_help
            ;;
        *)
            echo -e "${RED}Commande inconnue: $1${NC}\n"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
