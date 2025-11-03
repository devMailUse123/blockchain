#!/bin/bash
# ============================================================
# User Data Script - Orderer Node Setup
# Hyperledger Fabric 3.1.1 - Ubuntu 22.04 LTS
# ============================================================

set -euo pipefail

# Variables
LOG_FILE="/var/log/fabric-setup.log"
FABRIC_VERSION="3.1.1"

# Fonction de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================="
log "Début de l'installation Orderer Node"
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
    if ! blkid "$DATA_DEVICE"; then
        log "Formatage du volume de données..."
        mkfs.ext4 "$DATA_DEVICE"
    fi
    
    mkdir -p /data
    mount "$DATA_DEVICE" /data
    
    UUID=$(blkid -s UUID -o value "$DATA_DEVICE")
    echo "UUID=$UUID /data ext4 defaults,nofail 0 2" >> /etc/fstab
    
    log "Volume de données monté sur /data"
fi

# Créer les répertoires pour Fabric et Monitoring
log "Création des répertoires..."
mkdir -p /data/fabric/{crypto-config,ledger,logs}
mkdir -p /data/prometheus
mkdir -p /data/grafana
mkdir -p /data/blockchain-explorer
mkdir -p /opt/fabric/{config,scripts}
mkdir -p /opt/monitoring/{prometheus,grafana}

# Installation de Docker
log "Installation de Docker..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Configuration Docker
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

# Vérifier Docker Compose
log "Vérification de Docker Compose..."
docker compose version

# Télécharger les binaires Fabric
log "Téléchargement des binaires Hyperledger Fabric ${FABRIC_VERSION}..."
cd /opt/fabric
curl -sSL https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh | bash -s -- binary ${FABRIC_VERSION}

echo 'export PATH=$PATH:/opt/fabric/bin' >> /etc/profile.d/fabric.sh
echo 'export FABRIC_CFG_PATH=/opt/fabric/config' >> /etc/profile.d/fabric.sh
chmod +x /etc/profile.d/fabric.sh

# Installation de l'agent CloudWatch
log "Installation de l'agent CloudWatch..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm amazon-cloudwatch-agent.deb

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
            "log_group_name": "/aws/ec2/fabric-orderer",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/fabric-setup.log",
            "log_group_name": "/aws/ec2/fabric-orderer",
            "log_stream_name": "{instance_id}/setup",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "FabricOrderer",
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
        "resources": ["*"]
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

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
    -a fetch-config \
    -m ec2 \
    -s \
    -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

# Configuration du firewall
log "Configuration du firewall UFW..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow from 10.0.0.0/16
ufw allow 22/tcp
ufw allow 3000/tcp  # Grafana
ufw allow 9090/tcp  # Prometheus
ufw allow 8080/tcp  # Blockchain Explorer
ufw status verbose | tee -a "$LOG_FILE"

# Optimisation système
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

cat >> /etc/security/limits.conf <<EOF

# Limites pour Hyperledger Fabric
*       soft    nofile  65536
*       hard    nofile  65536
*       soft    nproc   65536
*       hard    nproc   65536
EOF

# Configuration Prometheus
log "Configuration de Prometheus..."
cat > /opt/monitoring/prometheus/prometheus.yml <<EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'fabric-production'
    region: '${AWS_REGION}'

scrape_configs:
  # Orderer metrics
  - job_name: 'orderer'
    static_configs:
      - targets: ['orderer.foncier.ci:9443']
        labels:
          org: 'orderer'
          node: 'orderer'

  # Peer AFOR metrics
  - job_name: 'peer-afor'
    static_configs:
      - targets: ['peer0.afor.foncier.ci:9443']
        labels:
          org: 'afor'
          node: 'peer0'

  # Peer CVGFR metrics
  - job_name: 'peer-cvgfr'
    static_configs:
      - targets: ['peer0.cvgfr.foncier.ci:9443']
        labels:
          org: 'cvgfr'
          node: 'peer0'

  # Peer PREFET metrics
  - job_name: 'peer-prefet'
    static_configs:
      - targets: ['peer0.prefet.foncier.ci:9443']
        labels:
          org: 'prefet'
          node: 'peer0'

  # Prometheus self-monitoring
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (si installé)
  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']
