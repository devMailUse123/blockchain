#!/bin/bash

# Script de packaging du chaincode Java
# Crée un package au format Fabric 3.x avec le JAR compilé

set -e

# Configuration
CC_VERSION="${CHAINCODE_VERSION:-2.0}"  # Utilise la variable d'environnement ou 2.0 par défaut
CC_NAME="foncier"
CHAINCODE_DIR="chaincode-java"
JAR_FILE="${CHAINCODE_DIR}/target/foncier-chaincode-1.0.0.jar"
PACKAGE_FILE="foncier-v${CC_VERSION}.tar.gz"

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  PACKAGE CHAINCODE ${CC_NAME} v${CC_VERSION}${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════${NC}\n"

# Vérifier que le JAR existe
if [ ! -f "${JAR_FILE}" ]; then
    echo -e "${RED}❌ Erreur: JAR non trouvé: ${JAR_FILE}${NC}"
    echo -e "${YELLOW}   Exécutez 'make build' d'abord${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} JAR trouvé: $(ls -lh ${JAR_FILE} | awk '{print $5}')"

# Nettoyer les fichiers temporaires
rm -rf tmp-code code.tar.gz ${PACKAGE_FILE}

# Créer la structure du package
echo -e "${YELLOW}📦 Création de la structure du package...${NC}"
mkdir -p tmp-code/src

# Copier le JAR
cp "${JAR_FILE}" tmp-code/src/chaincode.jar
echo -e "${GREEN}✓${NC} JAR copié vers tmp-code/src/chaincode.jar"

# Créer code.tar.gz
cd tmp-code
tar czf ../code.tar.gz .
cd ..
echo -e "${GREEN}✓${NC} code.tar.gz créé: $(ls -lh code.tar.gz | awk '{print $5}')"

# Créer metadata.json
cat > metadata.json << EOF
{"path":"","type":"java","label":"${CC_NAME}_${CC_VERSION}"}
EOF
echo -e "${GREEN}✓${NC} metadata.json créé"

# Créer le package final
tar czf ${PACKAGE_FILE} metadata.json code.tar.gz
echo -e "${GREEN}✓${NC} Package final créé: $(ls -lh ${PACKAGE_FILE} | awk '{print $5}')"

# Nettoyer les fichiers temporaires
rm -rf tmp-code code.tar.gz metadata.json

# Afficher le contenu
echo -e "\n${YELLOW}📋 Contenu du package:${NC}"
tar tzf ${PACKAGE_FILE}

echo -e "\n${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Package créé avec succès: ${PACKAGE_FILE}${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
