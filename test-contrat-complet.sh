#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
KEYCLOAK_URL="https://auth.digifor2.afor-ci.app"
REALM="for-blockchain"
CLIENT_ID="afor-blockchain-api"
CLIENT_SECRET="SIYIU61c2d0FybVMiBUALc7oWjaNsFQq"
API_URL="http://localhost:3000"

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  CRÉATION DE CONTRAT COMPLET VIA API + KEYCLOAK         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérifier que le fichier JSON existe
if [ ! -f "test-data/contrat-complet.json" ]; then
    echo -e "${RED}❌ Fichier test-data/contrat-complet.json introuvable${NC}"
    exit 1
fi

echo -e "${YELLOW}📄 Chargement du contrat complet...${NC}"
CONTRACT_DATA=$(cat test-data/contrat-complet.json)
CONTRACT_CODE=$(echo $CONTRACT_DATA | jq -r '.codeContract')
echo -e "${GREEN}✅ Contrat: ${CONTRACT_CODE}${NC}"
echo -e "${BLUE}   Description: Location avec toutes les informations simulées${NC}"
echo ""

# Étape 1: Obtenir le token
echo -e "${YELLOW}[1/4]${NC} Obtention du token Keycloak..."
TOKEN_RESPONSE=$(curl -s -X POST \
  "${KEYCLOAK_URL}/realms/${REALM}/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}")

if echo $TOKEN_RESPONSE | grep -q "access_token"; then
    ACCESS_TOKEN=$(echo $TOKEN_RESPONSE | jq -r '.access_token')
    echo -e "${GREEN}✅ Token obtenu${NC}"
else
    echo -e "${RED}❌ Erreur: Service Account non activé dans Keycloak${NC}"
    echo ""
    echo -e "${YELLOW}📋 Action requise:${NC}"
    echo "1. Ouvrir: ${KEYCLOAK_URL}/admin"
    echo "2. Realm: ${REALM}"
    echo "3. Clients → ${CLIENT_ID}"
    echo "4. Settings → Service accounts roles → ON"
    echo "5. Save"
    echo ""
    echo "Voir: ACTIVATION-KEYCLOAK-REQUIRED.md"
    exit 1
fi
echo ""

# Étape 2: Créer le contrat
echo -e "${YELLOW}[2/4]${NC} Création du contrat complet..."
CREATE_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$CONTRACT_DATA" \
  ${API_URL}/api/contracts)

HTTP_CODE=$(echo "$CREATE_RESPONSE" | tail -n1)
BODY=$(echo "$CREATE_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✅ Contrat créé avec succès${NC}"
    echo ""
    echo -e "${BLUE}📊 Résumé du contrat:${NC}"
    echo $BODY | jq '{
      code: .codeContract,
      type: .type,
      proprietaire: .owner.name,
      locataire: .beneficiary.name,
      surface: .terrain.surface,
      loyer_espece: .rent,
      loyer_nature: .rentIsNatureDetails,
      duree: (.duration + " " + .durationUnit),
      obligations_vivriere: .hasObligationVivriereDetails,
      obligations_perenne: .hasObligationPerenneDetails
    }'
else
    echo -e "${RED}❌ Erreur lors de la création (code: $HTTP_CODE)${NC}"
    echo $BODY | jq '.'
    exit 1
fi
echo ""

# Étape 3: Lire le contrat
echo -e "${YELLOW}[3/4]${NC} Vérification du contrat créé..."
sleep 2
READ_RESPONSE=$(curl -s -H "Authorization: Bearer ${ACCESS_TOKEN}" ${API_URL}/api/contracts/${CONTRACT_CODE})

if echo $READ_RESPONSE | grep -q "$CONTRACT_CODE"; then
    echo -e "${GREEN}✅ Contrat récupéré de la blockchain${NC}"
    
    # Afficher les informations importantes
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}           DÉTAILS DU CONTRAT COMPLET                  ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    
    echo $READ_RESPONSE | jq -r '
      .data[0] | 
      "
🏷️  CODE: \(.codeContract)
📅 DATE CRÉATION: \(.creationDate)
📝 TYPE: \(.type) - Version \(.version)
📍 LOCALISATION: \(.village), \(.sousPrefecture), \(.department), \(.region)

👤 PROPRIÉTAIRE:
   Nom: \(.owner.name)
   Conjoint: \(.owner.partnerName)
   Né le: \(.owner.birthDate) à \(.owner.birthPlace)
   Père: \(.owner.fatherName)
   Mère: \(.owner.motherName)
   ID: \(.owner.idType) N° \(.owner.idNumber)
   Tél: \(.owner.phoneNumber)
   Adresse: \(.owner.address)

👤 LOCATAIRE:
   Nom: \(.beneficiary.name)
   Conjoint: \(.beneficiary.partnerName)
   Né le: \(.beneficiary.birthDate) à \(.beneficiary.birthPlace)
   Père: \(.beneficiary.fatherName)
   Mère: \(.beneficiary.motherName)
   ID: \(.beneficiary.idType) N° \(.beneficiary.idNumber)
   Tél: \(.beneficiary.phoneNumber)
   Adresse: \(.beneficiary.address)