EOF

# Configuration des alertes Prometheus
cat > /opt/monitoring/prometheus/alerts.yml <<EOF
groups:
  - name: fabric_alerts
    interval: 30s
    rules:
      # Alerte si un peer est down
      - alert: PeerDown
        expr: up{job=~"peer-.*"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Peer {{ \$labels.node }} ({{ \$labels.org }}) est down"
          description: "Le peer {{ \$labels.node }} de l'organisation {{ \$labels.org }} ne répond pas depuis 2 minutes"

      # Alerte si l'orderer est down
      - alert: OrdererDown
        expr: up{job="orderer"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Orderer est down"
          description: "L'orderer ne répond pas depuis 1 minute"

      # Alerte si le disque est plein
      - alert: DiskSpaceLow
        expr: (node_filesystem_avail_bytes{mountpoint="/data"} / node_filesystem_size_bytes{mountpoint="/data"}) * 100 < 20
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Espace disque faible sur {{ \$labels.instance }}"
          description: "Seulement {{ \$value }}% d'espace disque disponible sur /data"

      # Alerte si la mémoire est élevée
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Utilisation mémoire élevée sur {{ \$labels.instance }}"
          description: "Utilisation mémoire: {{ \$value }}%"
EOF

# Script de health check
cat > /opt/fabric/scripts/health-check.sh <<'EOF'
#!/bin/bash
if ! systemctl is-active --quiet docker; then
    echo "ERROR: Docker n'est pas actif"
    exit 1
fi

ORDERER_RUNNING=$(docker ps --filter "name=orderer" --format "{{.Names}}" | wc -l)
if [ "$ORDERER_RUNNING" -eq 0 ]; then
    echo "WARNING: Aucun orderer en cours d'exécution"
    exit 1
fi

DISK_USAGE=$(df -h /data | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "WARNING: Utilisation disque > 80%: ${DISK_USAGE}%"
fi

echo "OK: Système sain - Orderer: $ORDERER_RUNNING, Disque: ${DISK_USAGE}%"
exit 0
EOF

chmod +x /opt/fabric/scripts/health-check.sh
echo "*/5 * * * * /opt/fabric/scripts/health-check.sh >> /data/fabric/logs/health-check.log 2>&1" | crontab -u ubuntu -

# Script de backup
cat > /opt/fabric/scripts/backup-ledger.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/data/fabric/backup/$(date +%Y%m%d-%H%M%S)"
S3_BUCKET="${BACKUP_BUCKET:-afor-blockchain-backups}"
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)

mkdir -p "$BACKUP_DIR"

if [ -d "/data/fabric/ledger" ]; then
    tar czf "$BACKUP_DIR/orderer-ledger.tar.gz" -C /data/fabric ledger/
    aws s3 cp "$BACKUP_DIR/orderer-ledger.tar.gz" "s3://$S3_BUCKET/$INSTANCE_ID/ledger-$(date +%Y%m%d-%H%M%S).tar.gz"
    echo "Backup orderer ledger complété"
fi

find /data/fabric/backup -type d -mtime +7 -exec rm -rf {} +
EOF

chmod +x /opt/fabric/scripts/backup-ledger.sh
echo "0 2 * * * /opt/fabric/scripts/backup-ledger.sh >> /data/fabric/logs/backup.log 2>&1" | crontab -u ubuntu -

log "========================================="
log "Installation Orderer Node terminée avec succès!"
log "========================================="
log "Services installés:"
log "- Docker: $(docker --version)"
log "- Docker Compose: $(docker compose version)"
log "- Prometheus configuration créée"
log "- Grafana sera déployé via Docker Compose"
log ""
log "Prochaines étapes:"
log "1. Déployer les fichiers de configuration MSP"
log "2. Déployer le docker-compose.yml"
log "3. Lancer le réseau Fabric + Monitoring"
log "========================================="

echo "SETUP_COMPLETE" > /tmp/user-data-complete
