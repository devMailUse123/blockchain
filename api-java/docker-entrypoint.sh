#!/bin/bash
set -e

# Script de démarrage pour l'API Foncier Java
echo "=== Démarrage de l'API Foncier Java ==="
echo "Version: 1.0.0"
echo "Profil Spring: ${SPRING_PROFILES_ACTIVE:-default}"
echo "Java Version: $(java -version 2>&1 | head -n 1)"

# Attendre que les services Fabric soient disponibles
echo "Attente des services Hyperledger Fabric..."
sleep 10

# Vérification des variables d'environnement essentielles
if [ -z "$FABRIC_CONFIG_PATH" ]; then
    export FABRIC_CONFIG_PATH="/app/network/connection-profile.yaml"
fi

if [ -z "$FABRIC_WALLET_PATH" ]; then
    export FABRIC_WALLET_PATH="/app/network/wallet"
fi

if [ -z "$FABRIC_CHANNEL" ]; then
    export FABRIC_CHANNEL="AFOR_CONTRAT_AGRAIRE"
fi

if [ -z "$FABRIC_CHAINCODE" ]; then
    export FABRIC_CHAINCODE="foncier-chaincode"
fi

echo "Configuration Fabric:"
echo "  - Config Path: $FABRIC_CONFIG_PATH"
echo "  - Wallet Path: $FABRIC_WALLET_PATH"
echo "  - Channel: $FABRIC_CHANNEL"
echo "  - Chaincode: $FABRIC_CHAINCODE"
echo "  - MSP ID: $FABRIC_MSP_ID"

# Créer les répertoires nécessaires
mkdir -p /app/logs
mkdir -p /app/network

# Démarrage de l'application Java
echo "Démarrage de l'application Spring Boot..."
exec "$@"