# 🔐 Configuration des Secrets GitHub

Pour activer le déploiement automatique via GitHub Actions, vous devez configurer les secrets suivants dans votre repository GitHub.

---

## 📍 Où Configurer les Secrets

1. Allez sur votre repository GitHub
2. Cliquez sur `Settings` (en haut à droite)
3. Dans le menu latéral gauche, cliquez sur `Secrets and variables` > `Actions`
4. Cliquez sur `New repository secret`

---

## 🔑 Secrets Requis

### 1. SERVER_HOST

**Description :** Adresse IP ou nom de domaine du serveur où déployer le réseau blockchain.

**Exemples :**
- `192.168.1.100` (IP locale)
- `10.0.0.50` (IP privée)
- `blockchain.votredomaine.com` (nom de domaine)
- `ec2-xx-xxx-xxx-xxx.compute.amazonaws.com` (AWS EC2)

**Comment l'obtenir :**
```bash
# Sur le serveur
hostname -I | awk '{print $1}'
```

---

### 2. SERVER_USER

**Description :** Nom d'utilisateur SSH pour se connecter au serveur.

**Exemples :**
- `ubuntu` (Ubuntu)
- `centos` (CentOS)
- `ec2-user` (Amazon Linux)
- `admin` (Debian)
- `deploy` (utilisateur personnalisé)

**Comment vérifier :**
```bash
# Sur le serveur
whoami
```

---

### 3. SERVER_SSH_KEY

**Description :** Clé privée SSH (format PEM) pour l'authentification sans mot de passe.

**⚠️ IMPORTANT :** Copiez **TOUT** le contenu de la clé privée, y compris les lignes `-----BEGIN RSA PRIVATE KEY-----` et `-----END RSA PRIVATE KEY-----`.

#### Générer une Nouvelle Clé SSH

```bash
# Sur votre machine locale (pas sur le serveur)
ssh-keygen -t rsa -b 4096 -C "github-deploy@votredomaine.com" -f ~/.ssh/github_deploy

# Appuyez sur Entrée pour accepter le chemin par défaut
# Appuyez sur Entrée deux fois pour ne pas mettre de passphrase (sinon GitHub Actions ne pourra pas l'utiliser)
```

#### Copier la Clé Publique sur le Serveur

```bash
# Copier automatiquement (recommandé)
ssh-copy-id -i ~/.ssh/github_deploy.pub ubuntu@192.168.1.100

# OU copier manuellement
cat ~/.ssh/github_deploy.pub
# Copiez le contenu, puis sur le serveur :
# mkdir -p ~/.ssh
# nano ~/.ssh/authorized_keys
# Collez la clé publique et sauvegardez
```

#### Obtenir la Clé Privée à Copier dans GitHub

```bash
# Sur votre machine locale
cat ~/.ssh/github_deploy

# Copiez TOUT le contenu (exemple) :
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3JLq9... (nombreuses lignes)
...
...
-----END RSA PRIVATE KEY-----
```

**Format dans GitHub Secret :**
```
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA0Z3JLq9mX5N8YjJwZvYH8... (ligne 1)
bXqZ9kL3mN7pQ2rS4tU5vW6xY7zA8... (ligne 2)
... (toutes les lignes)
-----END RSA PRIVATE KEY-----
```

#### Vérifier que la Connexion Fonctionne

```bash
# Tester la connexion SSH avec la nouvelle clé
ssh -i ~/.ssh/github_deploy ubuntu@192.168.1.100

# Si ça fonctionne sans demander de mot de passe, c'est bon !
```

---

### 4. SERVER_PORT (Optionnel)

**Description :** Port SSH du serveur (par défaut : 22).

**Exemples :**
- `22` (port SSH par défaut)
- `2222` (port SSH personnalisé)
- `2200`

**Comment vérifier :**
```bash
# Sur le serveur
sudo netstat -tulpn | grep ssh
# ou
cat /etc/ssh/sshd_config | grep "^Port"
```

**⚠️ Note :** Si votre serveur utilise le port SSH par défaut (22), vous pouvez omettre ce secret.

---

## 📝 Résumé des Secrets

| Secret Name | Description | Obligatoire | Exemple |
|------------|-------------|-------------|---------|
| `SERVER_HOST` | IP ou domaine du serveur | ✅ Oui | `192.168.1.100` |
| `SERVER_USER` | Utilisateur SSH | ✅ Oui | `ubuntu` |
| `SERVER_SSH_KEY` | Clé privée SSH complète | ✅ Oui | `-----BEGIN RSA...` |
| `SERVER_PORT` | Port SSH | ⚪ Non (défaut: 22) | `22` |

---

## ✅ Vérification de la Configuration

Une fois les secrets configurés, vérifiez en déclenchant manuellement le workflow :

### Méthode 1 : Via l'Interface GitHub

1. Allez sur votre repository
2. Cliquez sur `Actions`
3. Sélectionnez le workflow `🚀 Deploy Blockchain Network`
4. Cliquez sur `Run workflow` (en haut à droite)
5. Sélectionnez la branche `main`
6. Cliquez sur `Run workflow` (bouton vert)

### Méthode 2 : Via GitHub CLI