🏞️  TERRAIN:
   Localisation: \(.terrain.localisation)
   Surface: \(.terrain.surface) hectares
   CVGFR: \(.terrain.cvgfr)
   Certificat Foncier: \(.terrain.certificatFoncier) (\(.terrain.certificatFoncierType))
   Titre Foncier: \(.terrain.titreFoncier)
   IDUFCI: \(.terrain.idufci)
   Méthode mesure: \(.terrain.surfaceMethod)
   Servitude: \(.terrain.natureServitude)

💰 LOYER:
   Espèce: \(.rent) FCFA/\(.rentTimeUnit)
   Nature: \(.rentIsNatureDetails)
   Date paiement: \(.rentDate)
   Révision: \(.rentRevision)
   Payé par: \(.rentPayedBy)

⏱️  DURÉE: \(.duration) \(.durationUnit)
   Nouveau contrat: \(if .isNewContract == 1 then "OUI" else "NON" end)
   Ancien contrat: \(.oldContractDate // "N/A")

📋 OBLIGATIONS:
   Cultures vivrières: \(.hasObligationVivriereDetails)
   Cultures pérennes: \(.hasObligationPerenneDetails)
   Autres activités: \(.hasObligationAutreActiviteDetails)
   
   Propriétaire: \(.ownerObligations)
   Locataire: \(.beneficiaryObligations)

🌾 RÉCOLTE:
   Type paiement: \(.recoltePaiementType)
   Pourcentage: \(.recoltePaiementPercent)%
   Détails: \(.recoltePaiementDetails)

🌳 PLANTER-PARTAGER:
   Part propriétaire: \(.planterPartagerOwnerPercent)%
   Part exploitant: \(.planterPartagerBeneficiaryPercent)%
   Après partage: \(.planterPartagerPartageOwnerPercent)%
   Détails: \(.planterPartagerPartageOtherDetails)

💵 CONTREPARTIE:
   Prime: \(.prime) FCFA
   Prime annuelle: \(.contrepartiePrimeAnnuelle) FCFA
   Détails: \(.contrepartiePrimeAnnuelleDetails)

⏳ DÉLAIS:
   Travaux: \(.delaiTravaux) \(.delaiTravauxUnit)
   Partage: \(.partageDelay) mois

✍️  SIGNATURES:
   Propriétaire: \(.contractSignatory[0].ownerName)
   Témoin propriétaire: \(.contractSignatory[0].ownerWitnessName)
   Locataire: \(.contractSignatory[0].beneficiaryName)
   Témoin locataire: \(.contractSignatory[0].beneficiaryWitnessName)
   Président CVGFR: \(.contractSignatory[0].cvgfrPresidentName)
   Date signature: \(.contractSignatory[0].creationDate)
"
    '
else
    echo -e "${YELLOW}⚠️  Contrat pas encore visible (propagation en cours)${NC}"
fi
echo ""

# Étape 4: Vérifier CouchDB
echo -e "${YELLOW}[4/4]${NC} Vérification dans CouchDB..."
COUCH_RESPONSE=$(curl -s -u admin:adminpw "http://localhost:5984/contrat-agraire/_all_docs?include_docs=true")

if echo $COUCH_RESPONSE | grep -q "$CONTRACT_CODE"; then
    echo -e "${GREEN}✅ Contrat trouvé dans CouchDB${NC}"
    
    # Compter les champs non-null
    FILLED_FIELDS=$(echo $READ_RESPONSE | jq '[.data[0] | to_entries[] | select(.value != null and .value != "" and .value != 0 and .value != [])] | length')
    TOTAL_FIELDS=$(echo $READ_RESPONSE | jq '[.data[0] | to_entries[]] | length')
    
    echo -e "${BLUE}📊 Statistiques:${NC}"
    echo "   Champs remplis: ${FILLED_FIELDS}/${TOTAL_FIELDS}"
    echo "   Taux de complétion: $(echo "scale=1; $FILLED_FIELDS * 100 / $TOTAL_FIELDS" | bc)%"
else
    echo -e "${YELLOW}⚠️  Pas encore dans CouchDB (propagation en cours)${NC}"
fi
echo ""

# Résumé final
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✅ CRÉATION RÉUSSIE !                       ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🎯 Prochaines actions possibles:${NC}"
echo ""
echo "  # Lire le contrat"
echo "  curl -H \"Authorization: Bearer \$TOKEN\" \\"
echo "    http://localhost:3000/api/contracts/${CONTRACT_CODE}"
echo ""
echo "  # Modifier le contrat"
echo "  curl -X PUT -H \"Authorization: Bearer \$TOKEN\" \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d @test-data/contrat-complet-modifie.json \\"
echo "    http://localhost:3000/api/contracts/${CONTRACT_CODE}"
echo ""
echo "  # Lister tous les contrats"
echo "  curl -H \"Authorization: Bearer \$TOKEN\" \\"
echo "    http://localhost:3000/api/contracts"
echo ""
echo -e "${YELLOW}📚 Documentation complète: docs/API.md${NC}"
echo ""
