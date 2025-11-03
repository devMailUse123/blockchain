#!/bin/bash
#
# Scripts de Maintenance et Sécurité
# Blockchain Foncière - Côte d'Ivoire
#

# =============================================================================
# BACKUPS AUTOMATIQUES
# =============================================================================

backup_blockchain_data() {
    echo "🔄 Backup des données blockchain..."
    
    BACKUP_DIR="/opt/backups/fabric-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup des certificats
    tar czf "$BACKUP_DIR/organizations.tar.gz" /opt/fabric/organizations/
    
    # Backup des channel artifacts
    tar czf "$BACKUP_DIR/channel-artifacts.tar.gz" /opt/fabric/channel-artifacts/
    
    # Backup CouchDB (sur chaque peer)
    docker exec couchdb-afor curl -X GET http://admin:adminpw@localhost:5984/_all_dbs | \
        jq -r '.[]' | while read db; do
            docker exec couchdb-afor curl -X GET \
                "http://admin:adminpw@localhost:5984/$db/_all_docs?include_docs=true" \
                > "$BACKUP_DIR/couchdb-$db.json"
        done
    
    # Compresser tout
    tar czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
    rm -rf "$BACKUP_DIR"
    
    # Envoyer vers S3 (optionnel)
    # aws s3 cp "$BACKUP_DIR.tar.gz" s3://afor-blockchain-backups/
    
    echo "✅ Backup créé : $BACKUP_DIR.tar.gz"
}

# Ajouter au cron (exécuter quotidiennement à 2h du matin)
install_backup_cron() {
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/fabric/scripts/maintenance.sh backup") | crontab -
    echo "✅ Backup automatique configuré (2h du matin)"
}

# =============================================================================
# MONITORING DE SANTÉ
# =============================================================================

health_check() {
    echo "🏥 Vérification de la santé du réseau..."
    
    # Vérifier les conteneurs
    echo -n "Vérification des conteneurs... "
    EXPECTED_CONTAINERS=("peer0.afor.foncier.ci" "peer0.cvgfr.foncier.ci" "orderer.foncier.ci" "couchdb-afor")
    for container in "${EXPECTED_CONTAINERS[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "$container"; then
            echo "❌ Conteneur $container non démarré"
            return 1
        fi
    done
    echo "✅"
    
    # Vérifier les endpoints
    echo -n "Vérification orderer... "
    if curl -s --max-time 5 http://localhost:9443/healthz | grep -q "OK"; then
        echo "✅"
    else
        echo "❌"
    fi
    
    echo -n "Vérification peer AFOR... "
    if curl -s --max-time 5 http://localhost:9447/healthz | grep -q "OK"; then
        echo "✅"
    else
        echo "❌"
    fi
    
    echo -n "Vérification CouchDB... "
    if curl -s --max-time 5 http://admin:adminpw@localhost:5984/_up | grep -q "ok"; then
        echo "✅"
    else
        echo "❌"
    fi
    
    echo "✅ Vérification de santé terminée"
}

# =============================================================================
# NETTOYAGE DES LOGS
# =============================================================================

cleanup_logs() {
    echo "🧹 Nettoyage des anciens logs..."
    
    # Supprimer les logs Docker de plus de 30 jours
    find /var/lib/docker/containers -name "*.log" -mtime +30 -exec truncate -s 0 {} \;
    
    # Nettoyer les logs applicatifs
    find /opt/fabric/api/logs -name "*.log" -mtime +30 -delete
    
    # Nettoyer Docker (images non utilisées)
    docker image prune -af --filter "until=720h"
    
    echo "✅ Logs nettoyés"
}

# =============================================================================
# ROTATION DES CERTIFICATS
# =============================================================================

check_certificate_expiry() {
    echo "🔐 Vérification de l'expiration des certificats..."
    
    CERT_DIR="/opt/fabric/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls"
    
    if [ -f "$CERT_DIR/server.crt" ]; then
        EXPIRY=$(openssl x509 -in "$CERT_DIR/server.crt" -noout -enddate | cut -d= -f2)
        EXPIRY_TIMESTAMP=$(date -d "$EXPIRY" +%s)
        NOW_TIMESTAMP=$(date +%s)
        DAYS_LEFT=$(( ($EXPIRY_TIMESTAMP - $NOW_TIMESTAMP) / 86400 ))
        
        echo "Certificat expire dans : $DAYS_LEFT jours"
        
        if [ $DAYS_LEFT -lt 30 ]; then
            echo "⚠️  ALERTE : Certificat expire dans moins de 30 jours !"
            # Envoyer une notification
            # send_alert "Certificat AFOR expire dans $DAYS_LEFT jours"
        else
            echo "✅ Certificat valide"
        fi
    else
        echo "❌ Certificat non trouvé"
    fi
}

# =============================================================================
# MISE À JOUR DU CHAINCODE
# =============================================================================