```bash
# Installer GitHub CLI si nécessaire
# https://cli.github.com/

# Se connecter
gh auth login

# Déclencher le workflow
gh workflow run deploy.yml
```

### Vérifier l'Exécution

1. Allez dans `Actions`
2. Cliquez sur l'exécution en cours
3. Suivez les logs en temps réel
4. Vérifiez que toutes les étapes se terminent avec ✅

---

## 🔒 Sécurité des Secrets

### Bonnes Pratiques

✅ **À FAIRE :**
- Utiliser une clé SSH dédiée pour GitHub Actions (pas votre clé personnelle)
- Ne jamais partager vos secrets
- Révoquer et régénérer les clés si elles sont compromises
- Limiter les permissions de la clé SSH sur le serveur
- Utiliser des utilisateurs dédiés pour le déploiement (ex: `deploy`)

❌ **À ÉVITER :**
- Commiter des secrets dans le code
- Réutiliser la même clé SSH partout
- Utiliser l'utilisateur `root` pour le déploiement
- Partager les secrets par email ou chat

### Créer un Utilisateur Dédié au Déploiement (Recommandé)

```bash
# Sur le serveur
sudo adduser deploy
sudo usermod -aG docker deploy
sudo usermod -aG sudo deploy

# Configurer SSH pour l'utilisateur deploy
sudo mkdir -p /home/deploy/.ssh
sudo nano /home/deploy/.ssh/authorized_keys
# Collez la clé publique GitHub

sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh
sudo chmod 600 /home/deploy/.ssh/authorized_keys

# Tester
ssh -i ~/.ssh/github_deploy deploy@192.168.1.100
```

Puis utilisez `SERVER_USER=deploy` dans vos secrets GitHub.

---

## 🔄 Rotation des Secrets

Il est recommandé de changer régulièrement vos clés SSH :

```bash
# 1. Générer une nouvelle clé
ssh-keygen -t rsa -b 4096 -C "github-deploy-new@votredomaine.com" -f ~/.ssh/github_deploy_new

# 2. Ajouter la nouvelle clé publique sur le serveur
ssh-copy-id -i ~/.ssh/github_deploy_new.pub ubuntu@serveur

# 3. Tester la nouvelle clé
ssh -i ~/.ssh/github_deploy_new ubuntu@serveur

# 4. Mettre à jour le secret SERVER_SSH_KEY sur GitHub
cat ~/.ssh/github_deploy_new
# Copiez le contenu dans GitHub Secrets

# 5. Tester le déploiement avec la nouvelle clé

# 6. Supprimer l'ancienne clé publique du serveur
# Sur le serveur :
nano ~/.ssh/authorized_keys
# Supprimez l'ancienne ligne

# 7. Supprimer l'ancienne clé locale
rm ~/.ssh/github_deploy ~/.ssh/github_deploy.pub
mv ~/.ssh/github_deploy_new ~/.ssh/github_deploy
mv ~/.ssh/github_deploy_new.pub ~/.ssh/github_deploy.pub
```

---

## 🐛 Dépannage

### Erreur : "Permission denied (publickey)"

**Problème :** La clé SSH n'est pas correctement configurée.

**Solutions :**
```bash
# 1. Vérifier que la clé publique est bien sur le serveur
ssh ubuntu@serveur cat ~/.ssh/authorized_keys

# 2. Vérifier les permissions
ssh ubuntu@serveur chmod 700 ~/.ssh
ssh ubuntu@serveur chmod 600 ~/.ssh/authorized_keys

# 3. Vérifier le format de la clé dans GitHub
# Assurez-vous d'avoir copié TOUTE la clé (BEGIN et END inclus)

# 4. Tester manuellement
ssh -i ~/.ssh/github_deploy -v ubuntu@serveur
# Le -v affiche les détails pour déboguer
```

### Erreur : "Host key verification failed"

**Problème :** Le serveur n'est pas dans les known_hosts.

**Solution :** Le workflow GitHub Actions gère cela automatiquement avec `ssh-keyscan`. Si le problème persiste :

```bash
# Sur votre machine locale
ssh-keyscan -H 192.168.1.100 >> ~/.ssh/known_hosts
```

### Erreur : "Connection refused"

**Problème :** Le serveur SSH n'écoute pas ou le pare-feu bloque.

**Solutions :**
```bash
# Sur le serveur, vérifier que SSH fonctionne
sudo systemctl status sshd

# Vérifier le port SSH
sudo netstat -tulpn | grep ssh

# Vérifier le pare-feu
sudo ufw status
sudo ufw allow 22/tcp  # Ou votre port SSH personnalisé
```

---

## 📞 Support

Si vous rencontrez des problèmes avec la configuration des secrets :

1. Vérifiez que vous avez copié **TOUTE** la clé privée (BEGIN → END)
2. Testez la connexion SSH manuellement depuis votre machine
3. Vérifiez les logs du workflow GitHub Actions
4. Consultez la documentation GitHub Actions : https://docs.github.com/en/actions/security-guides/encrypted-secrets

---

**Dernière mise à jour :** 19 octobre 2025  
**Fichier maintenu par :** Équipe DevOps AFOR
