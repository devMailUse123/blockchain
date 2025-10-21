package ci.foncier.chaincode;

import ci.foncier.chaincode.model.*;
import ci.foncier.chaincode.util.DeterministicMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.hyperledger.fabric.contract.Context;
import org.hyperledger.fabric.contract.ContractInterface;
import org.hyperledger.fabric.contract.annotation.*;
import org.hyperledger.fabric.shim.ChaincodeException;
import org.hyperledger.fabric.shim.ledger.KeyValue;
import org.hyperledger.fabric.shim.ledger.QueryResultsIterator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Contract(
    name = "FoncierChaincode",
    info = @Info(
        title = "Contrat Agraire Chaincode",
        description = "Chaincode pour la gestion des contrats agraires en Côte d'Ivoire",
        version = "1.0.0",
        contact = @Contact(email = "contact@foncier.ci", name = "AFOR")
    )
)
@Default
public class FoncierChaincode implements ContractInterface {

    private static final Logger logger = LoggerFactory.getLogger(FoncierChaincode.class);
    private final ObjectMapper objectMapper;

    public FoncierChaincode() {
        this.objectMapper = DeterministicMapper.create();
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void initLedger(final Context context) {
        logger.info("Initialisation du chaincode Contrats Agraires - Version 1.0.0");
        
        try {
        Map<String, Object> metadata = new HashMap<>();
        metadata.put("supportedChannels", Arrays.asList("contrat-agraire", "admin"));
        metadata.put("organizations", Arrays.asList("AFOR", "CVGFR", "PREFET"));
        // Utiliser le timestamp de la transaction pour garantir le déterminisme
        metadata.put("initialized", context.getStub().getTxTimestamp().toString());
        metadata.put("version", "1.0.0");            context.getStub().putStringState("CHAINCODE_METADATA", objectMapper.writeValueAsString(metadata));
            logger.info("Chaincode initialisé avec succès");
        } catch (Exception e) {
            logger.error("Erreur lors de l'initialisation: {}", e.getMessage());
            throw new ChaincodeException("Erreur d'initialisation: " + e.getMessage(), "INIT_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire creerContrat(final Context context, final String contratJson) {
        logger.info("Création d'un nouveau contrat agraire");
        
        try {
            ContratAgraire contrat = objectMapper.readValue(contratJson, ContratAgraire.class);
            
            if (contrat.getId() == null || contrat.getId().trim().isEmpty()) {
                throw new ChaincodeException("L'ID du contrat est requis", "INVALID_INPUT");
            }
            
            // Validation: UUID et creationDate DOIVENT être fournis pour garantir le déterminisme
            if (contrat.getUuid() == null || contrat.getUuid().trim().isEmpty()) {
                throw new ChaincodeException("L'UUID du contrat est requis pour garantir le déterminisme", "INVALID_INPUT");
            }
            
            if (contrat.getCreationDate() == null) {
                throw new ChaincodeException("La date de création du contrat est requise pour garantir le déterminisme", "INVALID_INPUT");
            }
            
            String existingContrat = context.getStub().getStringState(contrat.getId());
            if (existingContrat != null && !existingContrat.trim().isEmpty()) {
                throw new ChaincodeException("Le contrat avec l'ID " + contrat.getId() + " existe déjà", "CONTRAT_EXISTS");
            }
            
            if (contrat.getCodeContract() == null || contrat.getCodeContract().trim().isEmpty()) {
                contrat.setCodeContract(genererCodeContrat(contrat));
            }
            
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contrat.getId(), contratJsonSave);
            context.getStub().setEvent("ContratCree", contrat.getId().getBytes());
            
            logger.info("Contrat créé avec succès: {}", contrat.getId());
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la création du contrat: {}", e.getMessage(), e);
            throw new ChaincodeException("Erreur de création: " + e.getMessage(), "CREATE_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public ContratAgraire lireContrat(final Context context, final String contratId) {
        logger.info("Lecture du contrat: {}", contratId);
        
        try {
            String contratJson = context.getStub().getStringState(contratId);
            if (contratJson == null || contratJson.trim().isEmpty()) {
                throw new ChaincodeException("Contrat non trouvé: " + contratId, "CONTRAT_NOT_FOUND");
            }
            
            return objectMapper.readValue(contratJson, ContratAgraire.class);
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la lecture du contrat {}: {}", contratId, e.getMessage());
            throw new ChaincodeException("Erreur de lecture: " + e.getMessage(), "READ_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire modifierContrat(final Context context, final String contratId, final String contratJson) {
        logger.info("Modification du contrat: {}", contratId);
        
        try {
            ContratAgraire contratExistant = lireContrat(context, contratId);
            ContratAgraire contratModifie = objectMapper.readValue(contratJson, ContratAgraire.class);
            contratModifie.setId(contratId);
            contratModifie.setCreationDate(contratExistant.getCreationDate());
            
            String contratJsonSave = objectMapper.writeValueAsString(contratModifie);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("ContratModifie", contratId.getBytes());
            
            logger.info("Contrat modifié avec succès: {}", contratId);
            return contratModifie;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la modification du contrat: {}", e.getMessage());
            throw new ChaincodeException("Erreur de modification: " + e.getMessage(), "UPDATE_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public void supprimerContrat(final Context context, final String contratId) {
        logger.info("Suppression du contrat: {}", contratId);
        
        try {
            lireContrat(context, contratId);
            context.getStub().delState(contratId);
            context.getStub().setEvent("ContratSupprime", contratId.getBytes());
            
            logger.info("Contrat supprimé avec succès: {}", contratId);
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la suppression du contrat: {}", e.getMessage());
            throw new ChaincodeException("Erreur de suppression: " + e.getMessage(), "DELETE_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String listerContrats(final Context context) {
        logger.info("Listing de tous les contrats");
        
        try {
            List<ContratAgraire> contrats = new ArrayList<>();
            QueryResultsIterator<KeyValue> results = context.getStub().getStateByRange("", "");
            
            for (KeyValue result : results) {
                String key = result.getKey();
                String value = result.getStringValue();
                
                if (key.equals("CHAINCODE_METADATA")) {
                    continue;
                }
                
                try {
                    ContratAgraire contrat = objectMapper.readValue(value, ContratAgraire.class);
                    contrats.add(contrat);
                } catch (Exception e) {
                    logger.warn("Impossible de parser le contrat {}: {}", key, e.getMessage());
                }
            }
            
            logger.info("Nombre de contrats trouvés: {}", contrats.size());
            return objectMapper.writeValueAsString(contrats);
            
        } catch (Exception e) {
            logger.error("Erreur lors du listing des contrats: {}", e.getMessage());
            throw new ChaincodeException("Erreur de listing: " + e.getMessage(), "LIST_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String rechercherParProprietaire(final Context context, final String ownerName) {
        logger.info("Recherche des contrats pour le propriétaire: {}", ownerName);
        
        try {
            List<ContratAgraire> contrats = new ArrayList<>();
            QueryResultsIterator<KeyValue> results = context.getStub().getStateByRange("", "");
            
            for (KeyValue result : results) {
                String key = result.getKey();
                String value = result.getStringValue();
                
                if (key.equals("CHAINCODE_METADATA")) {
                    continue;
                }
                
                try {
                    ContratAgraire contrat = objectMapper.readValue(value, ContratAgraire.class);
                    if (contrat.getOwner() != null && 
                        contrat.getOwner().getName() != null && 
                        contrat.getOwner().getName().toLowerCase().contains(ownerName.toLowerCase())) {
                        contrats.add(contrat);
                    }
                } catch (Exception e) {
                    logger.warn("Impossible de parser le contrat {}: {}", key, e.getMessage());
                }
            }
            
            logger.info("Nombre de contrats trouvés pour {}: {}", ownerName, contrats.size());
            return objectMapper.writeValueAsString(contrats);
            
        } catch (Exception e) {
            logger.error("Erreur lors de la recherche: {}", e.getMessage());
            throw new ChaincodeException("Erreur de recherche: " + e.getMessage(), "SEARCH_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String obtenirHistorique(final Context context, final String contratId) {
        logger.info("Récupération de l'historique du contrat: {}", contratId);
        
        try {
            List<Map<String, Object>> historique = new ArrayList<>();
            QueryResultsIterator<org.hyperledger.fabric.shim.ledger.KeyModification> results = 
                context.getStub().getHistoryForKey(contratId);
            
            for (org.hyperledger.fabric.shim.ledger.KeyModification modification : results) {
                Map<String, Object> entry = new HashMap<>();
                entry.put("txId", modification.getTxId());
                entry.put("timestamp", modification.getTimestamp());
                entry.put("isDelete", modification.isDeleted());
                
                if (!modification.isDeleted()) {
                    String value = modification.getStringValue();
                    try {
                        ContratAgraire contrat = objectMapper.readValue(value, ContratAgraire.class);
                        entry.put("value", contrat);
                    } catch (Exception e) {
                        entry.put("value", value);
                    }
                }
                
                historique.add(entry);
            }
            
            logger.info("Historique récupéré: {} entrées", historique.size());
            return objectMapper.writeValueAsString(historique);
            
        } catch (Exception e) {
            logger.error("Erreur lors de la récupération de l'historique: {}", e.getMessage());
            throw new ChaincodeException("Erreur d'historique: " + e.getMessage(), "HISTORY_ERROR");
        }
    }

    private String genererCodeContrat(ContratAgraire contrat) {
        String prefix = "CA";
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String random = UUID.randomUUID().toString().substring(0, 8).toUpperCase();
        return String.format("%s-%s-%s", prefix, timestamp, random);
    }
}
