#!/bin/bash
# Script de vérification de la configuration Ansible
# Vérifie la connectivité SSH et Ansible avant le déploiement

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                                                                   ║"
echo "║     🔍 VÉRIFICATION CONFIGURATION ANSIBLE VPC 🔍                 ║"
echo "║                                                                   ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo ""

INVENTORY_FILE="$(dirname "$0")/inventory/hosts.yml"

# Vérifier que l'inventaire existe
if [ ! -f "$INVENTORY_FILE" ]; then
    echo -e "${RED}❌ Fichier d'inventaire introuvable: $INVENTORY_FILE${NC}"
    exit 1
fi

echo -e "${BLUE}📋 Configuration réseau VPC${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Extraire les IPs de l'inventaire
BASTION_IP=$(grep "bastion_host:" "$INVENTORY_FILE" | awk '{print $2}' | tr -d '"')
VM1_PUBLIC=$(grep -A 3 "vm1-afor:" "$INVENTORY_FILE" | grep "ansible_host:" | awk '{print $2}')
VM1_PRIVATE=$(grep -A 5 "vm1-afor:" "$INVENTORY_FILE" | grep "private_ip:" | head -1 | awk '{print $2}')
VM2_PRIVATE=$(grep -A 3 "vm2-cvgfr:" "$INVENTORY_FILE" | grep "private_ip:" | head -1 | awk '{print $2}')
VM3_PRIVATE=$(grep -A 3 "vm3-prefet:" "$INVENTORY_FILE" | grep "private_ip:" | head -1 | awk '{print $2}')
VM4_PRIVATE=$(grep -A 3 "vm4-orderer:" "$INVENTORY_FILE" | grep "private_ip:" | head -1 | awk '{print $2}')

echo "✅ VM1 (AFOR)   - IP Publique: $VM1_PUBLIC | IP Privée: $VM1_PRIVATE"
echo "✅ VM2 (CVGFR)  - IP Privée: $VM2_PRIVATE"
echo "✅ VM3 (PREFET) - IP Privée: $VM3_PRIVATE"
echo "✅ VM4 (Orderer)- IP Privée: $VM4_PRIVATE"
echo "🌐 Bastion Host: $BASTION_IP"
echo ""

# Vérifier Ansible
echo -e "${BLUE}🔧 Vérification des prérequis${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v ansible &> /dev/null; then
    echo -e "${RED}❌ Ansible n'est pas installé${NC}"
    echo ""
    echo "Installation:"
    echo "  sudo apt update"
    echo "  sudo apt install -y ansible"
    exit 1
else
    ANSIBLE_VERSION=$(ansible --version | head -1)
    echo -e "${GREEN}✅ $ANSIBLE_VERSION${NC}"
fi

# Vérifier la clé SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${YELLOW}⚠️  Clé SSH ~/.ssh/id_rsa introuvable${NC}"
    echo ""
    echo "Générer une clé SSH:"
    echo "  ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''"
    echo ""
else
    echo -e "${GREEN}✅ Clé SSH trouvée: ~/.ssh/id_rsa${NC}"
fi

echo ""

# Test de connectivité SSH au bastion
echo -e "${BLUE}🔐 Test de connectivité SSH${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -n "🔍 Test connexion VM1 (Bastion $VM1_PUBLIC)... "
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes ubuntu@$VM1_PUBLIC exit 2>/dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
    BASTION_OK=true
else
    echo -e "${RED}❌ ÉCHEC${NC}"
    echo ""
    echo -e "${YELLOW}Configuration SSH nécessaire:${NC}"
    echo "  ssh-copy-id ubuntu@$VM1_PUBLIC"
    echo ""
    BASTION_OK=false
fi

if [ "$BASTION_OK" = true ]; then
    echo -n "🔍 Test ProxyJump VM2 (via bastion)... "
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
        -o ProxyJump=ubuntu@$VM1_PUBLIC ubuntu@$VM2_PRIVATE exit 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        echo -e "${YELLOW}Copier les clés depuis VM1:${NC}"
        echo "  ssh ubuntu@$VM1_PUBLIC"
        echo "  ssh-copy-id ubuntu@$VM2_PRIVATE"
    fi

    echo -n "🔍 Test ProxyJump VM3 (via bastion)... "
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
        -o ProxyJump=ubuntu@$VM1_PUBLIC ubuntu@$VM3_PRIVATE exit 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
    fi

    echo -n "🔍 Test ProxyJump VM4 (via bastion)... "
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes \
        -o ProxyJump=ubuntu@$VM1_PUBLIC ubuntu@$VM4_PRIVATE exit 2>/dev/null; then
        echo -e "${GREEN}✅ OK${NC}"
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
    fi
fi

echo ""

# Test Ansible ping
echo -e "${BLUE}🤖 Test Ansible${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$BASTION_OK" = true ]; then
    echo "🔍 Test ansible ping sur tous les hôtes..."
    echo ""
    ansible all -i "$INVENTORY_FILE" -m ping
    EXIT_CODE=$?
    echo ""
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}✅ CONFIGURATION VALIDÉE - PRÊT POUR LE DÉPLOIEMENT ! ✅${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "🚀 Lancer le déploiement:"
        echo "   ./ansible/quick-deploy-ansible.sh --auto"
        echo ""
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}❌ CERTAINS HÔTES NE SONT PAS ACCESSIBLES${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "📚 Consulter la documentation:"
        echo "   cat ansible/VPC-SETUP-QUICK.md"
    fi
else
    echo -e "${YELLOW}⚠️  Impossible de tester Ansible sans connexion au bastion${NC}"
    echo ""
    echo "📝 Étapes de configuration SSH:"
    echo ""
    echo "1. Copier votre clé sur le bastion (VM1):"
    echo "   ssh-copy-id ubuntu@$VM1_PUBLIC"
    echo ""
    echo "2. Se connecter au bastion:"
    echo "   ssh ubuntu@$VM1_PUBLIC"
    echo ""
    echo "3. Depuis le bastion, copier les clés vers les autres VMs:"
    echo "   ssh-copy-id ubuntu@$VM2_PRIVATE"
    echo "   ssh-copy-id ubuntu@$VM3_PRIVATE"
    echo "   ssh-copy-id ubuntu@$VM4_PRIVATE"
    echo ""
    echo "4. Quitter le bastion et relancer ce script:"
    echo "   exit"
    echo "   ./ansible/verify-setup.sh"
fi

echo ""
