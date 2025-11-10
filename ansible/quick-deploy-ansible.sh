#!/bin/bash

###############################################################################
# Script de Déploiement Rapide Ansible - Hyperledger Fabric Multi-VM
# Usage: ./quick-deploy-ansible.sh
###############################################################################

set -e  # Arrêter en cas d'erreur

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables
PROJECT_DIR="/home/absolue/my-blockchain"
INVENTORY_FILE="${PROJECT_DIR}/ansible/inventory/hosts.yml"
PLAYBOOK_DIR="${PROJECT_DIR}/ansible/playbooks"

###############################################################################
# Fonctions utilitaires
###############################################################################

print_header() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
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

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 n'est pas installé"
        return 1
    fi
    print_success "$1 est installé"
    return 0
}

###############################################################################
# Vérifications pré-déploiement
###############################################################################

check_prerequisites() {
    print_header "Vérification des Prérequis"
    
    local all_ok=true
    
    # Vérifier Ansible
    if check_command ansible; then
        ansible --version | head -n 1
    else
        all_ok=false
    fi
    
    # Vérifier Python
    if check_command python3; then
        python3 --version
    else
        all_ok=false
    fi
    
    # Vérifier rsync
    if check_command rsync; then
        rsync --version | head -n 1
    else
        all_ok=false
    fi
    
    # Vérifier SSH
    if check_command ssh; then
        ssh -V 2>&1 | head -n 1
    else
        all_ok=false
    fi
    
    # Vérifier l'inventaire
    if [ -f "$INVENTORY_FILE" ]; then
        print_success "Fichier d'inventaire trouvé: $INVENTORY_FILE"
    else
        print_error "Fichier d'inventaire non trouvé: $INVENTORY_FILE"
        all_ok=false
    fi
    
    # Vérifier les playbooks
    if [ -d "$PLAYBOOK_DIR" ]; then
        local playbook_count=$(ls -1 $PLAYBOOK_DIR/*.yml 2>/dev/null | wc -l)
        print_success "$playbook_count playbooks trouvés"
    else
        print_error "Répertoire playbooks non trouvé: $PLAYBOOK_DIR"
        all_ok=false
    fi
    
    # Vérifier la collection community.docker
    if ansible-galaxy collection list | grep -q "community.docker"; then
        print_success "Collection community.docker installée"
    else
        print_warning "Collection community.docker non installée"
        print_info "Installation en cours..."
        ansible-galaxy collection install community.docker
    fi
    
    if [ "$all_ok" = false ]; then
        print_error "Des prérequis sont manquants. Installation nécessaire."
        echo ""
        echo "Pour installer les prérequis sur Ubuntu:"
        echo "  sudo apt update"
        echo "  sudo apt install -y ansible python3-pip rsync openssh-client"
        echo "  ansible-galaxy collection install community.docker"
        exit 1
    fi
    
    print_success "Tous les prérequis sont satisfaits"
}

###############################################################################
# Configuration de l'inventaire
###############################################################################

check_inventory_ips() {
    print_header "Vérification de la Configuration des IPs"
    
    # Extraire les IPs de l'inventaire
    local vm1_ip=$(grep -A 1 "vm1-afor:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm2_ip=$(grep -A 1 "vm2-cvgfr:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm3_ip=$(grep -A 1 "vm3-prefet:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm4_ip=$(grep -A 1 "vm4-orderer:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    
    echo "VMs configurées:"
    echo "  VM1 (AFOR):   $vm1_ip"
    echo "  VM2 (CVGFR):  $vm2_ip"
    echo "  VM3 (PREFET): $vm3_ip"
    echo "  VM4 (Orderer):$vm4_ip"
    echo ""
    
    # Vérifier si les IPs sont les valeurs par défaut
    if [[ "$vm1_ip" == "10.0.1.10" ]] || [[ "$vm2_ip" == "10.0.2.10" ]] || \
       [[ "$vm3_ip" == "10.0.3.10" ]] || [[ "$vm4_ip" == "10.0.4.10" ]]; then
        print_warning "Les IPs par défaut sont configurées!"
        print_info "Veuillez modifier ${INVENTORY_FILE} avec vos vraies IPs"
        
        read -p "Voulez-vous continuer quand même? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "IPs personnalisées détectées"
    fi
}

###############################################################################
# Test de connectivité
###############################################################################

test_connectivity() {
    print_header "Test de Connectivité SSH"
    
    print_info "Test de connexion Ansible vers toutes les VMs..."
    
    if ansible all -i $INVENTORY_FILE -m ping -o; then
        print_success "Toutes les VMs sont accessibles via SSH"
    else
        print_error "Impossible de se connecter à certaines VMs"
        print_info "Assurez-vous que:"
        echo "  1. Les VMs sont démarrées"
        echo "  2. Les IPs sont correctes dans $INVENTORY_FILE"
        echo "  3. Vous avez copié votre clé SSH: ssh-copy-id ubuntu@<VM_IP>"
        exit 1
    fi
}

###############################################################################
# Génération du matériel cryptographique
###############################################################################

generate_crypto_material() {
    print_header "Génération du Matériel Cryptographique"
    
    local crypto_path="${PROJECT_DIR}/network/organizations"
    
    if [ -d "$crypto_path/peerOrganizations" ] && [ -d "$crypto_path/ordererOrganizations" ]; then
        print_warning "Matériel cryptographique existant trouvé"
        read -p "Voulez-vous le regénérer? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_info "Suppression de l'ancien matériel..."
            rm -rf $crypto_path
        else
            print_info "Utilisation du matériel existant"
            return 0
        fi
    fi
    
    print_info "Génération des certificats avec cryptogen..."
    
    cd $PROJECT_DIR
    
    if cryptogen generate \
        --config=./network/crypto-config.yaml \
        --output=./network/organizations; then
        print_success "Certificats générés avec succès"
        
        # Afficher un résumé
        local peer_orgs=$(ls -1 $crypto_path/peerOrganizations | wc -l)
        local orderer_orgs=$(ls -1 $crypto_path/ordererOrganizations | wc -l)
        print_info "$peer_orgs organisations peer créées"
        print_info "$orderer_orgs organisation orderer créée"
    else
        print_error "Échec de la génération des certificats"
        print_info "Vérifiez que cryptogen est installé et que crypto-config.yaml est valide"
        exit 1
    fi
}

###############################################################################
# Package du chaincode
###############################################################################

package_chaincode() {
    print_header "Package du Chaincode Java"
    
    local chaincode_dir="${PROJECT_DIR}/chaincode-java"
    local target_dir="${chaincode_dir}/target"
    
    if [ ! -d "$chaincode_dir" ]; then
        print_error "Répertoire chaincode non trouvé: $chaincode_dir"
        exit 1
    fi
    
    # Vérifier si un package existe déjà
    if ls $target_dir/*.tar.gz 1> /dev/null 2>&1; then
        print_warning "Package chaincode existant trouvé"
        read -p "Voulez-vous recompiler? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Utilisation du package existant"
            return 0
        fi
    fi
    
    print_info "Compilation du chaincode avec Maven..."
    
    cd $chaincode_dir
    
    if mvn clean package -DskipTests; then
        print_success "Chaincode compilé avec succès"
        
        # Vérifier que le package a été créé
        if ls $target_dir/*.tar.gz 1> /dev/null 2>&1; then
            local package_file=$(ls -1 $target_dir/*.tar.gz | head -n 1)
            print_info "Package: $(basename $package_file)"
            print_info "Taille: $(du -h $package_file | cut -f1)"
        else
            print_error "Package non trouvé après compilation"
            exit 1
        fi
    else
        print_error "Échec de la compilation du chaincode"
        exit 1
    fi
    
    cd $PROJECT_DIR
}

###############################################################################
# Exécution des playbooks
###############################################################################

run_playbook() {
    local playbook=$1
    local description=$2
    
    print_header "$description"
    
    print_info "Exécution: $playbook"
    
    if ansible-playbook -i $INVENTORY_FILE $playbook; then
        print_success "Playbook terminé avec succès"
    else
        print_error "Échec du playbook"
        exit 1
    fi
}

run_all_playbooks() {
    print_header "Déploiement Complet du Réseau"
    
    print_info "Le déploiement va exécuter toutes les phases automatiquement"
    print_warning "Durée estimée: 15-20 minutes"
    echo ""
    
    read -p "Voulez-vous continuer? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Déploiement annulé"
        exit 0
    fi
    
    # Enregistrer l'heure de début
    local start_time=$(date +%s)
    
    # Exécuter le playbook master
    run_playbook "${PLAYBOOK_DIR}/deploy-all.yml" "Déploiement Complet (Master Playbook)"
    
    # Calculer la durée
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    print_success "Déploiement terminé en ${minutes}m ${seconds}s"
}

###############################################################################
# Vérification post-déploiement
###############################################################################

verify_deployment() {
    print_header "Vérification du Déploiement"
    
    print_info "Vérification des conteneurs Docker..."
    ansible all -i $INVENTORY_FILE -m shell \
        -a "docker ps --format 'table {{.Names}}\t{{.Status}}'" -b || true
    
    echo ""
    print_info "Test de l'API REST..."
    
    local vm1_ip=$(grep -A 1 "vm1-afor:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    
    if curl -s -f "http://${vm1_ip}:3000/api/health" > /dev/null; then
        print_success "API REST est accessible"
        curl -s "http://${vm1_ip}:3000/api/health" | jq '.' || true
    else
        print_warning "API REST ne répond pas encore (peut nécessiter quelques secondes)"
    fi
}

###############################################################################
# Affichage des informations finales
###############################################################################

display_final_info() {
    print_header "Informations de Connexion"
    
    local vm1_ip=$(grep -A 1 "vm1-afor:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm2_ip=$(grep -A 1 "vm2-cvgfr:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm3_ip=$(grep -A 1 "vm3-prefet:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    local vm4_ip=$(grep -A 1 "vm4-orderer:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         DÉPLOIEMENT HYPERLEDGER FABRIC RÉUSSI !              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "📦 Réseau Déployé:"
    echo "   • Orderer:     ${vm4_ip}:7050"
    echo "   • Peer AFOR:   ${vm1_ip}:7051"
    echo "   • Peer CVGFR:  ${vm2_ip}:8051"
    echo "   • Peer PREFET: ${vm3_ip}:9051"
    echo ""
    echo "🔗 Channel: contrat-agraire"
    echo "📜 Chaincode: contrat-agraire-cc v4.0"
    echo ""
    echo "🌐 API REST:"
    echo "   • URL: http://${vm1_ip}:3000"
    echo "   • Health: http://${vm1_ip}:3000/api/health"
    echo "   • Swagger: http://${vm1_ip}:3000/api-docs"
    echo ""
    echo "🔐 Authentification Keycloak:"
    echo "   • URL: https://auth.digifor2.afor-ci.app"
    echo "   • Realm: digifor2"
    echo "   • Client: iam-user-auth"
    echo ""
    echo "📊 Métriques Prometheus:"
    echo "   • Orderer: http://${vm4_ip}:9443/metrics"
    echo "   • AFOR:    http://${vm1_ip}:9447/metrics"
    echo "   • CVGFR:   http://${vm2_ip}:9448/metrics"
    echo "   • PREFET:  http://${vm3_ip}:9449/metrics"
    echo ""
    echo "📚 Commandes utiles:"
    echo "   • Statut: ansible all -i $INVENTORY_FILE -m shell -a 'docker ps' -b"
    echo "   • Logs: ansible vm1-afor -i $INVENTORY_FILE -m shell -a 'docker logs peer0.afor.foncier.ci' -b"
    echo "   • Redémarrer: ansible all -i $INVENTORY_FILE -m shell -a 'cd /opt/fabric && docker-compose restart' -b"
    echo ""
    print_success "Déploiement complet terminé avec succès!"
}

###############################################################################
# Menu principal
###############################################################################

show_menu() {
    clear
    print_header "Déploiement Ansible - Hyperledger Fabric Multi-VM"
    
    echo "Choisissez une option:"
    echo ""
    echo "  1) Déploiement Complet Automatique (recommandé)"
    echo "  2) Vérifications Seulement (sans déploiement)"
    echo "  3) Générer Uniquement le Matériel Cryptographique"
    echo "  4) Tester la Connectivité SSH"
    echo "  5) Vérifier l'État du Déploiement Actuel"
    echo "  6) Afficher les Logs"
    echo "  0) Quitter"
    echo ""
    read -p "Votre choix: " choice
    
    case $choice in
        1)
            check_prerequisites
            check_inventory_ips
            test_connectivity
            generate_crypto_material
            package_chaincode
            run_all_playbooks
            verify_deployment
            display_final_info
            ;;
        2)
            check_prerequisites
            check_inventory_ips
            test_connectivity
            print_success "Toutes les vérifications sont OK"
            ;;
        3)
            generate_crypto_material
            ;;
        4)
            test_connectivity
            ;;
        5)
            verify_deployment
            ;;
        6)
            local vm1_ip=$(grep -A 1 "vm1-afor:" $INVENTORY_FILE | grep "ansible_host:" | awk '{print $2}')
            echo "Logs disponibles:"
            echo "  API: ssh ubuntu@${vm1_ip} 'tail -f /opt/fabric/api/logs/api.log'"
            echo "  Peer: ansible vm1-afor -i $INVENTORY_FILE -m shell -a 'docker logs -f peer0.afor.foncier.ci' -b"
            ;;
        0)
            print_info "Au revoir!"
            exit 0
            ;;
        *)
            print_error "Option invalide"
            sleep 2
            show_menu
            ;;
    esac
}

###############################################################################
# Point d'entrée
###############################################################################

main() {
    # Si des arguments sont passés, exécuter en mode automatique
    if [ $# -gt 0 ]; then
        case $1 in
            --auto|--full|-f)
                check_prerequisites
                check_inventory_ips
                test_connectivity
                generate_crypto_material
                package_chaincode
                run_all_playbooks
                verify_deployment
                display_final_info
                ;;
            --check|-c)
                check_prerequisites
                check_inventory_ips
                test_connectivity
                ;;
            --crypto)
                generate_crypto_material
                ;;
            --help|-h)
                echo "Usage: $0 [OPTION]"
                echo ""
                echo "Options:"
                echo "  --auto, -f      Déploiement complet automatique"
                echo "  --check, -c     Vérifications seulement"
                echo "  --crypto        Générer le matériel cryptographique"
                echo "  --help, -h      Afficher cette aide"
                echo "  (aucune)        Menu interactif"
                ;;
            *)
                print_error "Option inconnue: $1"
                echo "Utilisez --help pour voir les options disponibles"
                exit 1
                ;;
        esac
    else
        # Mode interactif
        show_menu
    fi
}

# Exécution
main "$@"
