# 🚀 Guide de Démarrage Rapide - Déploiement Serveur

## 📋 Vue d'Ensemble

Ce guide vous permet de déployer le réseau blockchain en **moins de 10 minutes** sur un serveur distant.

---

## 🎯 Méthode 1 : Déploiement Automatique avec GitHub Actions (Recommandé)

### Étape 1 : Préparer le Repository Git

```bash
# Sur votre machine locale
cd my-blockchain

# Initialiser Git et créer le commit initial
./scripts/init-git.sh

# Le script va :
# ✅ Initialiser le repository Git
# ✅ Vérifier qu'aucun fichier sensible n'est ajouté
# ✅ Créer le commit initial
# ✅ Configurer le remote GitHub (optionnel)
```

### Étape 2 : Configurer les Secrets GitHub

1. Allez sur votre repository GitHub
2. `Settings` > `Secrets and variables` > `Actions`
3. Cliquez sur `New repository secret`
4. Ajoutez les 4 secrets suivants :

| Secret Name | Valeur | Description |
|------------|--------|-------------|
| `SERVER_HOST` | `192.168.1.100` | IP ou domaine de votre serveur |
| `SERVER_USER` | `ubuntu` | Utilisateur SSH |
| `SERVER_SSH_KEY` | `-----BEGIN RSA...` | Clé privée SSH complète |
| `SERVER_PORT` | `22` | Port SSH (optionnel) |

**Générer une clé SSH si vous n'en avez pas :**

```bash
# Sur votre machine locale
ssh-keygen -t rsa -b 4096 -C "github-deploy@votredomaine.com" -f ~/.ssh/github_deploy

# Copier la clé publique sur le serveur
ssh-copy-id -i ~/.ssh/github_deploy.pub ubuntu@192.168.1.100

# Afficher la clé privée à copier dans GitHub
cat ~/.ssh/github_deploy
# Copiez TOUT le contenu (de BEGIN à END) dans le secret SERVER_SSH_KEY
```

### Étape 3 : Préparer le Serveur

```bash
# Se connecter au serveur
ssh ubuntu@192.168.1.100

# Installer les prérequis
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installer Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Se déconnecter et reconnecter pour appliquer les permissions
exit
ssh ubuntu@192.168.1.100

# Installer les binaires Fabric
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary

# Ajouter au PATH
echo 'export PATH=$PATH:$HOME/fabric-samples/bin' >> ~/.bashrc
source ~/.bashrc

# Vérifier
docker --version
docker-compose --version
peer version
```

### Étape 4 : Déployer

```bash
# Sur votre machine locale, pousser sur GitHub
git push origin main

# Le workflow GitHub Actions se déclenche automatiquement et :
# 1. ✅ Valide la configuration
# 2. ✅ Build le chaincode Java
# 3. ✅ Build l'API Node.js
# 4. ✅ Synchronise les fichiers sur le serveur
# 5. ✅ Configure l'environnement
# 6. ✅ Déploie le réseau complet
# 7. ✅ Vérifie que tout fonctionne
```

**Suivre le déploiement :**
- Sur GitHub : `Actions` > `Deploy to Server`
- Statut en temps réel avec logs détaillés

### Étape 5 : Vérifier

```bash
# Sur le serveur
cd ~/blockchain-deployment

# Vérifier les conteneurs
docker ps

# Devrait afficher 12 conteneurs :
# - 1 orderer
# - 3 peers
# - 3 couchdb
# - 4 fabric-ca
# - 1 cli

# Tester le chaincode
docker exec cli peer chaincode query \
  -C contrats-fonciers \
  -n contrats-fonciers \
  -c '{"function":"queryAllContracts","Args":[]}'
```

---

## 🔧 Méthode 2 : Déploiement Manuel

### Étape 1 : Cloner sur le Serveur

```bash
# Se connecter au serveur
ssh ubuntu@votre-serveur.com

# Cloner le projet
git clone https://github.com/VOTRE-USERNAME/my-blockchain.git
cd my-blockchain
```

### Étape 2 : Configuration

```bash
# Copier les variables d'environnement
cp .env.example .env

# Éditer si nécessaire (ports, domaine, etc.)
nano .env

# Rendre les scripts exécutables
chmod +x scripts/*.sh
```

### Étape 3 : Déploiement

```bash
# Lancer le déploiement complet (1 commande)
./scripts/deploy-complete.sh

# Ce script effectue automatiquement :
# 1. Vérification des prérequis
# 2. Nettoyage de l'environnement
# 3. Démarrage des 4 Fabric CA
# 4. Génération des certificats avec fabric-ca-client
# 5. Création du genesis block
# 6. Démarrage du réseau (orderer + peers + CouchDB)
# 7. Création du channel "contrats-fonciers"
# 8. Jonction des peers au channel
# 9. Déploiement du chaincode Java
# 10. Démarrage de l'API REST
```

### Étape 4 : Vérification

```bash
# Vérifier les conteneurs
docker ps

# Tester l'API
curl http://localhost:3000/health

# Logs en temps réel
docker logs -f peer0.afor.foncier.ci
```

---

## 📊 Services et Ports

Une fois déployé, les services sont accessibles sur :

