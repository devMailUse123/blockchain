# 🎯 Guide de Démarrage Rapide - Déploiement Ansible Multi-VM

## ✅ Ce qui a été créé

Votre environnement Ansible est maintenant complètement configuré avec :

### 📁 Structure Ansible
```
ansible/
├── inventory/
│   └── hosts.yml                    # Inventaire des 4 VMs (À CONFIGURER)
├── group_vars/
│   ├── all.yml                      # Variables globales
│   ├── orderers.yml                 # Variables pour orderers
│   └── peers.yml                    # Variables pour peers
├── playbooks/
│   ├── 00-prerequisites.yml         # Installation prérequis système
│   ├── 01-install-docker.yml        # Installation Docker
│   ├── 02-configure-firewall.yml    # Configuration pare-feu UFW
│   ├── 03-copy-crypto-material.yml  # Copie certificats MSP
│   ├── 04-deploy-containers.yml     # Déploiement conteneurs Docker
│   ├── 05-create-channel.yml        # Création channel blockchain
│   ├── 06-deploy-chaincode.yml      # Installation chaincode
│   ├── 07-deploy-api.yml            # Déploiement API REST
│   └── deploy-all.yml               # PLAYBOOK MASTER (tout automatique)
├── README.md                        # Documentation complète
└── quick-deploy-ansible.sh          # Script de déploiement automatique
```

### 🎯 Playbooks créés

| Playbook | Description | Durée |
|----------|-------------|-------|
| `deploy-all.yml` | 🚀 **PLAYBOOK MASTER** - Déploie tout automatiquement | 15-20 min |
| `00-prerequisites.yml` | Install paquets, création répertoires | 3-5 min |
| `01-install-docker.yml` | Install Docker + images Fabric | 5-8 min |
| `02-configure-firewall.yml` | Config UFW, ouverture ports | 1-2 min |
| `03-copy-crypto-material.yml` | Copie certificats vers VMs | 2-3 min |
| `04-deploy-containers.yml` | Démarrage conteneurs Docker | 3-5 min |
| `05-create-channel.yml` | Création channel + join peers | 2-3 min |
| `06-deploy-chaincode.yml` | Install + approve + commit chaincode | 3-5 min |
| `07-deploy-api.yml` | API REST + Keycloak | 2-3 min |

## 🚀 Démarrage en 5 Étapes

### Étape 1 : Installer Ansible (si pas encore fait)

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y ansible python3-pip rsync

# Installer la collection Docker
ansible-galaxy collection install community.docker

# Vérifier
ansible --version
```

### Étape 2 : Configurer vos IPs de VMs

Éditer le fichier d'inventaire :

```bash
nano /home/absolue/my-blockchain/ansible/inventory/hosts.yml
```

**Remplacer les IPs par défaut par VOS IPs réelles :**

```yaml
vm1-afor:
  ansible_host: 10.0.1.10  # ← CHANGER PAR VOTRE IP VM1

vm2-cvgfr:
  ansible_host: 10.0.2.10  # ← CHANGER PAR VOTRE IP VM2

vm3-prefet:
  ansible_host: 10.0.3.10  # ← CHANGER PAR VOTRE IP VM3

vm4-orderer:
  ansible_host: 10.0.4.10  # ← CHANGER PAR VOTRE IP VM4
```

### Étape 3 : Configurer l'accès SSH

```bash
# Copier votre clé SSH sur chaque VM
ssh-copy-id ubuntu@<VM1_IP>
ssh-copy-id ubuntu@<VM2_IP>
ssh-copy-id ubuntu@<VM3_IP>
ssh-copy-id ubuntu@<VM4_IP>

# Tester la connexion
ansible all -i ansible/inventory/hosts.yml -m ping
```

**Résultat attendu :**
```
vm1-afor | SUCCESS => { "ping": "pong" }
vm2-cvgfr | SUCCESS => { "ping": "pong" }
vm3-prefet | SUCCESS => { "ping": "pong" }
vm4-orderer | SUCCESS => { "ping": "pong" }
```

### Étape 4 : Générer les certificats (en local)

```bash
cd /home/absolue/my-blockchain

# Générer le matériel cryptographique
cryptogen generate \
  --config=./network/crypto-config.yaml \
  --output=./network/organizations

# Vérifier
ls -la network/organizations/
```

### Étape 5 : Lancer le déploiement automatique

#### Option A : Script tout automatique (RECOMMANDÉ)

```bash
cd /home/absolue/my-blockchain

# Lancement automatique complet
./ansible/quick-deploy-ansible.sh --auto
```

#### Option B : Playbook Ansible master

```bash
cd /home/absolue/my-blockchain

# Déploiement complet via Ansible
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/deploy-all.yml
```

#### Option C : Menu interactif

```bash
cd /home/absolue/my-blockchain

