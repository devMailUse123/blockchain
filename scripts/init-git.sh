#!/bin/bash

# ============================================================================
# SCRIPT D'INITIALISATION GIT POUR LE PROJET BLOCKCHAIN FONCIER
# ============================================================================

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'affichage
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ============================================================================
# VÉRIFICATION DES PRÉREQUIS
# ============================================================================

log "Vérification des prérequis..."

if ! command -v git &> /dev/null; then
    error "Git n'est pas installé"
    exit 1
fi

if [ -d ".git" ]; then
    warn "Repository Git déjà initialisé"
    read -p "Voulez-vous réinitialiser le repository ? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Suppression de l'ancien repository Git..."
        rm -rf .git
    else
        log "Utilisation du repository existant"
        exit 0
    fi
fi

# ============================================================================
# INITIALISATION GIT
# ============================================================================

log "Initialisation du repository Git..."
git init

# Configuration Git
log "Configuration Git..."
git config core.autocrlf false
git config core.fileMode false

# ============================================================================
# CRÉATION DU FICHIER .gitattributes
# ============================================================================

log "Création du fichier .gitattributes..."
cat > .gitattributes << 'EOF'
# Git attributes for consistent line endings
* text=auto

# Scripts shell should use LF
*.sh text eol=lf

# Windows scripts should use CRLF
*.bat text eol=crlf
*.ps1 text eol=crlf

# Java files
*.java text diff=java
*.gradle text diff=java
*.properties text
*.xml text

# JavaScript files
*.js text
*.json text
*.jsx text

# YAML files
*.yaml text
*.yml text

# Markdown
*.md text

# Docker
Dockerfile text
*.dockerignore text

# Binary files
*.jar binary
*.class binary
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
EOF

# ============================================================================
# VÉRIFICATION DU .gitignore
# ============================================================================

if [ ! -f ".gitignore" ]; then
    error ".gitignore n'existe pas. Créez-le avant d'initialiser Git."
    exit 1
fi

log "Fichier .gitignore trouvé ✓"

# ============================================================================
# AJOUT DES FICHIERS
# ============================================================================

log "Ajout des fichiers au staging..."

# Ajouter tous les fichiers sauf ceux ignorés
git add .

# ============================================================================
# VÉRIFICATION DES FICHIERS SENSIBLES
# ============================================================================

log "Vérification qu'aucun fichier sensible n'est ajouté..."

SENSITIVE_FILES=(
    "*.pem"
    "*.key"
    "*.crt"
    ".env"
    "network/organizations/ordererOrganizations"
    "network/organizations/peerOrganizations"
    "network/channel-artifacts/*.block"
    "production/"
)

HAS_SENSITIVE=0

for pattern in "${SENSITIVE_FILES[@]}"; do
    if git ls-files | grep -q "$pattern"; then
        error "Fichier sensible détecté : $pattern"
        HAS_SENSITIVE=1
    fi
done

if [ $HAS_SENSITIVE -eq 1 ]; then
    error "Des fichiers sensibles ont été détectés. Vérifiez votre .gitignore"
    exit 1
fi

log "Aucun fichier sensible détecté ✓"

# ============================================================================
# AFFICHAGE DES FICHIERS À COMMITER
# ============================================================================

log "Fichiers qui seront commitées :"
echo ""
git status --short
echo ""

# ============================================================================
# CRÉATION DU PREMIER COMMIT
# ============================================================================

read -p "Créer le commit initial ? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Création du commit initial..."
    
    git commit -m "feat: Initial Hyperledger Fabric 3.1.1 network setup

- ✅ 3 organizations (AFOR, CVGFR, PREFET)
- ✅ Fabric CA setup with fabric-ca-client enrollment
- ✅ Java chaincode with fabric-contract-api
- ✅ Spring Boot REST API with fabric-gateway
- ✅ Docker Compose orchestration (orderer + 3 peers + 3 CouchDB + 4 CAs)
- ✅ Complete deployment automation scripts
- ✅ GitHub Actions CI/CD workflow
- ✅ Comprehensive documentation (README, DEPLOYMENT, API)
- ✅ Security-focused .gitignore (excludes certificates, keys, blockchain data)
- ✅ Fabric 3.1.1 configtx.yaml (Channel Participation API, no Consortiums)
- ✅ Complete MSP structure with NodeOUs
- ✅ TLS enabled on all components"

    log "Commit initial créé ✓"
