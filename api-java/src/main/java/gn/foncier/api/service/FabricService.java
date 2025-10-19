package gn.foncier.api.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import gn.foncier.api.model.ContratFoncier;
import org.hyperledger.fabric.gateway.Contract;
import org.hyperledger.fabric.gateway.ContractException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeoutException;

/**
 * Service pour interagir avec le chaincode Fabric
 */
@Service
public class FabricService {

    private static final Logger logger = LoggerFactory.getLogger(FabricService.class);
    
    private final Contract contract;
    private final ObjectMapper objectMapper;

    public FabricService(Contract contract, ObjectMapper objectMapper) {
        this.contract = contract;
        this.objectMapper = objectMapper;
    }

    /**
     * Crée un nouveau contrat foncier
     */
    public ContratFoncier creerContrat(ContratFoncier contrat) throws Exception {
        logger.info("Création du contrat: {}", contrat.getId());
        
        try {
            String contratJson = objectMapper.writeValueAsString(contrat);
            
            byte[] result = contract.submitTransaction("creerContrat", contratJson);
            
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), ContratFoncier.class);
            
        } catch (ContractException | TimeoutException | InterruptedException e) {
            logger.error("Erreur lors de la création du contrat {}: {}", contrat.getId(), e.getMessage());
            throw new Exception("Erreur de création du contrat: " + e.getMessage(), e);
        }
    }

    /**
     * Lit un contrat par son ID
     */
    public ContratFoncier lireContrat(String contratId) throws Exception {
        logger.info("Lecture du contrat: {}", contratId);
        
        try {
            byte[] result = contract.evaluateTransaction("lireContrat", contratId);
            
            if (result.length == 0) {
                throw new Exception("Contrat non trouvé: " + contratId);
            }
            
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), ContratFoncier.class);
            
        } catch (ContractException e) {
            logger.error("Erreur lors de la lecture du contrat {}: {}", contratId, e.getMessage());
            throw new Exception("Erreur de lecture du contrat: " + e.getMessage(), e);
        }
    }

    /**
     * Modifie un contrat existant
     */
    public ContratFoncier modifierContrat(String contratId, ContratFoncier contrat) throws Exception {
        logger.info("Modification du contrat: {}", contratId);
        
        try {
            String contratJson = objectMapper.writeValueAsString(contrat);
            
            byte[] result = contract.submitTransaction("modifierContrat", contratId, contratJson);
            
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), ContratFoncier.class);
            
        } catch (ContractException | TimeoutException | InterruptedException e) {
            logger.error("Erreur lors de la modification du contrat {}: {}", contratId, e.getMessage());
            throw new Exception("Erreur de modification du contrat: " + e.getMessage(), e);
        }
    }

    /**
     * Archive un contrat
     */
    public void archiverContrat(String contratId) throws Exception {
        logger.info("Archivage du contrat: {}", contratId);
        
        try {
            contract.submitTransaction("archiverContrat", contratId);
            
        } catch (ContractException | TimeoutException | InterruptedException e) {
            logger.error("Erreur lors de l'archivage du contrat {}: {}", contratId, e.getMessage());
            throw new Exception("Erreur d'archivage du contrat: " + e.getMessage(), e);
        }
    }

    /**
     * Recherche des contrats par propriétaire
     */
    public List<ContratFoncier> rechercherParProprietaire(String nomProprietaire) throws Exception {
        logger.info("Recherche de contrats pour le propriétaire: {}", nomProprietaire);
        
        try {
            byte[] result = contract.evaluateTransaction("rechercherParProprietaire", nomProprietaire);
            
            TypeReference<List<ContratFoncier>> typeRef = new TypeReference<List<ContratFoncier>>() {};
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), typeRef);
            
        } catch (ContractException e) {
            logger.error("Erreur lors de la recherche par propriétaire {}: {}", nomProprietaire, e.getMessage());
            throw new Exception("Erreur de recherche: " + e.getMessage(), e);
        }
    }

    /**
     * Recherche des contrats par région
     */
    public List<ContratFoncier> rechercherParRegion(String region) throws Exception {
        logger.info("Recherche de contrats pour la région: {}", region);
        
        try {
            byte[] result = contract.evaluateTransaction("rechercherParRegion", region);
            
            TypeReference<List<ContratFoncier>> typeRef = new TypeReference<List<ContratFoncier>>() {};
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), typeRef);
            
        } catch (ContractException e) {
            logger.error("Erreur lors de la recherche par région {}: {}", region, e.getMessage());
            throw new Exception("Erreur de recherche: " + e.getMessage(), e);
        }
    }

    /**
     * Recherche des contrats par type
     */
    public List<ContratFoncier> rechercherParType(String type) throws Exception {
        logger.info("Recherche de contrats de type: {}", type);
        
        try {
            byte[] result = contract.evaluateTransaction("rechercherParType", type);
            
            TypeReference<List<ContratFoncier>> typeRef = new TypeReference<List<ContratFoncier>>() {};
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), typeRef);
            
        } catch (ContractException e) {
            logger.error("Erreur lors de la recherche par type {}: {}", type, e.getMessage());
            throw new Exception("Erreur de recherche: " + e.getMessage(), e);
        }
    }

    /**
     * Liste tous les contrats actifs
     */
    public List<ContratFoncier> listerContrats() throws Exception {
        logger.info("Liste de tous les contrats actifs");
        
        try {
            byte[] result = contract.evaluateTransaction("listerContrats");
            
            TypeReference<List<ContratFoncier>> typeRef = new TypeReference<List<ContratFoncier>>() {};
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), typeRef);
            
        } catch (ContractException e) {
            logger.error("Erreur lors du listage des contrats: {}", e.getMessage());
            throw new Exception("Erreur de listage: " + e.getMessage(), e);
        }
    }

    /**
     * Obtient l'historique d'un contrat
     */
    public List<Map<String, Object>> obtenirHistorique(String contratId) throws Exception {
        logger.info("Récupération de l'historique du contrat: {}", contratId);
        
        try {
            byte[] result = contract.evaluateTransaction("obtenirHistorique", contratId);
            
            TypeReference<List<Map<String, Object>>> typeRef = new TypeReference<List<Map<String, Object>>>() {};
            return objectMapper.readValue(new String(result, StandardCharsets.UTF_8), typeRef);
            
        } catch (ContractException e) {
            logger.error("Erreur lors de la récupération de l'historique {}: {}", contratId, e.getMessage());
            throw new Exception("Erreur de récupération d'historique: " + e.getMessage(), e);
        }
    }
}