# Menu interactif avec options
./ansible/quick-deploy-ansible.sh
```

## ⏱️ Durée du Déploiement

- **Déploiement complet** : 15-20 minutes
- **Vérifications préalables** : 2-3 minutes
- **Installation Docker** : 5-8 minutes (téléchargement images)
- **Configuration réseau** : 5-7 minutes
- **Déploiement chaincode** : 3-5 minutes

## ✅ Vérification Post-Déploiement

### 1. Vérifier les conteneurs Docker

```bash
# Statut de tous les conteneurs
ansible all -i ansible/inventory/hosts.yml -m shell \
  -a "docker ps --format 'table {{.Names}}\t{{.Status}}'" -b
```

### 2. Tester l'API REST

```bash
# Remplacer <VM1_IP> par votre IP réelle
curl http://<VM1_IP>:3000/api/health

# Résultat attendu:
# {"status":"UP","blockchain":"Connected"}
```

### 3. Obtenir un token Keycloak et tester les contrats

```bash
# Obtenir le token
TOKEN=$(curl -s -X POST "https://auth.digifor2.afor-ci.app/realms/digifor2/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=iam-user-auth" \
  -d "client_secret=V1pB8UbbtyUBua35NsrCVCbzYzPFnmr3" | jq -r '.access_token')

# Lister les contrats
curl -H "Authorization: Bearer $TOKEN" http://<VM1_IP>:3000/api/contracts
```

### 4. Accéder à la documentation Swagger

Ouvrir dans un navigateur :
```
http://<VM1_IP>:3000/api-docs
```

## 🎯 Ce que fait le déploiement automatique

### Phase 1 : Prérequis (3-5 min)
- ✅ Mise à jour APT sur toutes les VMs
- ✅ Installation paquets système (curl, jq, git, etc.)
- ✅ Configuration limites système pour Fabric
- ✅ Création des répertoires `/opt/fabric`
- ✅ Test de connectivité inter-VMs

### Phase 2 : Docker (5-8 min)
- ✅ Installation Docker CE + Docker Compose
- ✅ Configuration daemon Docker (logs, storage)
- ✅ Pull des images Hyperledger Fabric 3.1.1
- ✅ Pull des images CA 1.5.13 et CouchDB 3.3.3
- ✅ Création réseau Docker `fabric-network`

### Phase 3 : Pare-feu (1-2 min)
- ✅ Installation et configuration UFW
- ✅ Ouverture ports SSH (22)
- ✅ Ouverture ports Orderer (7050, 7053, 9443, 10054)
- ✅ Ouverture ports Peers (7051, 8051, 9051 + CAs + CouchDB)
- ✅ Ouverture port API (3000)

### Phase 4 : Certificats (2-3 min)
- ✅ Copie certificats MSP vers VM Orderer
- ✅ Copie certificats MSP vers chaque VM Peer
- ✅ Copie certificats TLS pour communication inter-noeuds
- ✅ Configuration des permissions (0755/0644)

### Phase 5 : Conteneurs (3-5 min)
- ✅ Copie des fichiers `docker-compose.yml`
- ✅ Remplacement des placeholders IP
- ✅ Démarrage Orderer (VM4)
- ✅ Démarrage Peers AFOR, CVGFR, PREFET (VM1, VM2, VM3)
- ✅ Démarrage CouchDB pour chaque peer
- ✅ Démarrage CA pour chaque organisation

### Phase 6 : Channel (2-3 min)
- ✅ Génération du genesis block
- ✅ Création du channel `contrat-agraire`
- ✅ Join de l'Orderer au channel
- ✅ Fetch du genesis block par chaque peer
- ✅ Join des 3 peers au channel

### Phase 7 : Chaincode (3-5 min)
- ✅ Copie du package chaincode Java vers peers
- ✅ Installation sur peer AFOR (VM1)
- ✅ Installation sur peer CVGFR (VM2)
- ✅ Approbation par AFOR
- ✅ Approbation par CVGFR
- ✅ Commit de la définition sur le channel
- ✅ Test d'invocation (création contrat test)

### Phase 8 : API REST (2-3 min)
- ✅ Installation Node.js + npm sur VM1
- ✅ Copie des fichiers API
- ✅ Installation dépendances npm
- ✅ Configuration fichier `.env`
- ✅ Création service systemd `fabric-api`
- ✅ Démarrage de l'API sur port 3000
- ✅ Test health check
- ✅ Test authentification Keycloak

## 📊 Architecture Déployée

```
        ┌──────────────────────────────────────────────┐
        │          Internet / Keycloak OAuth2          │
        │   https://auth.digifor2.afor-ci.app          │
        └────────────────┬─────────────────────────────┘
                         │
        ┌────────────────▼───────────────┐
        │    VM1 - AFOR (10.0.1.10)      │
        │  ┌──────────────────────────┐  │
        │  │ API REST :3000           │  │ ← Point d'entrée
        │  │ + Keycloak JWT           │  │
        │  └──────────┬───────────────┘  │
        │  ┌──────────▼───────────────┐  │
        │  │ Peer AFOR :7051          │  │
        │  │ CA :7054                 │  │
        │  │ CouchDB :5984            │  │
        │  └──────────┬───────────────┘  │
        └─────────────┼──────────────────┘
                      │
         ┌────────────┼────────────┐
         │            │            │
    ┌────▼────┐  ┌───▼─────┐  ┌──▼──────┐
    │ VM2     │  │ VM3     │  │ VM4     │
    │ CVGFR   │  │ PREFET  │  │ Orderer │
    │ :8051   │  │ :9051   │  │ :7050   │
    └─────────┘  └─────────┘  └─────────┘
