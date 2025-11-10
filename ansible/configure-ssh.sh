#!/bin/bash
# Script interactif pour configurer SSH vers les VMs AWS

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BASTION_IP="18.194.235.149"
VM2_IP="10.0.1.158"
VM3_IP="10.0.2.245"
VM4_IP="10.0.3.162"

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║        🔐 CONFIGURATION SSH POUR DÉPLOIEMENT MULTI-VM 🔐         ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Étape 1: Copier la clé sur VM1 (bastion)
echo -e "${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${CYAN}┃  ÉTAPE 1/4: Copier votre clé SSH sur VM1 (Bastion)              ┃${NC}"
echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""
echo "Nous allons copier votre clé publique SSH sur VM1 (18.194.235.149)"
echo "Cela permettra à Ansible de se connecter sans mot de passe."
echo ""
echo -e "${YELLOW}📝 Vous allez devoir entrer le mot de passe SSH de VM1 (ubuntu).${NC}"
echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."
echo ""

echo "🔑 Exécution de: ssh-copy-id ubuntu@$BASTION_IP"
echo ""

if ssh-copy-id -o StrictHostKeyChecking=no ubuntu@$BASTION_IP; then
    echo ""
    echo -e "${GREEN}✅ Clé SSH copiée avec succès sur VM1 !${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}❌ Échec de la copie de la clé SSH sur VM1${NC}"
    echo ""
    echo "Vérifiez:"
    echo "  • VM1 est accessible à l'IP $BASTION_IP"
    echo "  • Le port SSH (22) est ouvert"
    echo "  • Le mot de passe Ubuntu est correct"
    echo ""
    exit 1
fi

# Test de connexion à VM1
echo "🔍 Test de connexion à VM1 sans mot de passe..."
if ssh -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$BASTION_IP "echo 'Connection OK'" &> /dev/null; then
    echo -e "${GREEN}✅ Connexion SSH à VM1 fonctionne !${NC}"
    echo ""
else
    echo -e "${RED}❌ Impossible de se connecter à VM1${NC}"
    exit 1
fi

# Étape 2: Copier les clés depuis VM1 vers les autres VMs
echo ""
echo -e "${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${CYAN}┃  ÉTAPE 2/4: Copier les clés depuis VM1 vers VM2, VM3, VM4       ┃${NC}"
echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""
echo "Maintenant nous devons configurer l'accès depuis VM1 vers les autres VMs."
echo "Cela se fait EN DEUX SOUS-ÉTAPES:"
echo ""
echo "  A) Générer une clé SSH sur VM1 (si elle n'existe pas)"
echo "  B) Copier cette clé vers VM2, VM3, VM4"
echo ""
read -p "Appuyez sur ENTRÉE pour continuer..."
echo ""

echo "📡 Connexion à VM1 pour configurer les clés..."
echo ""

# Script à exécuter sur VM1
cat > /tmp/setup-ssh-from-bastion.sh << 'SCRIPT_EOF'
#!/bin/bash

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

VM2_IP="10.0.1.158"
VM3_IP="10.0.2.245"
VM4_IP="10.0.3.162"

echo ""
echo -e "${GREEN}🔐 Configuration SSH depuis VM1 (Bastion)${NC}"
echo ""

# Générer une clé SSH si elle n'existe pas
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "🔑 Génération d'une nouvelle clé SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N '' -q
    echo -e "${GREEN}✅ Clé SSH générée${NC}"
else
    echo -e "${GREEN}✅ Clé SSH déjà présente${NC}"
fi
echo ""

# Fonction pour copier la clé vers une VM
copy_key_to_vm() {
    local VM_NAME=$1
    local VM_IP=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔑 Copie de la clé vers $VM_NAME ($VM_IP)"
    echo ""
    echo -e "${YELLOW}Vous allez devoir entrer le mot de passe SSH de $VM_NAME${NC}"
    echo ""
    
    if ssh-copy-id -o StrictHostKeyChecking=no ubuntu@$VM_IP; then
        echo ""
        echo -e "${GREEN}✅ Clé copiée avec succès sur $VM_NAME !${NC}"
        
        # Test de connexion
        if ssh -o BatchMode=yes -o ConnectTimeout=5 ubuntu@$VM_IP "echo 'OK'" &> /dev/null; then
            echo -e "${GREEN}✅ Test de connexion réussi${NC}"
            return 0
        else
            echo -e "${RED}⚠️  Connexion configurée mais test échoué${NC}"
            return 1
        fi
    else
        echo ""
        echo -e "${RED}❌ Échec de la copie sur $VM_NAME${NC}"
        return 1
    fi
}

# Copier vers VM2, VM3, VM4
copy_key_to_vm "VM2 (CVGFR)" "$VM2_IP"
echo ""
copy_key_to_vm "VM3 (PREFET)" "$VM3_IP"
echo ""
copy_key_to_vm "VM4 (Orderer)" "$VM4_IP"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}✅ Configuration SSH terminée !${NC}"
echo ""
SCRIPT_EOF

# Copier le script sur VM1 et l'exécuter
scp -q /tmp/setup-ssh-from-bastion.sh ubuntu@$BASTION_IP:/tmp/
ssh ubuntu@$BASTION_IP "bash /tmp/setup-ssh-from-bastion.sh"

echo ""
echo -e "${GREEN}✅ Clés SSH configurées depuis VM1 vers toutes les VMs !${NC}"
echo ""

# Étape 3: Test de connectivité Ansible
echo ""
echo -e "${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${CYAN}┃  ÉTAPE 3/4: Test de connectivité Ansible                        ┃${NC}"
echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""
echo "Nous allons tester que Ansible peut se connecter à toutes les VMs"
echo "en utilisant le ProxyJump automatique."
echo ""
read -p "Appuyez sur ENTRÉE pour lancer le test..."
echo ""

cd "$(dirname "$0")/.."
echo "🤖 Exécution de: ansible all -i ansible/inventory/hosts.yml -m ping"
echo ""

if ansible all -i ansible/inventory/hosts.yml -m ping; then
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ TOUS LES TESTS DE CONNECTIVITÉ ONT RÉUSSI !${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    TEST_SUCCESS=true
else
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}❌ CERTAINES CONNEXIONS ONT ÉCHOUÉ${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    TEST_SUCCESS=false
fi

# Étape 4: Résumé
echo ""
echo -e "${CYAN}┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓${NC}"
echo -e "${CYAN}┃  ÉTAPE 4/4: Résumé de la configuration                          ┃${NC}"
echo -e "${CYAN}┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛${NC}"
echo ""

if [ "$TEST_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ Configuration SSH terminée avec succès !${NC}"
    echo ""
    echo "📊 État de la connectivité:"
    echo "  ✅ Votre machine → VM1 (Bastion) : OK"
    echo "  ✅ VM1 → VM2 (CVGFR) : OK"
    echo "  ✅ VM1 → VM3 (PREFET) : OK"
    echo "  ✅ VM1 → VM4 (Orderer) : OK"
    echo "  ✅ Ansible ProxyJump : OK"
    echo ""
    echo "🎉 Vous pouvez maintenant déployer Fabric sur les VMs !"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Prochaine commande:"
    echo "  ./ansible/quick-deploy-ansible.sh --auto"
    echo ""
else
    echo -e "${YELLOW}⚠️  Configuration SSH complétée mais avec des avertissements${NC}"
    echo ""
    echo "Vérifiez les connexions qui ont échoué et réessayez si nécessaire."
    echo ""
    echo "Pour relancer uniquement le test:"
    echo "  ansible all -i ansible/inventory/hosts.yml -m ping"
    echo ""
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
