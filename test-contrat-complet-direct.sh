#!/bin/bash

# Couleurs
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  CRÉATION CONTRAT COMPLET - DIRECT BLOCKCHAIN (peer CLI) ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Vérifier que le fichier existe
if [ ! -f "test-data/contrat-complet.json" ]; then
    echo -e "${RED}❌ Fichier test-data/contrat-complet.json introuvable${NC}"
    exit 1
fi

# Charger le contrat
CONTRACT_DATA=$(cat test-data/contrat-complet.json | jq -c '.')
CONTRACT_CODE=$(cat test-data/contrat-complet.json | jq -r '.codeContract')

echo -e "${YELLOW}📄 Contrat à créer:${NC} ${CONTRACT_CODE}"
echo -e "${BLUE}   Type:${NC} $(cat test-data/contrat-complet.json | jq -r '.type')"
echo -e "${BLUE}   Propriétaire:${NC} $(cat test-data/contrat-complet.json | jq -r '.owner.name')"
echo -e "${BLUE}   Locataire:${NC} $(cat test-data/contrat-complet.json | jq -r '.beneficiary.name')"
echo -e "${BLUE}   Surface:${NC} $(cat test-data/contrat-complet.json | jq -r '.terrain.surface') hectares"
echo ""

echo -e "${YELLOW}🚀 Création sur la blockchain...${NC}"
docker exec cli peer chaincode invoke \
    -o orderer.foncier.ci:7050 \
    --tls \
    --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/ordererOrganizations/foncier.ci/orderers/orderer.foncier.ci/msp/tlscacerts/tlsca.foncier.ci-cert.pem \
    -C contrat-agraire \
    -n foncier \
    --peerAddresses peer0.afor.foncier.ci:7051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/afor.foncier.ci/peers/peer0.afor.foncier.ci/tls/ca.crt \
    --peerAddresses peer0.cvgfr.foncier.ci:8051 \
    --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/organizations/peerOrganizations/cvgfr.foncier.ci/peers/peer0.cvgfr.foncier.ci/tls/ca.crt \
    -c "{\"function\":\"creerContrat\",\"Args\":[\"$CONTRACT_DATA\"]}" 2>&1 | grep -v "INFO\|WARN"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Contrat créé avec succès !${NC}"
    echo ""
    
    # Attendre la propagation
    echo -e "${YELLOW}⏳ Attente de la propagation (3 secondes)...${NC}"
    sleep 3
    
    # Lire le contrat
    echo -e "${YELLOW}🔍 Lecture du contrat depuis la blockchain...${NC}"
    echo ""
    
    RESULT=$(docker exec cli peer chaincode query \
        -C contrat-agraire \
        -n foncier \
        -c "{\"function\":\"lireContrat\",\"Args\":[\"$CONTRACT_CODE\"]}" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Contrat récupéré !${NC}"
        echo ""
        echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}         DÉTAILS DU CONTRAT COMPLET CRÉÉ                   ${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
        echo ""
        
        # Affichage formaté
        echo "$RESULT" | jq -r '
"🏷️  CODE CONTRAT: \(.codeContract)
📅 CRÉATION: \(.creationDate)
📝 TYPE: \(.type) - Version \(.version)
📍 LIEU: \(.village), \(.sousPrefecture), \(.department), \(.region)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 PROPRIÉTAIRE COMPLET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Nom: \(.owner.name)
   Épouse: \(.owner.partnerName)
   Naissance: \(.owner.birthDate) à \(.owner.birthPlace)
   Parents: \(.owner.fatherName) et \(.owner.motherName)
   Identité: \(.owner.idType) N° \(.owner.idNumber) du \(.owner.idDate)
   Téléphone: \(.owner.phoneNumber)
   Adresse: \(.owner.address)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 LOCATAIRE/PRENEUR COMPLET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Nom: \(.beneficiary.name)
   Époux: \(.beneficiary.partnerName)
   Naissance: \(.beneficiary.birthDate) à \(.beneficiary.birthPlace)
   Parents: \(.beneficiary.fatherName) et \(.beneficiary.motherName)
   Identité: \(.beneficiary.idType) N° \(.beneficiary.idNumber) du \(.beneficiary.idDate)
   Téléphone: \(.beneficiary.phoneNumber)
   Adresse: \(.beneficiary.address)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏞️  TERRAIN COMPLET
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📍 Localisation: \(.terrain.localisation)
   📏 Surface: \(.terrain.surface) hectares
   📊 Mesure: \(.terrain.surfaceMeasurment)
   🛠️  Méthode: \(.terrain.surfaceMethod)
   
   📄 Documents:
      • CVGFR: \(.terrain.cvgfr)
      • Certificat Foncier: \(.terrain.certificatFoncier)
      • Type: \(.terrain.certificatFoncierType)
      • Titre Foncier: \(.terrain.titreFoncier)
      • IDUFCI: \(.terrain.idufci)
   
   ⚠️  Servitude: \(.terrain.natureServitude)
   🗺️  Croquis: \(.terrain.croquisDisponible)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💰 LOYER ET PAIEMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   💵 Espèce: \(.rent) FCFA / \(.rentTimeUnit)
      → \(.rentIsEspeceDetails)
   
   🌾 Nature: \(if .rentIsNature == 1 then "OUI" else "NON" end)
      → \(.rentIsNatureDetails)
   
   📅 Date paiement: \(.rentDate)
   🔄 Révision: \(.rentRevision)
   👤 Payé par: \(.rentPayedBy)
   ⏰ Période: \(.rentPeriod) mois

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏱️  DURÉE ET DÉLAIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ⏳ Durée totale: \(.duration) \(.durationUnit)
   🆕 Nouveau contrat: \(if .isNewContract == 1 then "OUI" else "NON - Renouvellement" end)
   📜 Ancien contrat: \(.oldContractDate // "N/A")
   🏗️  Délai travaux: \(.delaiTravaux) \(.delaiTravauxUnit)
   ⏰ Délai partage: \(.partageDelay) mois

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 OBLIGATIONS DÉTAILLÉES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🌾 Cultures vivrières:
      \(.hasObligationVivriereDetails)
   
   🌳 Cultures pérennes:
      \(.hasObligationPerenneDetails)
   
   🔧 Autres activités:
      \(.hasObligationAutreActiviteDetails)
   
   📜 Obligations propriétaire:
      \(.ownerObligations)
   
   📜 Obligations locataire:
      \(.beneficiaryObligations)
   
   🔐 Détenteur droit foncier: \(if .isOwnerDetenteurDroitFoncier == 1 then "OUI" else "NON" end)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌾 PARTAGE RÉCOLTE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Type: \(.recoltePaiementType)
   Pourcentage: \(.recoltePaiementPercent)%
   Mode: \(.recoltePaiement)
   Détails: \(.recoltePaiementDetails)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌳 PLANTER-PARTAGER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Part propriétaire initial: \(.planterPartagerOwnerPercent)%
   Part exploitant initial: \(.planterPartagerBeneficiaryPercent)%
   Part propriétaire après partage: \(.planterPartagerPartageOwnerPercent)%
   
   Détails:
   \(.planterPartagerPartageOtherDetails)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💵 CONTREPARTIES ET PRIMES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Prime totale: \(.prime) FCFA
   Prime annuelle: \(.contrepartiePrimeAnnuelle) FCFA
   Type: \(.contrepartiePrime)
   
   Détails:
   \(.contrepartiePrimeAnnuelleDetails)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✍️  SIGNATAIRES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Propriétaire: \(.contractSignatory[0].ownerName)
      Signature: \(.contractSignatory[0].ownerSignature)
      Témoin: \(.contractSignatory[0].ownerWitnessName)
      Signature témoin: \(.contractSignatory[0].ownerWitnessSignature)
   
   Locataire: \(.contractSignatory[0].beneficiaryName)
      Signature: \(.contractSignatory[0].beneficiarySignature)
      Témoin: \(.contractSignatory[0].beneficiaryWitnessName)
      Signature témoin: \(.contractSignatory[0].beneficiaryWitnessSignature)
   
   Président CVGFR: \(.contractSignatory[0].cvgfrPresidentName)
      Signature: \(.contractSignatory[0].cvgfrPresidentSignature)
   
   📅 Date signature: \(.contractSignatory[0].creationDate)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 AUTORISATIONS ET ACTIVITÉS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Activités associées: \(if .hasActiviteAssocie == 1 then "✅ OUI" else "❌ NON" end)
   Légumes: \(if .hasActiviteAssocieLegume == 1 then "✅ OUI" else "❌ NON" end)
   Vivrières: \(if .hasActiviteAssocieVivriere == 1 then "✅ OUI" else "❌ NON" end)
   
   Autorisation familiale: \(if .hasFamilyAuthorization == 1 then "✅ OUI" else "❌ NON" end)
   Pour livraison: \(if .hasFamilyAuthorizationLivraison == 1 then "✅ OUI" else "❌ NON" end)
   Pour vente: \(if .hasFamilyAuthorizationVente == 1 then "✅ OUI" else "❌ NON" end)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 USAGES AUTORISÉS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
\(.usagesAutorises)
"
        '
        
        echo ""
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}  ✅ CONTRAT COMPLET CRÉÉ ET VÉRIFIÉ AVEC SUCCÈS !        ${NC}"
        echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
        
    else
        echo -e "${RED}❌ Erreur lors de la lecture${NC}"
    fi
else
    echo -e "${RED}❌ Erreur lors de la création${NC}"
fi

echo ""