else
    log "Commit annulé. Vous pouvez créer le commit manuellement avec :"
    echo "  git commit -m 'Initial commit'"
fi

# ============================================================================
# CONFIGURATION DU REMOTE (OPTIONNEL)
# ============================================================================

echo ""
read -p "Voulez-vous configurer le remote GitHub ? (y/N) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    read -p "Entrez l'URL du repository GitHub (ex: https://github.com/user/repo.git): " REMOTE_URL
    
    if [ -n "$REMOTE_URL" ]; then
        log "Ajout du remote 'origin'..."
        git remote add origin "$REMOTE_URL"
        
        log "Remote ajouté ✓"
        
        read -p "Voulez-vous pousser sur GitHub maintenant ? (y/N) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Push vers GitHub..."
            git branch -M main
            git push -u origin main
            
            log "Code poussé sur GitHub ✓"
        fi
    fi
fi

# ============================================================================
# CRÉATION DU FICHIER README POUR LES SECRETS
# ============================================================================

log "Création du guide de configuration des secrets GitHub..."
cat > .github/SECRETS.md << 'EOF'
# 🔐 Configuration des Secrets GitHub

Pour activer le déploiement automatique via GitHub Actions, configurez les secrets suivants :

## Secrets Requis

Allez dans `Settings > Secrets and variables > Actions` et ajoutez :

| Secret Name | Description | Exemple |
|------------|-------------|---------|
| `SERVER_HOST` | IP ou nom de domaine du serveur | `192.168.1.100` ou `blockchain.votredomaine.com` |
| `SERVER_USER` | Nom d'utilisateur SSH | `ubuntu` ou `deploy` |
| `SERVER_SSH_KEY` | Clé privée SSH pour l'authentification | Contenu complet de votre fichier `~/.ssh/id_rsa` |
| `SERVER_PORT` | Port SSH (optionnel, par défaut 22) | `22` |

## Génération de la Clé SSH

Si vous n'avez pas encore de clé SSH :

```bash
# Sur votre machine locale
ssh-keygen -t rsa -b 4096 -C "github-actions@votredomaine.com" -f ~/.ssh/github_deploy

# Copier la clé publique sur le serveur
ssh-copy-id -i ~/.ssh/github_deploy.pub user@serveur

# Afficher la clé privée à copier dans GitHub Secrets
cat ~/.ssh/github_deploy
```

## Vérification

Une fois les secrets configurés, le workflow se déclenchera automatiquement à chaque push sur `main`.

Vous pouvez aussi déclencher manuellement :
- Via l'interface : `Actions > Deploy to Server > Run workflow`
- Via CLI : `gh workflow run deploy.yml`
EOF

log "Guide des secrets créé : .github/SECRETS.md"

# ============================================================================
# RÉSUMÉ
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${GREEN}✓${NC} Repository Git initialisé avec succès                     ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Prochaines étapes :"
echo "  1. Vérifier les fichiers commitées : git log --stat"
echo "  2. Configurer le remote GitHub si pas encore fait"
echo "  3. Pousser le code : git push -u origin main"
echo "  4. Configurer les secrets GitHub : voir .github/SECRETS.md"
echo "  5. Le déploiement automatique se déclenchera sur le prochain push"
echo ""

log "Pour déployer sur un serveur :"
echo "  1. Cloner sur le serveur : git clone <url>"
echo "  2. Configurer l'environnement : cp .env.example .env"
echo "  3. Déployer : ./scripts/deploy-complete.sh"
echo ""

warn "N'oubliez pas : ne commitez JAMAIS les certificats, clés ou fichiers .env !"
echo ""