```

## 🔧 Commandes Utiles Après Déploiement

### Gestion des conteneurs

```bash
# Voir tous les conteneurs
ansible all -i ansible/inventory/hosts.yml -m shell -a "docker ps" -b

# Redémarrer un service
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "cd /opt/fabric && docker-compose restart peer0.afor.foncier.ci" -b

# Arrêter tout le réseau
ansible all -i ansible/inventory/hosts.yml -m shell \
  -a "cd /opt/fabric && docker-compose down" -b

# Redémarrer tout le réseau
ansible all -i ansible/inventory/hosts.yml -m shell \
  -a "cd /opt/fabric && docker-compose up -d" -b
```

### Consulter les logs

```bash
# Logs Peer AFOR
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "docker logs peer0.afor.foncier.ci --tail 100" -b

# Logs Orderer
ansible vm4-orderer -i ansible/inventory/hosts.yml -m shell \
  -a "docker logs orderer.foncier.ci --tail 100" -b

# Logs API REST
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "tail -100 /opt/fabric/api/logs/api.log"
```

### Tests chaincode

```bash
# Se connecter à VM1
ssh ubuntu@<VM1_IP>

# Query tous les contrats
docker exec peer0.afor.foncier.ci peer chaincode query \
  -C contrat-agraire \
  -n contrat-agraire-cc \
  -c '{"function":"queryAllContrats","Args":[]}'

# Créer un nouveau contrat
docker exec peer0.afor.foncier.ci peer chaincode invoke \
  -o orderer.foncier.ci:7050 \
  -C contrat-agraire \
  -n contrat-agraire-cc \
  --tls \
  --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem \
  --peerAddresses peer0.afor.foncier.ci:7051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
  --peerAddresses peer0.cvgfr.foncier.ci:8051 \
  --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
  -c '{"function":"createContrat","Args":["TEST-001","KOUAME Jean","N'\''GUESSAN Marie","Bouake","2.5","Titre Foncier"]}'
```

## 🐛 Dépannage Rapide

### Problème : Ansible ne peut pas se connecter

```bash
# Vérifier SSH manuellement
ssh ubuntu@<VM_IP>

# Copier à nouveau la clé
ssh-copy-id ubuntu@<VM_IP>

# Test verbose
ansible all -i ansible/inventory/hosts.yml -m ping -vvv
```

### Problème : Conteneur ne démarre pas

```bash
# Se connecter à la VM
ssh ubuntu@<VM_IP>

# Voir les logs
docker logs <container_name>

# Redémarrer
cd /opt/fabric
docker-compose restart <service_name>
```

### Problème : API ne répond pas

```bash
# Vérifier le service
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "sudo systemctl status fabric-api" -b

# Redémarrer l'API
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "sudo systemctl restart fabric-api" -b

# Voir les logs
ansible vm1-afor -i ansible/inventory/hosts.yml -m shell \
  -a "tail -100 /opt/fabric/api/logs/api.log"
```

## 📚 Documentation

- **README Ansible** : `/home/absolue/my-blockchain/ansible/README.md`
- **README Deployment** : `/home/absolue/my-blockchain/deployment/README.md`
- **Documentation API** : `/home/absolue/my-blockchain/docs/API.md`

## 🎉 Résultat Final Attendu

Après un déploiement réussi, vous aurez :

✅ **4 VMs configurées** avec Docker, pare-feu, certificats  
✅ **1 Orderer** actif sur VM4  
✅ **3 Peers** actifs (AFOR, CVGFR, PREFET) sur VM1, VM2, VM3  
✅ **3 CouchDB** (une par peer)  
✅ **4 CA** (une par organisation)  
✅ **1 Channel** `contrat-agraire` créé et opérationnel  
✅ **1 Chaincode** `contrat-agraire-cc v4.0` déployé  
✅ **1 API REST** sur VM1 port 3000 avec Keycloak  
✅ **Documentation Swagger** accessible  

---

**Prêt à déployer ?**

```bash
cd /home/absolue/my-blockchain
./ansible/quick-deploy-ansible.sh --auto
```

Bonne chance ! 🚀
