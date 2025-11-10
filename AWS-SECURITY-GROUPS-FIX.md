# 🔒 Configuration Security Groups AWS pour Hyperledger Fabric

## 🔴 Problème Détecté

Les VMs ne peuvent pas communiquer entre elles dans le VPC :
- ❌ VM1 (10.0.1.10) → VM2 (10.0.1.158) : Connection timed out
- ❌ VM1 (10.0.1.10) → VM3 (10.0.2.245) : Connection timed out
- ❌ VM1 (10.0.1.10) → VM4 (10.0.3.162) : Connection timed out

## 🎯 Solution : Configurer les Security Groups

### Étape 1 : Accéder aux Security Groups AWS

1. Connectez-vous à la **Console AWS**
2. Allez dans **EC2** → **Security Groups**
3. Identifiez les Security Groups de vos 4 VMs

### Étape 2 : Règles Inbound à Ajouter

Pour **CHAQUE Security Group**, ajoutez ces règles **Inbound** :

#### A. Communication SSH (pour Ansible via bastion)

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | `10.0.0.0/16` | SSH depuis toutes les VMs du VPC |

#### B. Communication Hyperledger Fabric

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| Custom TCP | TCP | 7050-7053 | `10.0.0.0/16` | Orderer (7050=orderer, 7053=admin) |
| Custom TCP | TCP | 7051-7052 | `10.0.0.0/16` | Peer AFOR (7051=peer, 7052=chaincode) |
| Custom TCP | TCP | 8051-8052 | `10.0.0.0/16` | Peer CVGFR |
| Custom TCP | TCP | 9051-9052 | `10.0.0.0/16` | Peer PREFET |
| Custom TCP | TCP | 5984 | `10.0.0.0/16` | CouchDB (toutes les VMs) |
| Custom TCP | TCP | 7054 | `10.0.0.0/16` | CA AFOR |
| Custom TCP | TCP | 8054 | `10.0.0.0/16` | CA CVGFR |
| Custom TCP | TCP | 9054 | `10.0.0.0/16` | CA PREFET |
| Custom TCP | TCP | 10054 | `10.0.0.0/16` | CA Orderer |

#### C. ICMP (pour ping - diagnostic)

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| All ICMP - IPv4 | ICMP | All | `10.0.0.0/16` | Ping entre VMs |

### Étape 3 : Règle Spéciale pour VM1 (AFOR)

VM1 doit aussi accepter les connexions **depuis Internet** pour :

| Type | Protocol | Port Range | Source | Description |
|------|----------|------------|--------|-------------|
| SSH | TCP | 22 | `0.0.0.0/0` | SSH depuis votre machine locale |
| Custom TCP | TCP | 3000 | `0.0.0.0/0` | API REST (backend Spring Boot) |

### Étape 4 : Vérifier les Route Tables

1. Allez dans **VPC** → **Route Tables**
2. Pour chaque subnet (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24) :
   - Vérifiez qu'il y a une route `10.0.0.0/16` → `local`
   - Cela permet la communication intra-VPC

### Étape 5 : Network ACLs

1. Allez dans **VPC** → **Network ACLs**
2. Vérifiez que les Network ACLs autorisent :
   - Inbound : Tout le trafic depuis `10.0.0.0/16`
   - Outbound : Tout le trafic vers `10.0.0.0/16`

## ✅ Vérification Après Configuration

Après avoir appliqué ces règles, testez depuis votre machine locale :

```bash
# Test 1 : VM1 peut-elle ping les autres ?
ssh -i ~/.ssh/id_ed25519_blockchain_vm ubuntu@18.194.235.149 \
  "ping -c 2 10.0.1.158 && ping -c 2 10.0.2.245 && ping -c 2 10.0.3.162"

# Test 2 : VM1 peut-elle SSH vers les autres ?
ssh -i ~/.ssh/id_ed25519_blockchain_vm ubuntu@18.194.235.149 \
  "ssh -o StrictHostKeyChecking=no ubuntu@10.0.1.158 'hostname'"

# Test 3 : Ansible ping fonctionne-t-il ?
ansible all -i ansible/inventory/hosts.yml -m ping
```

Si tous les tests passent ✅, vous pouvez continuer le déploiement Fabric !

## 🚀 Configuration Rapide via AWS CLI (Optionnel)

Si vous préférez la ligne de commande :

```bash
# Récupérer l'ID du VPC
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=fabric-vpc" --query 'Vpcs[0].VpcId' --output text)

# Récupérer les Security Group IDs
SG_AFOR=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=afor-sg" --query 'SecurityGroups[0].GroupId' --output text)
SG_CVGFR=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=cvgfr-sg" --query 'SecurityGroups[0].GroupId' --output text)
SG_PREFET=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=prefet-sg" --query 'SecurityGroups[0].GroupId' --output text)
SG_ORDERER=$(aws ec2 describe-security-groups --filters "Name=tag:Name,Values=orderer-sg" --query 'SecurityGroups[0].GroupId' --output text)

# Autoriser tout le trafic depuis le VPC (10.0.0.0/16) pour chaque SG
for SG in $SG_AFOR $SG_CVGFR $SG_PREFET $SG_ORDERER; do
  aws ec2 authorize-security-group-ingress \
    --group-id $SG \
    --protocol -1 \
    --cidr 10.0.0.0/16
done
```

## 📖 Pourquoi ces règles ?

- **10.0.0.0/16** : Plage complète de votre VPC, permet la communication entre TOUS les subnets
- **Port 22** : SSH nécessaire pour Ansible et debugging
- **Ports 7050-9054** : Ports Hyperledger Fabric (peers, orderer, CA, CouchDB)
- **ICMP** : Permet `ping` pour diagnostiquer les problèmes réseau
- **API 3000** : Accessible depuis Internet pour que votre backend Spring Boot puisse appeler la blockchain

Une fois ces règles appliquées, le déploiement multi-VM pourra commencer ! 🎉
