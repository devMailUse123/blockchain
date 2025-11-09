# 🚀 Guide de Déploiement CI/CD Automatisé

## 📋 Vue d'ensemble

Ce projet utilise une approche **conteneurisée complète** avec CI/CD automatisé via GitHub Actions.

**Workflow** :
```
git push → GitHub Actions → Build Images → Push Registry → Deploy VM
```

## 🏗️ Architecture

### Images Docker

1. **foncier-deployer** : Image utilitaire contenant :
   - Scripts de génération certificats
   - Scripts création channels
   - Chaincode compilé
   - Fabric binaries (cryptogen, configtxgen, peer)

2. **foncier-api** : API REST Node.js

### Fichiers clés

```
├── Dockerfile.deployer          # Image deployer
├── api/Dockerfile               # Image API
├── docker-compose.ci.yml        # Orchestration CI/CD
├── .github/workflows/
│   └── build-and-deploy.yml     # Pipeline GitHub Actions
├── deploy-production.sh         # Script déploiement simplifié
└── docker/
    └── deployer-entrypoint.sh   # Entrypoint deployer
```

---

## 🔧 Configuration initiale

### 1. GitHub Repository Secrets

Aller dans **Settings → Secrets and variables → Actions** et ajouter :

```
VM1_SSH_KEY       = Votre clé SSH privée (Ed25519)
GITHUB_TOKEN      = Fourni automatiquement par GitHub
```

### 2. Activer GitHub Container Registry

Le workflow utilise `ghcr.io` (GitHub Container Registry) :
- Activé automatiquement avec GITHUB_TOKEN
- Images publiques : Pas besoin d'authentification pour pull
- Images privées : Nécessite authentification

---

## 🚀 Workflow CI/CD

### Déclencheurs

Le pipeline se déclenche sur :

1. **Push sur `main` ou `develop`** :
   - Build images
   - Tag avec nom de branche
   - Push vers registry

2. **Tags `v*`** (exemple: `v1.0.0`) :
   - Build images
   - Tag avec version sémantique
   - Push vers registry
   - **Déploiement automatique sur VM1**

3. **Pull Requests** :
   - Build images (sans push)
   - Tests uniquement

### Étapes du Pipeline

```yaml
jobs:
  1. build-chaincode    # Compile JAR Java
  2. build-deployer     # Build image deployer
  3. build-api          # Build image API
  4. deploy-production  # Deploy sur VM1 (si tag)
  5. notify             # Notification résultat
```

### Durée estimée

- Build chaincode : 2-3 min
- Build deployer : 3-5 min
- Build API : 2-3 min
- Deploy : 2-3 min

**Total : 10-15 minutes**

---

## 📦 Déploiement Manuel

### Option 1 : Via script automatisé

Sur VM1 :

```bash
# Télécharger le script
curl -fsSL https://raw.githubusercontent.com/AforInnov/afor-blockchain/main/deploy-production.sh \
  -o deploy.sh && chmod +x deploy.sh

# Déployer version spécifique
./deploy.sh v1.0.0

# Ou dernière version
./deploy.sh latest
```

### Option 2 : Étapes manuelles

```bash
# 1. Télécharger docker-compose
curl -fsSL https://raw.githubusercontent.com/AforInnov/afor-blockchain/main/docker-compose.ci.yml \
  -o docker-compose.yml

# 2. Définir variables
export REGISTRY=ghcr.io/aforinnov
export VERSION=v1.0.0

# 3. Pull images
docker compose pull

# 4. Démarrer
docker compose up -d

# 5. Vérifier
sleep 60
curl http://localhost:3000/health
```

---

## 🔄 Workflow de développement

### Développement local

```bash
# Compiler chaincode
cd chaincode-java && mvn clean package

# Build images localement
docker build -f Dockerfile.deployer -t foncier-deployer:dev .
docker build -f api/Dockerfile -t foncier-api:dev api/

# Tester avec docker-compose
export REGISTRY=localhost VERSION=dev
docker compose -f docker-compose.ci.yml up -d
```

### Créer une release

```bash
# 1. Commit et push code
git add .
git commit -m "feat: nouvelle fonctionnalité"
git push origin main

# 2. Créer tag version
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# 3. GitHub Actions se déclenche automatiquement
# 4. Déploiement automatique sur VM1
# 5. Vérifier sur http://18.194.235.149:3000
```

---

## 🐛 Debugging

### Voir les logs du pipeline

GitHub → Actions → Sélectionner run → Voir logs par job

### Logs sur VM1

```bash
# API
docker logs -f api-rest

# Tous les services
docker compose logs -f

# Service spécifique
docker logs -f peer0.afor.foncier.ci
```

### Problèmes courants

**Images non téléchargées** :
```bash
# Vérifier registry
docker pull ghcr.io/aforinnov/foncier-deployer:latest

# Authentification si privé
echo $GITHUB_TOKEN | docker login ghcr.io -u username --password-stdin
```

**Certificats non générés** :
```bash
# Vérifier init-deployer
docker logs init-deployer

# Regénérer manuellement
docker run -v fabric-crypto:/opt/blockchain/network/organizations \
  ghcr.io/aforinnov/foncier-deployer:latest generate-crypto
```

**API ne démarre pas** :
```bash
# Vérifier dépendances
docker compose ps

# Redémarrer API
docker compose restart api-rest
```

---

## 🎯 Avantages de cette approche

✅ **Zéro configuration manuelle sur VM**
   - Pas de Maven, Node.js, build tools
   - Juste Docker

✅ **Reproductibilité totale**
   - Même image = même comportement
   - Versioning clair

✅ **Déploiement rapide**
   - `git push` → Déployé en 15 min
   - Rollback facile : `deploy.sh v1.0.0`

✅ **Isolation complète**
   - Certificats dans volumes Docker
   - Pas de fichiers sur filesystem

✅ **Scalabilité**
   - Multi-VM : même images, différentes configs
   - Ajout nœuds : juste docker compose up

---

## 📊 Monitoring

### Health checks

```bash
# API
curl http://localhost:3000/health

# Peers (via API)
curl http://localhost:3000/api/peers

# Docker health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### Métriques Prometheus

Les peers exposent métriques sur ports :
- peer0.afor : 9443
- peer0.cvgfr : 9444
- peer0.prefet : 9445

---

## 🔐 Sécurité

### Images Docker

- **Base images officielles** : hyperledger/fabric, node:18-alpine
- **Multi-stage builds** : Images optimisées
- **Scan vulnérabilités** : Intégrer Snyk/Trivy dans CI

### Secrets

- **Certificats** : Volumes Docker (pas dans images)
- **Clés privées** : Jamais dans code/images
- **GitHub Secrets** : SSH keys, tokens

### Production

Recommandations :
1. Images privées (registry privé)
2. TLS activé entre tous composants
3. Firewall sur VM (seulement port 3000 public)
4. Rotation certificats automatique

---

## 🚀 Prochaines étapes

1. **Ajouter tests automatisés** dans CI
   ```yaml
   - name: Run integration tests
     run: |
       docker compose -f docker-compose.ci.yml up -d
       sleep 60
       npm run test:integration
   ```

2. **Notifications** Slack/Discord sur déploiement

3. **Environnements multiples**
   - `develop` → VM staging
   - `main` → VM production

4. **Backup automatique** volumes Docker

---

## 📞 Support

Issues : https://github.com/AforInnov/afor-blockchain/issues
CI/CD docs : `.github/workflows/build-and-deploy.yml`
