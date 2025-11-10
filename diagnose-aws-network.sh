#!/bin/bash
# Script pour diagnostiquer et vérifier la configuration AWS

SSH_KEY=~/.ssh/id_ed25519_blockchain_vm
VM1_IP="18.194.235.149"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        🔍 DIAGNOSTIC RÉSEAU AWS - ÉTAPE PAR ÉTAPE 🔍            ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}Informations à collecter dans AWS Console :${NC}"
echo ""

read -p "1️⃣  Combien de VMs sont en état 'running' dans EC2 ? (1/2/3/4) : " VM_COUNT
echo ""

if [ "$VM_COUNT" != "4" ]; then
    echo -e "${RED}❌ PROBLÈME : Toutes les 4 VMs doivent être démarrées !${NC}"
    echo ""
    echo "Actions :"
    echo "  1. AWS Console → EC2 → Instances"
    echo "  2. Sélectionnez les VMs arrêtées"
    echo "  3. Actions → Instance State → Start"
    echo "  4. Attendez qu'elles passent à 'running'"
    echo "  5. Relancez ce script"
    echo ""
    exit 1
fi

echo -e "${GREEN}✅ Les 4 VMs sont démarrées${NC}"
echo ""

read -p "2️⃣  VM1 Security Group : Y a-t-il une règle 'All traffic' depuis 10.0.0.0/16 ? (oui/non) : " SG_VM1
read -p "3️⃣  VM2 Security Group : Y a-t-il une règle 'All traffic' depuis 10.0.0.0/16 ? (oui/non) : " SG_VM2
read -p "4️⃣  VM3 Security Group : Y a-t-il une règle 'All traffic' depuis 10.0.0.0/16 ? (oui/non) : " SG_VM3
read -p "5️⃣  VM4 Security Group : Y a-t-il une règle 'All traffic' depuis 10.0.0.0/16 ? (oui/non) : " SG_VM4
echo ""

SG_OK=true
[ "$SG_VM1" != "oui" ] && SG_OK=false && echo -e "${RED}❌ VM1 Security Group mal configuré${NC}"
[ "$SG_VM2" != "oui" ] && SG_OK=false && echo -e "${RED}❌ VM2 Security Group mal configuré${NC}"
[ "$SG_VM3" != "oui" ] && SG_OK=false && echo -e "${RED}❌ VM3 Security Group mal configuré${NC}"
[ "$SG_VM4" != "oui" ] && SG_OK=false && echo -e "${RED}❌ VM4 Security Group mal configuré${NC}"

if [ "$SG_OK" = false ]; then
    echo ""
    echo "📖 Pour ajouter la règle :"
    echo "  1. AWS Console → EC2 → Security Groups"
    echo "  2. Cliquez sur le Security Group"
    echo "  3. Onglet 'Inbound rules' → Edit inbound rules"
    echo "  4. Add rule :"
    echo "     - Type: All traffic"
    echo "     - Source: Custom = 10.0.0.0/16"
    echo "  5. Save rules"
    echo ""
    read -p "Appuyez sur Entrée après avoir corrigé..."
fi

echo -e "${GREEN}✅ Security Groups configurés${NC}"
echo ""

echo -e "${YELLOW}6️⃣  Test réseau depuis VM1...${NC}"
echo ""

echo "🔍 VM1 peut-elle résoudre les IPs privées ?"
ssh -i $SSH_KEY ubuntu@$VM1_IP "ip route show" 2>/dev/null
echo ""

echo "🔍 Interfaces réseau de VM1 :"
ssh -i $SSH_KEY ubuntu@$VM1_IP "ip addr show | grep -E 'inet |^[0-9]'" 2>/dev/null
echo ""

echo "🔍 Table ARP de VM1 (voisins réseau) :"
ssh -i $SSH_KEY ubuntu@$VM1_IP "ip neigh show" 2>/dev/null
echo ""

echo "🔍 Tentative de ping vers VM2 (10.0.1.158)..."
ssh -i $SSH_KEY ubuntu@$VM1_IP "ping -c 3 -W 2 10.0.1.158" 2>&1
PING_RESULT=$?
echo ""

if [ $PING_RESULT -eq 0 ]; then
    echo -e "${GREEN}✅ VM1 peut ping VM2 !${NC}"
    echo ""
    echo "Le problème vient peut-être de la clé SSH sur VM2/3/4"
    echo "Relançons le script de configuration SSH :"
    echo ""
    echo "  ./setup-ssh-keys-all-vms.sh"
    echo ""
else
    echo -e "${RED}❌ VM1 ne peut toujours pas ping VM2${NC}"
    echo ""
    echo "Les VMs sont probablement dans des SUBNETS différents NON CONNECTÉS"
    echo ""
    echo "📋 Vérifiez dans AWS Console :"
    echo ""
    echo "A) EC2 → Instances → Vérifiez la colonne 'Subnet'"
    echo "   • Toutes les VMs sont-elles dans le MÊME subnet ?"
    echo "   • OU les subnets sont-ils dans le MÊME VPC ?"
    echo ""
    echo "B) VPC → Route Tables"
    echo "   • Chaque subnet doit avoir une route : 10.0.0.0/16 → local"
    echo ""
    echo "C) VPC → Subnets → Sélectionnez chaque subnet"
    echo "   • Vérifiez 'VPC' : tous doivent être dans le MÊME VPC"
    echo ""
    read -p "Quelle est la configuration ? (même-subnet/même-vpc/différents-vpc) : " SUBNET_CONFIG
    echo ""
    
    if [ "$SUBNET_CONFIG" = "différents-vpc" ]; then
        echo -e "${RED}❌ ERREUR CRITIQUE : Les VMs doivent être dans le MÊME VPC !${NC}"
        echo ""
        echo "Solutions :"
        echo "  1. Recréer les VMs dans le même VPC"
        echo "  2. Ou utiliser VPC Peering (complexe)"
        echo ""
    elif [ "$SUBNET_CONFIG" = "même-vpc" ]; then
        echo -e "${YELLOW}⚠️  VMs dans différents subnets du même VPC${NC}"
        echo ""
        echo "Vérifiez les Route Tables :"
        echo "  VPC → Route Tables → Sélectionnez chaque Route Table"
        echo "  Doit contenir : 10.0.0.0/16 → local (ou Target=local)"
        echo ""
    fi
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Résumé : Si VM1 ne peut pas ping VM2, c'est un problème AWS réseau,"
echo "pas un problème de notre configuration Fabric/Ansible."
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