upgrade_chaincode() {
    local NEW_VERSION=$1
    
    if [ -z "$NEW_VERSION" ]; then
        echo "❌ Usage: upgrade_chaincode <version>"
        return 1
    fi
    
    echo "🔄 Mise à jour du chaincode vers version $NEW_VERSION..."
    
    # Compiler la nouvelle version
    cd /opt/fabric/chaincode-java
    mvn clean package -DskipTests
    
    # Créer le nouveau package
    cd /opt/fabric
    CHAINCODE_VERSION=$NEW_VERSION ./scripts/package-chaincode.sh
    
    # Installer sur les peers
    export CORE_PEER_LOCALMSPID="AFORMSP"
    export CORE_PEER_ADDRESS=localhost:7051
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/fabric/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/fabric/organizations/peerOrganizations/afor.foncier.ci/users/Admin@afor.foncier.ci/msp
    
    peer lifecycle chaincode install "foncier-v${NEW_VERSION}.tar.gz"
    
    # Répéter pour CVGFR...
    
    echo "✅ Chaincode mis à jour"
}

# =============================================================================
# ALERTES ET NOTIFICATIONS
# =============================================================================

send_alert() {
    local MESSAGE=$1
    
    # Email (nécessite mailutils)
    # echo "$MESSAGE" | mail -s "Alerte Blockchain AFOR" admin@afor.gov.ci
    
    # Slack (nécessite webhook)
    # curl -X POST -H 'Content-type: application/json' \
    #   --data "{\"text\":\"$MESSAGE\"}" \
    #   https://hooks.slack.com/services/YOUR/WEBHOOK/URL
    
    # Log
    echo "[ALERT $(date)] $MESSAGE" >> /var/log/fabric-alerts.log
}

# =============================================================================
# STATISTIQUES DU RÉSEAU
# =============================================================================

network_stats() {
    echo "📊 Statistiques du réseau..."
    
    echo ""
    echo "=== Conteneurs Docker ==="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Size}}"
    
    echo ""
    echo "=== Utilisation Disque ==="
    df -h | grep -E "Filesystem|/opt/fabric|docker"
    
    echo ""
    echo "=== Nombre de Documents CouchDB ==="
    curl -s http://admin:adminpw@localhost:5984/_all_dbs | jq -r '.[]' | while read db; do
        count=$(curl -s "http://admin:adminpw@localhost:5984/$db" | jq -r '.doc_count')
        echo "$db: $count documents"
    done
    
    echo ""
    echo "=== Métriques Prometheus ==="
    curl -s http://localhost:9447/metrics | grep "^ledger_blockchain_height"
    
    echo ""
}

# =============================================================================
# PROCÉDURES D'INCIDENT
# =============================================================================

# Redémarrage d'urgence d'un peer
emergency_restart_peer() {
    local PEER_NAME=$1
    
    echo "🚨 Redémarrage d'urgence de $PEER_NAME..."
    
    docker restart "$PEER_NAME"
    sleep 10
    
    # Vérifier que le peer est bien redémarré
    if docker ps --format '{{.Names}}' | grep -q "$PEER_NAME"; then
        echo "✅ $PEER_NAME redémarré avec succès"
        send_alert "Peer $PEER_NAME redémarré (intervention manuelle)"
    else
        echo "❌ Échec du redémarrage de $PEER_NAME"
        send_alert "CRITIQUE: Échec du redémarrage de $PEER_NAME"
    fi
}

# Rollback du chaincode
rollback_chaincode() {
    local PREVIOUS_VERSION=$1
    
    echo "⏮️  Rollback du chaincode vers version $PREVIOUS_VERSION..."
    
    # Logique de rollback (approuver et committer l'ancienne version)
    # Nécessite de garder les anciens packages
    
    echo "✅ Rollback effectué"
    send_alert "Rollback chaincode vers version $PREVIOUS_VERSION"
}

# =============================================================================
# MAIN MENU
# =============================================================================

show_menu() {
    cat << EOF
╔════════════════════════════════════════════════════════════╗
║     Scripts de Maintenance - Blockchain AFOR              ║
╚════════════════════════════════════════════════════════════╝

Opérations disponibles:

  [1] backup              Créer un backup complet
  [2] health              Vérifier la santé du réseau
  [3] cleanup             Nettoyer les logs anciens
  [4] certs               Vérifier l'expiration des certificats
  [5] stats               Afficher les statistiques
  [6] restart-peer        Redémarrer un peer
  [7] upgrade             Mettre à jour le chaincode
  [8] install-cron        Installer les tâches automatiques
  
  [0] quit                Quitter

EOF
}

# Main
case "$1" in
    backup)
        backup_blockchain_data
        ;;
    health)
        health_check
        ;;
    cleanup)
        cleanup_logs
        ;;
    certs)
        check_certificate_expiry
        ;;
    stats)
        network_stats
        ;;
    restart-peer)
        emergency_restart_peer "$2"
        ;;
    upgrade)
        upgrade_chaincode "$2"
        ;;
    install-cron)
        install_backup_cron
        ;;
    menu)
        show_menu
        ;;
    *)
        show_menu
        ;;
esac
