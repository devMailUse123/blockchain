package ci.foncier.chaincode;

import ci.foncier.chaincode.model.*;
import ci.foncier.chaincode.util.DeterministicMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
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
            
            // Initialiser le workflow
            contrat.setStatus("DRAFT");
            contrat.setModifiable(true);
            contrat.setDeletable(true);
            
            // Créer l'action CREATE
            WorkflowAction createAction = new WorkflowAction();
            createAction.setType("CREATE");
            createAction.setTimestamp(contrat.getCreationDate());
            createAction.setTransactionId(context.getStub().getTxId());
            createAction.setNewStatus("DRAFT");
            contrat.getActions().add(createAction);
            
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
            
            // Vérifier si le contrat est modifiable
            if (!contratExistant.isModifiable()) {
                throw new ChaincodeException("Le contrat " + contratId + " ne peut plus être modifié (statut: " + 
                    contratExistant.getStatus() + ")", "CONTRAT_NOT_MODIFIABLE");
            }
            
            ContratAgraire contratModifie = objectMapper.readValue(contratJson, ContratAgraire.class);
            contratModifie.setId(contratId);
            contratModifie.setCreationDate(contratExistant.getCreationDate());
            
            // Préserver le workflow existant
            contratModifie.setStatus(contratExistant.getStatus());
            contratModifie.setModifiable(contratExistant.isModifiable());
            contratModifie.setDeletable(contratExistant.isDeletable());
            contratModifie.setActions(contratExistant.getActions());
            contratModifie.setSignatures(contratExistant.getSignatures());
            contratModifie.setApprobation(contratExistant.getApprobation());
            contratModifie.setValidation(contratExistant.getValidation());
            
            // Ajouter une action MODIFY
            WorkflowAction modifyAction = new WorkflowAction();
            modifyAction.setType("MODIFY");
            modifyAction.setTimestamp(LocalDateTime.now());
            modifyAction.setTransactionId(context.getStub().getTxId());
            contratModifie.getActions().add(modifyAction);
            
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
    public void supprimerContrat(final Context context, final String contratId, final String actorJson, final String reason) {
        logger.info("Suppression du contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            
            // Vérifier si le contrat est supprimable
            if (!contrat.isDeletable()) {
                throw new ChaincodeException("Le contrat " + contratId + " ne peut pas être supprimé (statut: " + 
                    contrat.getStatus() + ")", "CONTRAT_NOT_DELETABLE");
            }
            
            Actor actor = objectMapper.readValue(actorJson, Actor.class);
            
            // Soft delete: marquer comme supprimé au lieu de supprimer
            contrat.setDeletedAt(LocalDateTime.now());
            contrat.setDeletedBy(actor.getUserId());
            contrat.setDeletedReason(reason);
            contrat.setStatus("DELETED");
            contrat.setModifiable(false);
            contrat.setDeletable(false);
            
            // Ajouter une action DELETE
            WorkflowAction deleteAction = new WorkflowAction();
            deleteAction.setType("DELETE");
            deleteAction.setActor(actor);
            deleteAction.setTimestamp(LocalDateTime.now());
            deleteAction.setComment(reason);
            deleteAction.setPreviousStatus(contrat.getStatus());
            deleteAction.setNewStatus("DELETED");
            deleteAction.setTransactionId(context.getStub().getTxId());
            contrat.getActions().add(deleteAction);
            
            // Sauvegarder au lieu de supprimer (audit trail)
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("ContratSupprime", contratId.getBytes());
            
            logger.info("Contrat marqué comme supprimé avec succès: {}", contratId);
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la suppression du contrat: {}", e.getMessage());
            throw new ChaincodeException("Erreur de suppression: " + e.getMessage(), "DELETE_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire ajouterSignature(final Context context, final String contratId, final String signatureJson) {
        logger.info("Ajout d'une signature pour le contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            
            if (!"DRAFT".equals(contrat.getStatus()) && !"SIGNED".equals(contrat.getStatus())) {
                throw new ChaincodeException("Les signatures ne peuvent être ajoutées qu'aux contrats en statut DRAFT ou SIGNED", 
                    "INVALID_STATUS");
            }
            
            PartySignature signature = objectMapper.readValue(signatureJson, PartySignature.class);
            contrat.getSignatures().add(signature);
            
            // Vérifier si toutes les signatures requises sont présentes
            if (hasAllRequiredSignatures(contrat)) {
                contrat.setStatus("SIGNED");
                
                WorkflowAction signAction = new WorkflowAction();
                signAction.setType("SIGN");
                signAction.setTimestamp(LocalDateTime.now());
                signAction.setPreviousStatus("DRAFT");
                signAction.setNewStatus("SIGNED");
                signAction.setTransactionId(context.getStub().getTxId());
                signAction.setComment("Toutes les signatures requises ont été collectées");
                contrat.getActions().add(signAction);
                
                logger.info("Contrat {} complètement signé", contratId);
            }
            
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("SignatureAjoutee", contratId.getBytes());
            
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de l'ajout de signature: {}", e.getMessage());
            throw new ChaincodeException("Erreur signature: " + e.getMessage(), "SIGNATURE_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire approuverContrat(final Context context, final String contratId, final String approbationJson) {
        logger.info("Approbation du contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            
            if (!"SIGNED".equals(contrat.getStatus())) {
                throw new ChaincodeException("Seuls les contrats signés peuvent être approuvés", "INVALID_STATUS");
            }
            
            ContractApprobation approbation = objectMapper.readValue(approbationJson, ContractApprobation.class);
            contrat.setApprobation(approbation);
            contrat.setStatus("APPROVED");
            
            WorkflowAction approveAction = new WorkflowAction();
            approveAction.setType("APPROVE");
            Actor approver = new Actor();
            approver.setUserId(approbation.getApprovedBy());
            approver.setUserName(approbation.getApproverName());
            approver.setRole(approbation.getApproverRole());
            approveAction.setActor(approver);
            approveAction.setTimestamp(approbation.getApprovedAt());
            approveAction.setSignature(approbation.getDigitalSignature());
            approveAction.setPreviousStatus("SIGNED");
            approveAction.setNewStatus("APPROVED");
            approveAction.setTransactionId(context.getStub().getTxId());
            contrat.getActions().add(approveAction);
            
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("ContratApprouve", contratId.getBytes());
            
            logger.info("Contrat approuvé avec succès: {}", contratId);
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de l'approbation: {}", e.getMessage());
            throw new ChaincodeException("Erreur approbation: " + e.getMessage(), "APPROVAL_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire validerContrat(final Context context, final String contratId, final String validationJson) {
        logger.info("Validation finale du contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            
            if (!"APPROVED".equals(contrat.getStatus())) {
                throw new ChaincodeException("Seuls les contrats approuvés peuvent être validés", "INVALID_STATUS");
            }
            
            ContractValidation validation = objectMapper.readValue(validationJson, ContractValidation.class);
            
            // Vérifier le hash du document
            if (validation.getDocumentHash() == null || validation.getDocumentHash().isEmpty()) {
                throw new ChaincodeException("Le hash SHA-256 du document est requis", "MISSING_HASH");
            }
            
            if (validation.getDigitalSignature() == null || validation.getDigitalSignature().isEmpty()) {
                throw new ChaincodeException("La signature ECDSA est requise", "MISSING_SIGNATURE");
            }
            
            contrat.setValidation(validation);
            contrat.setStatus("VALIDATED");
            contrat.setModifiable(false); // Plus de modification possible
            contrat.setDeletable(false); // Plus de suppression possible
            
            WorkflowAction validateAction = new WorkflowAction();
            validateAction.setType("VALIDATE");
            Actor validator = new Actor();
            validator.setUserId(validation.getValidatedBy());
            validator.setUserName(validation.getValidatorName());
            validator.setRole("VALIDATOR");
            validateAction.setActor(validator);
            validateAction.setTimestamp(validation.getValidatedAt());
            validateAction.setSignature(validation.getDigitalSignature());
            validateAction.setPreviousStatus("APPROVED");
            validateAction.setNewStatus("VALIDATED");
            validateAction.setTransactionId(context.getStub().getTxId());
            validateAction.setComment("Document hash: " + validation.getDocumentHash());
            contrat.getActions().add(validateAction);
            
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("ContratValide", contratId.getBytes());
            
            logger.info("Contrat validé et scellé avec succès: {}", contratId);
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors de la validation: {}", e.getMessage());
            throw new ChaincodeException("Erreur validation: " + e.getMessage(), "VALIDATION_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.SUBMIT)
    public ContratAgraire rejeterContrat(final Context context, final String contratId, final String actorJson, final String reason) {
        logger.info("Rejet du contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            Actor actor = objectMapper.readValue(actorJson, Actor.class);
            
            String previousStatus = contrat.getStatus();
            contrat.setStatus("REJECTED");
            contrat.setModifiable(true); // Permettre la modification après rejet
            
            WorkflowAction rejectAction = new WorkflowAction();
            rejectAction.setType("REJECT");
            rejectAction.setActor(actor);
            rejectAction.setTimestamp(LocalDateTime.now());
            rejectAction.setComment(reason);
            rejectAction.setPreviousStatus(previousStatus);
            rejectAction.setNewStatus("REJECTED");
            rejectAction.setTransactionId(context.getStub().getTxId());
            contrat.getActions().add(rejectAction);
            
            String contratJsonSave = objectMapper.writeValueAsString(contrat);
            context.getStub().putStringState(contratId, contratJsonSave);
            context.getStub().setEvent("ContratRejete", contratId.getBytes());
            
            logger.info("Contrat rejeté: {}", contratId);
            return contrat;
            
        } catch (ChaincodeException e) {
            throw e;
        } catch (Exception e) {
            logger.error("Erreur lors du rejet: {}", e.getMessage());
            throw new ChaincodeException("Erreur rejet: " + e.getMessage(), "REJECT_ERROR");
        }
    }

    @Transaction(intent = Transaction.TYPE.EVALUATE)
    public String verifierContrat(final Context context, final String contratId) {
        logger.info("Vérification de l'intégrité du contrat: {}", contratId);
        
        try {
            ContratAgraire contrat = lireContrat(context, contratId);
            Map<String, Object> verification = new HashMap<>();
            
            verification.put("contratId", contratId);
            verification.put("status", contrat.getStatus());
            verification.put("isModifiable", contrat.isModifiable());
            verification.put("isDeletable", contrat.isDeletable());
            verification.put("nombreSignatures", contrat.getSignatures().size());
            verification.put("aApprobation", contrat.getApprobation() != null);
            verification.put("aValidation", contrat.getValidation() != null);
            verification.put("nombreActions", contrat.getActions().size());
            
            if (contrat.getValidation() != null) {
                verification.put("documentHash", contrat.getValidation().getDocumentHash());
                verification.put("signatureAlgorithm", contrat.getValidation().getSignatureAlgorithm());
                verification.put("validatedBy", contrat.getValidation().getValidatorName());
                verification.put("validatedAt", contrat.getValidation().getValidatedAt());
                verification.put("blockchainTimestamp", contrat.getValidation().getBlockchainTimestamp());
            }
            
            verification.put("integrite", "OK");
            verification.put("message", "Contrat vérifié avec succès");
            
            return objectMapper.writeValueAsString(verification);
            
        } catch (Exception e) {
            logger.error("Erreur lors de la vérification: {}", e.getMessage());
            throw new ChaincodeException("Erreur vérification: " + e.getMessage(), "VERIFICATION_ERROR");
        }
    }

    private boolean hasAllRequiredSignatures(ContratAgraire contrat) {
        boolean hasOwner = false;
        boolean hasBeneficiary = false;
        
        for (PartySignature sig : contrat.getSignatures()) {
            if ("OWNER".equals(sig.getPartyType())) {
                hasOwner = true;
            } else if ("BENEFICIARY".equals(sig.getPartyType())) {
                hasBeneficiary = true;
            }
        }
        
        return hasOwner && hasBeneficiary;
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
