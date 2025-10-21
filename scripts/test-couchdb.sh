#!/bin/bash

# Script de test - Vérification CouchDB
set -e

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${YELLOW}════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  VÉRIFICATION COUCHDB                          ${NC}"
echo -e "${YELLOW}════════════════════════════════════════════════${NC}\n"

# Configuration CouchDB
AFOR_COUCHDB="http://localhost:5984"
CVGFR_COUCHDB="http://localhost:6984"
CHANNEL_NAME="contrat-agraire"
CC_NAME="foncier"

# Fonction pour vérifier une instance CouchDB
check_couchdb() {
    local NAME=$1
    local URL=$2
    
    echo -e "${BLUE}🔍 Vérification CouchDB ${NAME}...${NC}"
    
    # Vérifier la connexion
    if curl -s ${URL} > /dev/null 2>&1; then
        echo -e "${GREEN}✅ CouchDB ${NAME} accessible${NC}"
        VERSION=$(curl -s ${URL} | jq -r '.version' 2>/dev/null || echo "?")
        echo -e "   Version: ${VERSION}"
    else
        echo -e "${RED}❌ CouchDB ${NAME} non accessible${NC}"
        return 1
    fi
    
    # Lister les bases de données
    echo -e "\n${BLUE}📋 Bases de données:${NC}"
    DBS=$(curl -s ${URL}/_all_dbs | jq -r '.[]' 2>/dev/null)
    
    if [ -z "$DBS" ]; then
        echo -e "${YELLOW}   Aucune base de données${NC}"
    else
        echo "$DBS" | while read db; do
            # Compter les documents
            if [[ "$db" == ${CHANNEL_NAME}_${CC_NAME} ]]; then
                DOC_COUNT=$(curl -s ${URL}/${db} | jq -r '.doc_count' 2>/dev/null || echo "?")
                echo -e "   ${GREEN}▸${NC} ${db} (${DOC_COUNT} documents)"
                
                # Lister quelques documents
                echo -e "${BLUE}   📄 Documents:${NC}"
                DOCS=$(curl -s "${URL}/${db}/_all_docs?limit=10" | jq -r '.rows[].id' 2>/dev/null)
                if [ -n "$DOCS" ]; then
                    echo "$DOCS" | while read doc_id; do
                        if [[ ! "$doc_id" =~ ^_ ]]; then
                            echo -e "      • ${doc_id}"
                        fi
                    done
                fi
            else
                echo -e "   ▸ ${db}"
            fi
        done
    fi
    echo ""
}

# Fonction pour afficher un document
show_document() {
    local NAME=$1
    local URL=$2
    local DOC_ID=$3
    
    echo -e "${BLUE}📄 Document ${DOC_ID} dans CouchDB ${NAME}:${NC}"
    
    DB_NAME="${CHANNEL_NAME}_${CC_NAME}"
    DOC=$(curl -s "${URL}/${DB_NAME}/${DOC_ID}" 2>/dev/null)
    
    if echo "$DOC" | jq -e '.error' > /dev/null 2>&1; then
        echo -e "${RED}❌ Document non trouvé${NC}\n"
    else
        echo "$DOC" | jq '.' 2>/dev/null || echo "$DOC"
        echo ""
    fi
}

# Vérifier AFOR CouchDB
check_couchdb "AFOR" "${AFOR_COUCHDB}"

# Vérifier CVGFR CouchDB
check_couchdb "CVGFR" "${CVGFR_COUCHDB}"

# Si un contrat de test existe, l'afficher
if [ $# -gt 0 ]; then
    DOC_ID=$1
    echo -e "${YELLOW}═══ Affichage du document: ${DOC_ID} ═══${NC}\n"
    show_document "AFOR" "${AFOR_COUCHDB}" "${DOC_ID}"
    show_document "CVGFR" "${CVGFR_COUCHDB}" "${DOC_ID}"
fi

# Résumé
echo -e "${GREEN}════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Vérification CouchDB terminée${NC}"
echo -e "${GREEN}════════════════════════════════════════════════${NC}\n"

echo -e "${BLUE}💡 Accès Web:${NC}"
echo -e "   AFOR:  http://localhost:5984/_utils"
echo -e "   CVGFR: http://localhost:6984/_utils\n"

echo -e "${BLUE}💡 Pour afficher un document:${NC}"
echo -e "   bash scripts/test-couchdb.sh <CODE_CONTRAT>\n"
