package ci.foncier.chaincode;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import gn.foncier.model.*;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.*;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ChaincodeStub;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * Chaincode Java pour la gestion des contrats fonciers ruraux en Côte d'Ivoire
 * Compatible avec Hyperledger Fabric 3.1.1 et les canaux spécialisés
 */
@Contract(
    name = "FoncierChaincode",
    info = @Info(
        title = "Contrats Fonciers Chaincode",
        description = "Chaincode pour la gestion des contrats fonciers et certificats en Côte d'Ivoire",
        version = "1.0.0"
    )
)
@Default
public class FoncierChaincode implements ContractInterface {

    private static final Logger logger = LoggerFactory.getLogger(FoncierChaincode.class);
    private final ObjectMapper objectMapper;

    // Types de contrats supportés
    public enum TypeContrat {
        CONTRAT_AGRAIRE, CERTIFICAT_FONCIER, LOCATION, VENTE, CONCESSION
    }

    // Statuts des contrats
    public enum StatutContrat {
        BROUILLON, ACTIF, SUSPENDU, ARCHIVE, VALIDE, EN_ATTENTE_VALIDATION
    }

    // Organisations autorisées
    public enum Organisation {
        AFOR, CVGFR, PREFET
    }

    public FoncierChaincode() {
        this.objectMapper = new ObjectMapper();
        this.objectMapper.registerModule(new JavaTimeModule());
        this.objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    /**
     * Initialise le ledger avec des données de test si nécessaire
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void initLedger(final Context context) {
        logger.info("Initialisation du chaincode Contrats Fonciers - Version 1.0.0");
        
        // Ajouter des métadonnées du chaincode
        try {
            Map<String, Object> metadata = new HashMap<>();
            metadata.put("version", "1.0.0");
            metadata.put("initialized", getCurrentTimestamp());
            metadata.put("supportedChannels", Arrays.asList("AFOR_CONTRAT_AGRAIRE", "AFOR_CERTIFICATE", "ADMIN"));
            metadata.put("organizations", Arrays.asList("AFOR", "CVGFR", "PREFET"));
            
            context.getStub().putStringState("CHAINCODE_METADATA", objectMapper.writeValueAsString(metadata));
            logger.info("Chaincode initialisé avec succès");
        } catch (Exception e) {
            logger.error("Erreur lors de l'initialisation: {}", e.getMessage());
            throw new ChaincodeException("Erreur d'initialisation: " + e.getMessage(), "INIT_ERROR");
        }
    }

    /**
     * Crée un nouveau contrat foncier
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratFoncier creerContrat(final Context context, final String contratJson) {
        logger.info("Création d'un nouveau contrat");
        
        try {
            ContratFoncier contrat = objectMapper.readValue(contratJson, ContratFoncier.class);
            
            // Validation du contrat
            validerContrat(contrat);
            
            // Vérifier que le contrat n'existe pas déjà
            if (contratExiste(context, contrat.getId())) {
                throw new ChaincodeException("Le contrat avec l'ID " + contrat.getId() + " existe déjà", "CONTRAT_EXISTS");
            }
            
            // Initialiser les métadonnées
            String timestamp = getCurrentTimestamp();
            if (contrat.getMetadonnees() == null) {
                contrat.setMetadonnees(new Metadonnees());
            }
            
            contrat.getMetadonnees().setDateCreation(timestamp);
            contrat.getMetadonnees().setDerniereMaj(timestamp);
            contrat.getMetadonnees().setVersion(1);
            contrat.setDateCreation(timestamp);
            contrat.setStatut(StatutContrat.BROUILLON.name());
            
            // Générer code contrat si absent
            if (contrat.getCodeContrat() == null || contrat.getCodeContrat().trim().isEmpty()) {
                contrat.setCodeContrat(genererCodeContrat(contrat));
            }
            
            // Ajouter événement de création
            Evenement creation = new Evenement("CREATION", "Création du contrat", 
                                             getCallerInfo(context), 
                                             getCallerOrganization(context));
            creation.setDate(timestamp);
            creation.setStatutApres(StatutContrat.BROUILLON.name());
            creation.setTransactionId(context.getStub().getTxId());
            contrat.ajouterEvenement(creation);
            
            // Sauvegarder
            sauvegarderContrat(context, contrat);
            
            // Émettre événement blockchain
            emettrEvenement(context, "ContratCree", contrat.getId(), Map.of(
                "type", contrat.getType(),
                "region", contrat.getRegion(),
                "organisation", getCallerOrganization(context)
            ));
            
            logger.info("Contrat créé avec succès: {}", contrat.getId());
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la création du contrat: {}", e.getMessage());
            throw new ChaincodeException("Erreur de création: " + e.getMessage(), "CREATE_ERROR");
        }
    }

    /**
     * Lit un contrat par son ID
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public ContratFoncier lireContrat(final Context context, final String contratId) {
        logger.info("Lecture du contrat: {}", contratId);
        
        try {
            String contratJson = context.getStub().getStringState(contratId);
            if (contratJson == null || contratJson.trim().isEmpty()) {
                throw new ChaincodeException("Contrat non trouvé: " + contratId, "CONTRAT_NOT_FOUND");
            }
            
            return objectMapper.readValue(contratJson, ContratFoncier.class);
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la lecture du contrat {}: {}", contratId, e.getMessage());
            throw new ChaincodeException("Erreur de lecture: " + e.getMessage(), "READ_ERROR");
        }
    }

    /**
     * Modifie un contrat existant
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratFoncier modifierContrat(final Context context, final String contratId, final String contratJson) {
        logger.info("Modification du contrat: {}", contratId);
        
        try {
            // Vérifier l'existence
            ContratFoncier contratExistant = lireContrat(context, contratId);
            
            // Parser les nouvelles données
            ContratFoncier contratModifie = objectMapper.readValue(contratJson, ContratFoncier.class);
            contratModifie.setId(contratId);
            
            // Validation
            validerContrat(contratModifie);
            
            // Préserver certaines données
            contratModifie.setDateCreation(contratExistant.getDateCreation());
            contratModifie.setHistorique(contratExistant.getHistorique());
            
            if (contratModifie.getMetadonnees() == null) {
                contratModifie.setMetadonnees(contratExistant.getMetadonnees());
            } else {
                contratModifie.getMetadonnees().setDateCreation(contratExistant.getMetadonnees().getDateCreation());
                contratModifie.getMetadonnees().setVersion(contratExistant.getMetadonnees().getVersion() + 1);
            }
            
            String timestamp = getCurrentTimestamp();
            contratModifie.getMetadonnees().setDerniereMaj(timestamp);
            
            // Ajouter événement de modification
            Evenement modification = new Evenement("MODIFICATION", "Modification du contrat",
                                                 getCallerInfo(context),
                                                 getCallerOrganization(context));
            modification.setDate(timestamp);
            modification.setStatutAvant(contratExistant.getStatut());
            modification.setStatutApres(contratModifie.getStatut());
            modification.setTransactionId(context.getStub().getTxId());
            contratModifie.ajouterEvenement(modification);
            
            // Sauvegarder
            sauvegarderContrat(context, contratModifie);
            
            // Émettre événement
            emettrEvenement(context, "ContratModifie", contratId, Map.of(
                "version", contratModifie.getMetadonnees().getVersion(),
                "organisation", getCallerOrganization(context)
            ));
            
            logger.info("Contrat modifié avec succès: {}", contratId);
            return contratModifie;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la modification du contrat {}: {}", contratId, e.getMessage());
            throw new ChaincodeException("Erreur de modification: " + e.getMessage(), "UPDATE_ERROR");
        }
    }

    /**
     * Archive un contrat (soft delete)
     */
    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void archiverContrat(final Context context, final String contratId) {
        logger.info("Archivage du contrat: {}", contratId);
        
        try {
            ContratFoncier contrat = lireContrat(context, contratId);
            
            String ancienStatut = contrat.getStatut();
            contrat.setStatut(StatutContrat.ARCHIVE.name());
            
            String timestamp = getCurrentTimestamp();
            contrat.getMetadonnees().setDerniereMaj(timestamp);
            contrat.getMetadonnees().incrementerVersion();
            
            // Ajouter événement
            Evenement archivage = new Evenement("ARCHIVAGE", "Archivage du contrat",
                                               getCallerInfo(context),
                                               getCallerOrganization(context));
            archivage.setDate(timestamp);
            archivage.setStatutAvant(ancienStatut);
            archivage.setStatutApres(StatutContrat.ARCHIVE.name());
            archivage.setTransactionId(context.getStub().getTxId());
            contrat.ajouterEvenement(archivage);
            
            // Sauvegarder
            sauvegarderContrat(context, contrat);
            
            // Émettre événement
            emettrEvenement(context, "ContratArchive", contratId, Map.of(
                "organisation", getCallerOrganization(context)
            ));
            
            logger.info("Contrat archivé avec succès: {}", contratId);
            
        } catch (Exception e) {
            logger.error("Erreur lors de l'archivage du contrat {}: {}", contratId, e.getMessage());
            throw new ChaincodeException("Erreur d'archivage: " + e.getMessage(), "ARCHIVE_ERROR");
        }
    }

    /**
     * Recherche des contrats par propriétaire
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public List<ContratFoncier> rechercherParProprietaire(final Context context, final String nomProprietaire) {
        logger.info("Recherche de contrats pour le propriétaire: {}", nomProprietaire);
        
        String queryString = String.format(
            "{\"selector\":{\"proprietaire.nom\":\"%s\",\"statut\":{\"$ne\":\"%s\"}}}",
            nomProprietaire, StatutContrat.ARCHIVE.name()
        );
        
        return executerRequete(context, queryString);
    }

    /**
     * Recherche des contrats par région
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public List<ContratFoncier> rechercherParRegion(final Context context, final String region) {
        logger.info("Recherche de contrats pour la région: {}", region);
        
        String queryString = String.format(
            "{\"selector\":{\"region\":\"%s\",\"statut\":{\"$ne\":\"%s\"}}}",
            region, StatutContrat.ARCHIVE.name()
        );
        
        return executerRequete(context, queryString);
    }

    /**
     * Recherche des contrats par type
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public List<ContratFoncier> rechercherParType(final Context context, final String type) {
        logger.info("Recherche de contrats de type: {}", type);
        
        String queryString = String.format(
            "{\"selector\":{\"$or\":[{\"type\":\"%s\"},{\"typeDocument\":\"%s\"}],\"statut\":{\"$ne\":\"%s\"}}}",
            type, type, StatutContrat.ARCHIVE.name()
        );
        
        return executerRequete(context, queryString);
    }

    /**
     * Liste tous les contrats actifs
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public List<ContratFoncier> listerContrats(final Context context) {
        logger.info("Liste de tous les contrats actifs");
        
        String queryString = String.format(
            "{\"selector\":{\"statut\":{\"$ne\":\"%s\"}}}",
            StatutContrat.ARCHIVE.name()
        );
        
        return executerRequete(context, queryString);
    }

    /**
     * Obtient l'historique complet d'un contrat
     */
    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public List<Map<String, Object>> obtenirHistorique(final Context context, final String contratId) {
        logger.info("Récupération de l'historique du contrat: {}", contratId);
        
        try {
            QueryResultsIterator<org.hyperledger.fabric.shim.ledger.KeyModification> historyIterator = 
                context.getStub().getHistoryForKey(contratId);
            
            List<Map<String, Object>> historique = new ArrayList<>();
            
            for (org.hyperledger.fabric.shim.ledger.KeyModification modification : historyIterator) {
                Map<String, Object> entry = new HashMap<>();
                entry.put("txId", modification.getTxId());
                entry.put("timestamp", modification.getTimestamp().toString());
                entry.put("isDelete", modification.isDeleted());
                
                if (!modification.isDeleted() && modification.getValue() != null) {
                    try {
                        ContratFoncier contrat = objectMapper.readValue(modification.getValue(), ContratFoncier.class);
                        entry.put("contrat", contrat);
                    } catch (Exception e) {
                        logger.warn("Erreur de parsing pour l'entrée historique: {}", e.getMessage());
                    }
                }
                
                historique.add(entry);
            }
            
            return historique;
            
        } catch (Exception e) {
            logger.error("Erreur lors de la récupération de l'historique pour {}: {}", contratId, e.getMessage());
            throw new ChaincodeException("Erreur de récupération d'historique: " + e.getMessage(), "HISTORY_ERROR");
        }
    }

    // Méthodes utilitaires privées

    private boolean contratExiste(Context context, String contratId) {
        try {
            String state = context.getStub().getStringState(contratId);
            return state != null && !state.trim().isEmpty();
        } catch (Exception e) {
            return false;
        }
    }

    private void validerContrat(ContratFoncier contrat) {
        if (contrat.getId() == null || contrat.getId().trim().isEmpty()) {
            throw new ChaincodeException("ID du contrat obligatoire", "VALIDATION_ERROR");
        }
        if (contrat.getType() == null || contrat.getType().trim().isEmpty()) {
            throw new ChaincodeException("Type de contrat obligatoire", "VALIDATION_ERROR");
        }
        if (contrat.getRegion() == null || contrat.getRegion().trim().isEmpty()) {
            throw new ChaincodeException("Région obligatoire", "VALIDATION_ERROR");
        }
        if (contrat.getProprietaire() == null) {
            throw new ChaincodeException("Propriétaire obligatoire", "VALIDATION_ERROR");
        }
        if (contrat.getTerrain() == null) {
            throw new ChaincodeException("Informations du terrain obligatoires", "VALIDATION_ERROR");
        }
    }

    private void sauvegarderContrat(Context context, ContratFoncier contrat) throws Exception {
        String contratJson = objectMapper.writeValueAsString(contrat);
        context.getStub().putStringState(contrat.getId(), contratJson);
    }

    private List<ContratFoncier> executerRequete(Context context, String queryString) {
        try {
            QueryResultsIterator<KeyValue> resultIterator = context.getStub().getQueryResult(queryString);
            List<ContratFoncier> contrats = new ArrayList<>();
            
            for (KeyValue result : resultIterator) {
                try {
                    ContratFoncier contrat = objectMapper.readValue(result.getStringValue(), ContratFoncier.class);
                    contrats.add(contrat);
                } catch (Exception e) {
                    logger.warn("Erreur de parsing pour le contrat {}: {}", result.getKey(), e.getMessage());
                }
            }
            
            return contrats;
        } catch (Exception e) {
            logger.error("Erreur lors de l'exécution de la requête: {}", e.getMessage());
            throw new ChaincodeException("Erreur de requête: " + e.getMessage(), "QUERY_ERROR");
        }
    }

    private String genererCodeContrat(ContratFoncier contrat) {
        String prefixe = contrat.estContratAgraire() ? "CA" : 
                        contrat.estCertificatFoncier() ? "CF" : "CT";
        String regionCode = contrat.getRegion().substring(0, Math.min(3, contrat.getRegion().length())).toUpperCase();
        String sequence = String.valueOf(System.currentTimeMillis() % 100000);
        return String.format("%s-%s-%s", prefixe, regionCode, sequence);
    }

    private String getCurrentTimestamp() {
        return Instant.now().atOffset(ZoneOffset.UTC).format(DateTimeFormatter.ISO_INSTANT);
    }

    private String getCallerInfo(Context context) {
        return context.getClientIdentity().getId();
    }

    private String getCallerOrganization(Context context) {
        try {
            return context.getClientIdentity().getMSPID().replace("Org", "").toUpperCase();
        } catch (Exception e) {
            return "UNKNOWN";
        }
    }

    private void emettrEvenement(Context context, String eventName, String contratId, Map<String, Object> payload) {
        try {
            Map<String, Object> eventData = new HashMap<>(payload);
            eventData.put("contratId", contratId);
            eventData.put("timestamp", getCurrentTimestamp());
            
            String eventJson = objectMapper.writeValueAsString(eventData);
            context.getStub().setEvent(eventName, eventJson.getBytes());
        } catch (Exception e) {
            logger.warn("Erreur lors de l'émission de l'événement {}: {}", eventName, e.getMessage());
        }
    }
}