| Service | Port | URL | Credentials |
|---------|------|-----|-------------|
| **API REST** | 3000 | http://serveur:3000 | - |
| **CouchDB AFOR** | 5984 | http://serveur:5984/_utils | admin/adminpw |
| **CouchDB CVGFR** | 6984 | http://serveur:6984/_utils | admin/adminpw |
| **CouchDB PREFET** | 7984 | http://serveur:7984/_utils | admin/adminpw |
| **Orderer** | 7050 | grpcs://serveur:7050 | TLS |
| **Peer AFOR** | 7051 | grpcs://serveur:7051 | TLS |
| **Peer CVGFR** | 8051 | grpcs://serveur:8051 | TLS |
| **Peer PREFET** | 9051 | grpcs://serveur:9051 | TLS |
| **Fabric CA AFOR** | 7054 | https://serveur:7054 | admin/adminpw |
| **Fabric CA CVGFR** | 8054 | https://serveur:8054 | admin/adminpw |
| **Fabric CA PREFET** | 9054 | https://serveur:9054 | admin/adminpw |
| **Fabric CA Orderer** | 10054 | https://serveur:10054 | admin/adminpw |

---

## 🔒 Sécurité en Production

### 1. Changer les Mots de Passe

```bash
# Éditer .env sur le serveur
nano .env

# Changer :
COUCHDB_PASSWORD=votre-mot-de-passe-fort
CA_ADMIN_PASSWORD=votre-mot-de-passe-fort
API_JWT_SECRET=votre-secret-jwt-fort

# Redémarrer
./scripts/network.sh down
./scripts/deploy-complete.sh
```

### 2. Configurer le Pare-feu

```bash
# Autoriser uniquement les ports nécessaires
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 3000/tcp  # API REST
sudo ufw allow 7050/tcp  # Orderer (si accès externe)
sudo ufw allow 7051/tcp  # Peer AFOR (si accès externe)
sudo ufw allow 8051/tcp  # Peer CVGFR (si accès externe)
sudo ufw allow 9051/tcp  # Peer PREFET (si accès externe)

# Bloquer tout le reste
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Activer
sudo ufw enable
```

### 3. TLS pour l'API (optionnel avec Nginx)

```bash
# Installer Nginx
sudo apt install nginx certbot python3-certbot-nginx -y

# Configurer le reverse proxy
sudo nano /etc/nginx/sites-available/blockchain-api

# Ajouter :
# server {
#     listen 80;
#     server_name api.votredomaine.com;
#     location / {
#         proxy_pass http://localhost:3000;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }

# Activer
sudo ln -s /etc/nginx/sites-available/blockchain-api /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Obtenir un certificat SSL Let's Encrypt
sudo certbot --nginx -d api.votredomaine.com
```

---

## 🛠️ Maintenance

### Redémarrer le Réseau

```bash
cd my-blockchain

# Arrêter
./scripts/network.sh down

# Redémarrer
./scripts/deploy-complete.sh
```

### Mettre à Jour depuis Git

```bash
cd my-blockchain

# Arrêter le réseau
docker-compose -f deploy/docker-compose.yaml down

# Mettre à jour le code
git pull origin main

# Redéployer
./scripts/deploy-complete.sh
```

### Sauvegarder les Données

```bash
# Sauvegarder les volumes Docker
mkdir -p ~/backups
docker run --rm \
  -v deploy_orderer.foncier.ci:/data \
  -v ~/backups:/backup \
  ubuntu tar czf /backup/orderer-$(date +%Y%m%d).tar.gz /data

# Sauvegarder CouchDB
for port in 5984 6984 7984; do
  curl -X GET http://admin:adminpw@localhost:$port/_all_dbs | \
    jq -r '.[]' | while read db; do
      curl -X GET http://admin:adminpw@localhost:$port/$db/_all_docs?include_docs=true > \
        ~/backups/$db-$(date +%Y%m%d).json
    done
done
```

### Restaurer les Données

```bash
# Restaurer un volume
docker run --rm \
  -v deploy_orderer.foncier.ci:/data \
  -v ~/backups:/backup \
  ubuntu tar xzf /backup/orderer-20241019.tar.gz -C /

# Redémarrer
./scripts/network.sh down
./scripts/deploy-complete.sh
```

---

## 📞 Dépannage

### Les conteneurs ne démarrent pas

```bash
# Vérifier les logs
docker logs orderer.foncier.ci
docker logs peer0.afor.foncier.ci

# Nettoyer complètement
./scripts/network.sh down
docker system prune -af --volumes
./scripts/deploy-complete.sh
```

### L'API ne répond pas

```bash
# Vérifier le statut
curl http://localhost:3000/health

# Vérifier les logs
docker logs -f foncier-api

# Redémarrer l'API
docker-compose restart foncier-api
```

### Erreur de certificats

```bash
# Régénérer les certificats
cd my-blockchain
sudo rm -rf network/organizations/ordererOrganizations
sudo rm -rf network/organizations/peerOrganizations

# Redéployer
./scripts/deploy-complete.sh
```

---

## ✅ Checklist de Déploiement

- [ ] Serveur préparé avec Docker, Docker Compose, binaires Fabric
- [ ] Repository Git initialisé avec `./scripts/init-git.sh`
- [ ] Secrets GitHub configurés (SERVER_HOST, SERVER_USER, SERVER_SSH_KEY)
- [ ] Code poussé sur GitHub : `git push origin main`
- [ ] Workflow GitHub Actions exécuté avec succès
- [ ] 12 conteneurs en cours d'exécution : `docker ps`
- [ ] Chaincode déployé et testé
- [ ] API accessible : `curl http://serveur:3000/health`
- [ ] Mots de passe changés en production
- [ ] Pare-feu configuré
- [ ] Sauvegardes planifiées

---

## 🎉 Félicitations !

Votre réseau blockchain Hyperledger Fabric 3.1.1 est maintenant déployé et opérationnel !

**Prochaines étapes :**
- Tester l'API REST : `docs/API.md`
- Consulter la documentation : `DEPLOYMENT.md`
- Configurer le monitoring (Prometheus/Grafana)
- Planifier les sauvegardes automatiques

**Support :**
- Documentation : `README.md`
- Guide complet : `DEPLOYMENT.md`
- API : `docs/API.md`
