#!/bin/bash
# ============================================================
# User Data Script - Peer Node Setup
# Hyperledger Fabric 3.1.1 - Ubuntu 22.04 LTS
# ============================================================

set -euo pipefail

# Variables
LOG_FILE="/var/log/fabric-setup.log"
FABRIC_VERSION="3.1.1"
NODE_VERSION="18"

# Fonction de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================="
log "Début de l'installation Peer Node"
log "========================================="

# Mise à jour du système
log "Mise à jour du système..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y

# Installation des outils de base
log "Installation des outils de base..."
apt-get install -y \
    curl \
    wget \
    git \
    jq \
    unzip \
    ca-certificates \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common \
    net-tools \
    vim \
    htop \
    awscli

# Configuration du volume de données
log "Configuration du volume de données..."
if lsblk | grep -q nvme1n1; then
    DATA_DEVICE="/dev/nvme1n1"
elif lsblk | grep -q xvdf; then
    DATA_DEVICE="/dev/xvdf"
else
    log "AVERTISSEMENT: Volume de données non trouvé"
    DATA_DEVICE=""
fi

if [ -n "$DATA_DEVICE" ]; then
    # Formatter le volume si pas déjà formaté
    if ! blkid "$DATA_DEVICE"; then
        log "Formatage du volume de données..."
        mkfs.ext4 "$DATA_DEVICE"
    fi
    
    # Créer le point de montage
    mkdir -p /data
    
    # Monter le volume
    mount "$DATA_DEVICE" /data
    
    # Ajouter au fstab pour montage automatique
    UUID=$(blkid -s UUID -o value "$DATA_DEVICE")
    echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab
    
    log "Volume de données monté sur /data"
fi

# Créer les répertoires pour Fabric
log "Création des répertoires Fabric..."
mkdir -p /data/fabric/{crypto-config,ledger,chaincode,logs}
mkdir -p /opt/fabric/{config,scripts}

# Installation de Docker
log "Installation de Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrer et activer Docker
systemctl start docker
systemctl enable docker

# Ajouter l'utilisateur ubuntu au groupe docker
usermod -aG docker ubuntu

# Configuration Docker pour les volumes de données
log "Configuration Docker..."
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "/data/docker",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "live-restore": true,
  "storage-driver": "overlay2"
}
EOF

systemctl restart docker

# Installation de Docker Compose v2
log "Vérification de Docker Compose..."
docker compose version

# Installation de Node.js et npm
log "Installation de Node.js ${NODE_VERSION}..."
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs

# Vérifier les versions
log "Versions installées:"
docker --version | tee -a "$LOG_FILE"
docker compose version | tee -a "$LOG_FILE"
node --version | tee -a "$LOG_FILE"
npm --version | tee -a "$LOG_FILE"

# Télécharger les binaires Fabric
log "Téléchargement des binaires Hyperledger Fabric ${FABRIC_VERSION}..."
cd /opt/fabric
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary ${FABRIC_VERSION}

# Ajouter les binaires au PATH
echo 'export PATH=$PATH:/opt/fabric/bin' >> /etc/profile.d/fabric.sh
echo 'export FABRIC_CFG_PATH=/opt/fabric/config' >> /etc/profile.d/fabric.sh
chmod +x /etc/profile.d/fabric.sh

# Installation de l'agent CloudWatch
log "Installation de l'agent CloudWatch..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

