#!/bin/bash
# Script pour tester la connectivité VPC après configuration Security Groups

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SSH_KEY=~/.ssh/id_ed25519_blockchain_vm
VM1_IP="18.194.235.149"
VM2_IP="10.0.1.158"
VM3_IP="10.0.2.245"
VM4_IP="10.0.3.162"

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║     🔍 TEST DE CONNECTIVITÉ VPC - HYPERLEDGER FABRIC 🔍         ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 1 : Connectivité ICMP (ping)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

test_ping() {
    local VM_NAME=$1
    local VM_IP=$2
    
    echo -n "🔍 Ping $VM_NAME ($VM_IP)... "
    if ssh -i $SSH_KEY -o ConnectTimeout=5 ubuntu@$VM1_IP "ping -c 2 -W 2 $VM_IP > /dev/null 2>&1"; then
        echo -e "${GREEN}✅ OK${NC}"
        return 0
    else
        echo -e "${RED}❌ ÉCHEC${NC}"
        return 1
    fi
}

PING_SUCCESS=0
test_ping "VM2 (CVGFR)" "$VM2_IP" && ((PING_SUCCESS++)) || true
test_ping "VM3 (PREFET)" "$VM3_IP" && ((PING_SUCCESS++)) || true
test_ping "VM4 (Orderer)" "$VM4_IP" && ((PING_SUCCESS++)) || true

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 2 : Connectivité SSH (port 22)${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

test_ssh() {
    local VM_NAME=$1
    local VM_IP=$2
    
    echo -n "🔍 SSH $VM_NAME ($VM_IP)... "
    if ssh -i $SSH_KEY -o ConnectTimeout=5 ubuntu@$VM1_IP "nc -zv -w 3 $VM_IP 22 > /dev/null 2>&1"; then
        echo -e "${GREEN}✅ Port 22 ouvert${NC}"
        return 0
    else
        echo -e "${RED}❌ Port 22 fermé${NC}"
        return 1
    fi
}

SSH_SUCCESS=0
test_ssh "VM2 (CVGFR)" "$VM2_IP" && ((SSH_SUCCESS++)) || true
test_ssh "VM3 (PREFET)" "$VM3_IP" && ((SSH_SUCCESS++)) || true
test_ssh "VM4 (Orderer)" "$VM4_IP" && ((SSH_SUCCESS++)) || true

echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}TEST 3 : Connectivité Ansible${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "🤖 Test Ansible ping sur toutes les VMs..."
echo ""

cd /home/absolue/my-blockchain
ANSIBLE_OUTPUT=$(ansible all -i ansible/inventory/hosts.yml -m ping 2>&1)
ANSIBLE_SUCCESS=$(echo "$ANSIBLE_OUTPUT" | grep -c "SUCCESS" || true)

echo "$ANSIBLE_OUTPUT"
echo ""

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}RÉSUMÉ${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

echo "📊 Résultats des tests :"
echo "  • Ping : $PING_SUCCESS/3 VMs accessibles"
echo "  • SSH : $SSH_SUCCESS/3 VMs accessibles"
echo "  • Ansible : $ANSIBLE_SUCCESS/4 VMs accessibles"
echo ""

if [ $ANSIBLE_SUCCESS -eq 4 ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ SUCCÈS ! Toutes les VMs sont accessibles${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "🚀 Vous pouvez maintenant déployer Hyperledger Fabric :"
    echo ""
    echo "   ./ansible/quick-deploy-ansible.sh --auto"
    echo ""
    exit 0
else
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ ÉCHEC : Certaines VMs ne sont pas accessibles${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "⚠️  Les Security Groups AWS doivent être configurés."
    echo ""
    echo "📖 Suivez le guide : AWS-SECURITY-GROUPS-FIX.md"
    echo ""
    exit 1
fi
