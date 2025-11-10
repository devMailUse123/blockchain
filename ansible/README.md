# 🚀 Déploiement Ansible Multi-VM - Hyperledger Fabric

Déploiement automatisé du réseau Hyperledger Fabric 3.1.1 sur 4 VMs distinctes pour le projet de sécurisation foncière rurale en Côte d'Ivoire.

## 📋 Table des Matières

- [Architecture](#architecture)
- [Prérequis](#prérequis)
- [Configuration Rapide](#configuration-rapide)
- [Déploiement](#déploiement)
- [Playbooks Disponibles](#playbooks-disponibles)
- [Gestion du Réseau](#gestion-du-réseau)
- [Dépannage](#dépannage)

## 🏗️ Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   VM1 - AFOR    │     │  VM2 - CVGFR    │     │  VM3 - PREFET   │
├─────────────────┤     ├─────────────────┤     ├─────────────────┤
│ Peer:7051       │────▶│ Peer:8051       │────▶│ Peer:9051       │
│ CA:7054         │     │ CA:8054         │     │ CA:9054         │
│ CouchDB:5984    │     │ CouchDB:6984    │     │ CouchDB:7984    │
│ API:3000        │     │                 │     │                 │
└────────┬────────┘     └────────┬────────┘     └────────┬────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                          ┌──────▼──────┐
                          │ VM4-Orderer │
                          ├─────────────┤
                          │ Order:7050  │
                          │ CA:10054    │
                          └─────────────┘
```

## ✅ Prérequis

### Sur votre machine locale (control node)

- **Ansible** >= 2.14
- **Python** >= 3.8
- **SSH** accès aux 4 VMs
- **rsync** pour la synchronisation de fichiers

Installation Ansible :
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible python3-pip rsync

# Vérification
ansible --version
```

Installation des collections Ansible requises :
```bash
ansible-galaxy collection install community.docker
```

### Sur les VMs cibles (managed nodes)

- **Ubuntu 22.04 LTS** (recommandé) ou 20.04
- **2 vCPU minimum** (4 recommandés)
- **4 GB RAM minimum** (8 GB recommandés)
- **20 GB stockage minimum** (50 GB recommandés)
- **Python 3** installé
- **SSH** activé avec accès par clé
- **Connectivité réseau** entre toutes les VMs

## ⚙️ Configuration Rapide

### 1. Configurer l'inventaire avec vos IPs

Éditer `ansible/inventory/hosts.yml` et remplacer les IPs :

```yaml
vm1-afor:
  ansible_host: 10.0.1.10  # ← VOTRE IP VM1

vm2-cvgfr:
  ansible_host: 10.0.2.10  # ← VOTRE IP VM2

vm3-prefet:
  ansible_host: 10.0.3.10  # ← VOTRE IP VM3

vm4-orderer:
  ansible_host: 10.0.4.10  # ← VOTRE IP VM4
```

### 2. Configurer l'accès SSH

```bash
# Générer une clé SSH si vous n'en avez pas
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copier la clé sur chaque VM
ssh-copy-id ubuntu@10.0.1.10  # VM1
ssh-copy-id ubuntu@10.0.2.10  # VM2
ssh-copy-id ubuntu@10.0.3.10  # VM3
ssh-copy-id ubuntu@10.0.4.10  # VM4

# Tester la connexion
ansible all -i ansible/inventory/hosts.yml -m ping
```

Résultat attendu :
```
vm1-afor | SUCCESS => { "ping": "pong" }
vm2-cvgfr | SUCCESS => { "ping": "pong" }
vm3-prefet | SUCCESS => { "ping": "pong" }
vm4-orderer | SUCCESS => { "ping": "pong" }
```

### 3. Générer le matériel cryptographique (en local)

```bash
# Génération des certificats MSP
cd /home/absolue/my-blockchain
cryptogen generate --config=./network/crypto-config.yaml --output=./network/organizations

# Vérifier que les certificats sont créés
ls -la network/organizations/
```

### 4. Packager le chaincode (en local)

```bash
cd chaincode-java
mvn clean package -DskipTests
cd ..

# Le package devrait être dans chaincode-java/target/
ls -la chaincode-java/target/*.tar.gz
```

## 🚀 Déploiement

### Déploiement Complet (Toutes les phases)

```bash
cd /home/absolue/my-blockchain

# Exécution du playbook master (déploiement complet)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-all.yml
```

Durée estimée : **15-20 minutes**

### Déploiement Phase par Phase

Si vous préférez déployer étape par étape :

```bash
# Phase 1: Prérequis système
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/00-prerequisites.yml

# Phase 2: Installation Docker
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/01-install-docker.yml

# Phase 3: Configuration Pare-feu
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/02-configure-firewall.yml

# Phase 4: Copie des certificats
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/03-copy-crypto-material.yml

# Phase 5: Déploiement des conteneurs
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/04-deploy-containers.yml

# Phase 6: Création du channel
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/05-create-channel.yml

# Phase 7: Déploiement du chaincode
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/06-deploy-chaincode.yml

# Phase 8: Déploiement de l'API REST
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/07-deploy-api.yml
```

### Mode Dry-Run (Simulation)

Pour tester sans appliquer les changements :

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-all.yml --check
```

### Mode Verbose (Débogage)

Pour voir les détails d'exécution :

```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-all.yml -vvv
```

## 📚 Playbooks Disponibles

| Playbook | Description | Durée |
|----------|-------------|-------|
| `00-prerequisites.yml` | Installation paquets système, création répertoires | 3-5 min |
| `01-install-docker.yml` | Installation Docker + images Fabric | 5-8 min |
| `02-configure-firewall.yml` | Configuration UFW, ouverture ports | 1-2 min |
| `03-copy-crypto-material.yml` | Copie certificats MSP vers VMs | 2-3 min |
| `04-deploy-containers.yml` | Déploiement docker-compose, démarrage conteneurs | 3-5 min |
| `05-create-channel.yml` | Création channel, join peers | 2-3 min |
| `06-deploy-chaincode.yml` | Installation, approbation, commit chaincode | 3-5 min |
| `07-deploy-api.yml` | Déploiement API REST + Keycloak | 2-3 min |
| **`deploy-all.yml`** | **Playbook master (toutes les phases)** | **15-20 min** |

## 🔧 Gestion du Réseau

### Vérifier le statut

```bash
# Statut de tous les hôtes
ansible all -i ansible/inventory/hosts.yml -m shell -a "docker ps --format 'table {{.Names}}\t{{.Status}}'" -b

# Statut d'un hôte spécifique
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "docker ps" -b
```

### Redémarrer les conteneurs

```bash
# Redémarrer un peer spécifique
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "cd /opt/fabric && docker-compose restart" -b

# Redémarrer tous les conteneurs
ansible all -i ansible/inventory/hosts.yml -m shell -a "cd /opt/fabric && docker-compose restart" -b
```

### Voir les logs

```bash
# Logs du peer AFOR
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "docker logs peer0.afor.foncier.ci --tail 50" -b

# Logs de l'orderer
ansible vm4-orderer -i ansible/inventory/hosts.yml -m shell -a "docker logs orderer.foncier.ci --tail 50" -b

# Logs de l'API
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "tail -50 /opt/fabric/api/logs/api.log"
```

### Arrêter le réseau

```bash
# Arrêter tous les conteneurs
ansible all -i ansible/inventory/hosts.yml -m shell -a "cd /opt/fabric && docker-compose down" -b
```

### Nettoyer complètement

```bash
# Supprimer conteneurs, volumes, images
ansible all -i ansible/inventory/hosts.yml -m shell -a "cd /opt/fabric && docker-compose down -v && docker system prune -af" -b
```

## 🧪 Tests et Vérification

### Test de connectivité

```bash
# Ping entre VMs
ansible all -i ansible/inventory/hosts.yml -m ping

# Test ports ouverts
ansible vm1-afor -i ansible/inventory/hosts.yml -m wait_for -a "host=10.0.4.10 port=7050 timeout=10"
```

### Test du réseau Fabric

```bash
# Connexion SSH à VM1
ssh ubuntu@<VM1_IP>

# Test query chaincode
docker exec peer0.afor.foncier.ci peer chaincode query \
  -C contrat-agraire \
  -n contrat-agraire-cc \
  -c '{"function":"queryAllContrats","Args":[]}'
```

### Test de l'API

```bash
# Health check
curl http://<VM1_IP>:3000/api/health

# Obtenir un token Keycloak
TOKEN=$(curl -s -X POST "https://auth.digifor2.afor-ci.app/realms/digifor2/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=iam-user-auth" \
  -d "client_secret=V1pB8UbbtyUBua35NsrCVCbzYzPFnmr3" | jq -r '.access_token')

# Test GET contracts
curl -H "Authorization: Bearer $TOKEN" http://<VM1_IP>:3000/api/contracts
```

## 🐛 Dépannage

### Problème : Ansible ne peut pas se connecter aux VMs

**Solution :**
```bash
# Vérifier la clé SSH
ssh -i ~/.ssh/id_rsa ubuntu@<VM_IP>

# Vérifier le fichier inventory
ansible-inventory -i ansible/inventory/hosts.yml --list

# Test de connexion verbose
ansible all -i ansible/inventory/hosts.yml -m ping -vvv
```

### Problème : Docker ne démarre pas sur une VM

**Solution :**
```bash
# SSH vers la VM problématique
ssh ubuntu@<VM_IP>

# Vérifier le statut Docker
sudo systemctl status docker

# Redémarrer Docker
sudo systemctl restart docker

# Voir les logs Docker
sudo journalctl -u docker -n 50
```

### Problème : Peer ne peut pas se connecter à l'Orderer

**Solution :**
```bash
# Vérifier la connectivité réseau
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "ping -c 3 <ORDERER_IP>"

# Vérifier que le port 7050 est ouvert sur l'Orderer
ansible vm4-orderer -i ansible/inventory/hosts.yml -m shell -a "sudo ufw status" -b

# Tester le port depuis le peer
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "nc -zv <ORDERER_IP> 7050"
```

### Problème : Chaincode ne s'installe pas

**Solution :**
```bash
# Vérifier que le package existe
ls -la chaincode-java/target/*.tar.gz

# Voir les logs du peer
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "docker logs peer0.afor.foncier.ci --tail 100" -b

# Vérifier les chaincodes installés
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a \
  "docker exec peer0.afor.foncier.ci peer lifecycle chaincode queryinstalled" -b
```

### Problème : API ne répond pas

**Solution :**
```bash
# Vérifier le statut du service
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "sudo systemctl status fabric-api" -b

# Voir les logs de l'API
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "tail -100 /opt/fabric/api/logs/api.log"

# Redémarrer l'API
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell -a "sudo systemctl restart fabric-api" -b
```

## 📝 Variables de Configuration

### Modifier les variables globales

Éditer `ansible/group_vars/all.yml` :

```yaml
# Versions
fabric_version: "3.1.1"
ca_version: "1.5.13"

# Réseau
network_name: "contrat-agraire"
domain: "foncier.ci"

# Chaincode
chaincode_name: "contrat-agraire-cc"
chaincode_version: "4.0"

# Sécurité (CHANGER EN PRODUCTION!)
couchdb_user: "admin"
couchdb_password: "adminpw"
ca_admin_user: "admin"
ca_admin_password: "adminpw"
```

### Variables spécifiques aux groupes

- **Orderers** : `ansible/group_vars/orderers.yml`
- **Peers** : `ansible/group_vars/peers.yml`

## 🔐 Sécurité en Production

### ⚠️ IMPORTANT : Modifier les mots de passe par défaut

```bash
# Éditer les variables
nano ansible/group_vars/all.yml

# Changer:
couchdb_password: "VOTRE_MOT_DE_PASSE_FORT"
ca_admin_password: "VOTRE_MOT_DE_PASSE_FORT"
```

### Restreindre l'accès réseau

Par défaut, les playbooks configurent UFW pour ouvrir tous les ports nécessaires. En production :

1. Limiter l'accès SSH à des IPs spécifiques
2. Utiliser un VPN pour l'accès inter-VM
3. Activer TLS mutuel sur tous les services

## 📊 Monitoring

Les métriques Prometheus sont exposées sur :

- **Orderer** : `http://<ORDERER_IP>:9443/metrics`
- **Peer AFOR** : `http://<AFOR_IP>:9447/metrics`
- **Peer CVGFR** : `http://<CVGFR_IP>:9448/metrics`
- **Peer PREFET** : `http://<PREFET_IP>:9449/metrics`

## 📖 Ressources

- [Documentation Hyperledger Fabric](https://hyperledger-fabric.readthedocs.io/)
- [Ansible Documentation](https://docs.ansible.com/)
- [Guide de Déploiement Détaillé](../deployment/README.md)

## 🆘 Support

Pour toute question ou problème :

1. Consulter la section [Dépannage](#dépannage)
2. Vérifier les logs des conteneurs
3. Consulter `../GUIDE-DEPLOIEMENT-PRODUCTION.md`

---

**Dernière mise à jour** : Janvier 2025  
**Version Fabric** : 3.1.1  
**Auteur** : Projet DigiFor2 - AFOR Côte d'Ivoire