# Configuration de l'agent CloudWatch
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
AWS_REGION=$(ec2-metadata --availability-zone | cut -d " " -f 2 | sed 's/[a-z]$//')

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<EOF
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/data/fabric/logs/*.log",
            "log_group_name": "/aws/ec2/fabric-peer",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/fabric-setup.log",
            "log_group_name": "/aws/ec2/fabric-peer",
            "log_stream_name": "{instance_id}/setup",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "FabricPeer",
    "metrics_collected": {
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUsedPercent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUsedPercent",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      }
    }
  }
}
EOF

# Démarrer l'agent CloudWatch
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Configuration du firewall (UFW)
log "Configuration du firewall UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.0.0.0/16  # Autoriser tout le trafic VPC
ufw allow 22/tcp  # SSH
ufw status verbose | tee -a "$LOG_FILE"

# Optimisation système pour Fabric
log "Optimisation système..."
cat >> /etc/sysctl.conf <<EOF

# Optimisations pour Hyperledger Fabric
net.core.somaxconn=4096
net.ipv4.tcp_max_syn_backlog=4096
net.ipv4.ip_local_port_range=1024 65535
net.core.netdev_max_backlog=5000
vm.swappiness=10
fs.file-max=2097152
EOF

sysctl -p

# Limites de fichiers
cat >> /etc/security/limits.conf <<EOF

# Limites pour Hyperledger Fabric
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   65536
*       hard    nproc   65536
EOF

# Script de santé pour monitoring
log "Création du script de monitoring..."
cat > /opt/fabric/scripts/health-check.sh <<'EOF'
#!/bin/bash
# Health check script pour peer Fabric

# Vérifier que Docker est actif
if ! systemctl is-active --quiet docker; then
    echo "ERROR: Docker n'est pas actif"
    exit 1
fi

# Vérifier les conteneurs Fabric
PEER_RUNNING=$(docker ps --filter "name=peer" --format "{{.Names}}" | wc -l)
if [ "$PEER_RUNNING" -eq 0 ]; then
    echo "WARNING: Aucun peer en cours d'exécution"
    exit 1
fi

# Vérifier l'espace disque
DISK_USAGE=$(df -h /data | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "WARNING: Utilisation disque > 80%: ${DISK_USAGE}%"
fi

echo "OK: Système sain - Peers: $PEER_RUNNING, Disque: ${DISK_USAGE}%"
exit 0
EOF

chmod +x /opt/fabric/scripts/health-check.sh

# Créer un cron job pour le health check
echo "*/5 * * * * /opt/fabric/scripts/health-check.sh >> /data/fabric/logs/health-check.log 2>&1" | crontab -u ubuntu -

# Créer un script de backup
cat > /opt/fabric/scripts/backup-ledger.sh <<'EOF'
#!/bin/bash
# Script de backup du ledger vers S3

BACKUP_DIR="/data/fabric/backup/$(date +%Y%m%d-%H%M%S)"
S3_BUCKET="${BACKUP_BUCKET:-afor-blockchain-backups}"
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)

mkdir -p "$BACKUP_DIR"

# Backup du ledger
if [ -d "/data/fabric/ledger" ]; then
    tar czf "$BACKUP_DIR/ledger.tar.gz" -C /data/fabric ledger/
    aws s3 cp "$BACKUP_DIR/ledger.tar.gz" "s3://$S3_BUCKET/$INSTANCE_ID/ledger-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo "Backup ledger complété: $BACKUP_DIR/ledger.tar.gz"
fi

# Nettoyage des backups locaux > 7 jours
find /data/fabric/backup -type d -mtime +7 -exec rm -rf {} +

EOF

chmod +x /opt/fabric/scripts/backup-ledger.sh

# Ajouter le backup quotidien au cron
echo "0 2 * * * /opt/fabric/scripts/backup-ledger.sh >> /data/fabric/logs/backup.log 2>&1" | crontab -u ubuntu -

log "========================================="
log "Installation Peer Node terminée avec succès!"
log "========================================="
log "Versions installées:"
log "- Docker: $(docker --version)"
log "- Docker Compose: $(docker compose version)"
log "- Node.js: $(node --version)"
log "- NPM: $(npm --version)"
log ""
log "Prochaines étapes:"
log "1. Déployer les fichiers de configuration MSP"
log "2. Déployer le docker-compose.yml"
log "3. Lancer le réseau Fabric"
log "========================================="

# Signal de fin (pour CloudFormation/Terraform wait conditions)
log "Envoi du signal de succès..."
echo "SETUP_COMPLETE" > /tmp/user-data-complete
