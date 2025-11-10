#!/bin/bash
# Script pour copier la clé SSH sur toutes les VMs via VM1 (bastion)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SSH_KEY=~/.ssh/id_ed25519_blockchain_vm
SSH_PUB_KEY=~/.ssh/id_ed25519_blockchain_vm.pub
VM1_IP="18.194.235.149"
VM2_IP="10.0.1.158"
VM3_IP="10.0.2.245"
VM4_IP="10.0.3.162"

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║     🔑 CONFIGURATION SSH POUR TOUTES LES VMs 🔑                  ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier que les clés existent
if [ ! -f "$SSH_KEY" ]; then
    echo -e "${RED}❌ Clé privée non trouvée: $SSH_KEY${NC}"
    exit 1
fi

if [ ! -f "$SSH_PUB_KEY" ]; then
    echo -e "${RED}❌ Clé publique non trouvée: $SSH_PUB_KEY${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Clés SSH trouvées${NC}"
echo "  Clé privée: $SSH_KEY"
echo "  Clé publique: $SSH_PUB_KEY"
echo ""

# Lire le contenu de la clé publique
PUB_KEY_CONTENT=$(cat $SSH_PUB_KEY)

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}ÉTAPE 1: Configurer VM1 (Bastion)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "🔧 Copie de la clé privée sur VM1..."
scp -i $SSH_KEY $SSH_KEY ubuntu@$VM1_IP:~/.ssh/ 2>/dev/null && echo -e "${GREEN}✅ Clé privée copiée${NC}" || echo -e "${YELLOW}⚠️  Déjà présente${NC}"

echo "🔧 Configuration des permissions sur VM1..."
ssh -i $SSH_KEY ubuntu@$VM1_IP "chmod 600 ~/.ssh/id_ed25519_blockchain_vm" && echo -e "${GREEN}✅ Permissions configurées${NC}"

echo ""

# Fonction pour ajouter la clé sur une VM distante via VM1
add_key_to_vm() {
    local VM_NAME=$1
    local VM_IP=$2
    
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Configuration $VM_NAME ($VM_IP)${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Vérifier si la VM est accessible depuis VM1
    echo "🔍 Test de connectivité vers $VM_NAME..."
    if ssh -i $SSH_KEY ubuntu@$VM1_IP "timeout 5 nc -zv $VM_IP 22" 2>/dev/null; then
        echo -e "${GREEN}✅ $VM_NAME est accessible${NC}"
        
        # Ajouter la clé publique
        echo "🔑 Ajout de la clé publique sur $VM_NAME..."
        ssh -i $SSH_KEY ubuntu@$VM1_IP "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519_blockchain_vm ubuntu@$VM_IP 'mkdir -p ~/.ssh && chmod 700 ~/.ssh && echo \"$PUB_KEY_CONTENT\" >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && sort -u ~/.ssh/authorized_keys -o ~/.ssh/authorized_keys'" 2>/dev/null && echo -e "${GREEN}✅ Clé ajoutée à $VM_NAME${NC}" || echo -e "${RED}❌ Échec ajout clé${NC}"
        
        # Tester la connexion
        echo "🧪 Test de connexion depuis votre machine..."
        if ssh -i $SSH_KEY -o ProxyJump=ubuntu@$VM1_IP -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@$VM_IP "echo 'OK'" 2>/dev/null; then
            echo -e "${GREEN}✅ $VM_NAME accessible via ProxyJump !${NC}"
        else
            echo -e "${YELLOW}⚠️  $VM_NAME: connexion ProxyJump à vérifier${NC}"
        fi
    else
        echo -e "${RED}❌ $VM_NAME n'est pas accessible depuis VM1${NC}"
        echo -e "${YELLOW}   Vérifiez que la VM est démarrée et que l'IP est correcte${NC}"
    fi
    echo ""
}

# Configurer VM2, VM3, VM4
add_key_to_vm "VM2 (CVGFR)" "$VM2_IP"
add_key_to_vm "VM3 (PREFET)" "$VM3_IP"
add_key_to_vm "VM4 (Orderer)" "$VM4_IP"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST FINAL: Connectivité Ansible${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "🤖 Test Ansible ping sur toutes les VMs..."
echo ""

cd /home/absolue/my-blockchain
ansible all -i ansible/inventory/hosts.yml -m ping

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ CONFIGURATION SSH TERMINÉE !${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Prochaine étape: Déployer Fabric"
echo "  ./ansible/quick-deploy-ansible.sh --auto"
echo ""
