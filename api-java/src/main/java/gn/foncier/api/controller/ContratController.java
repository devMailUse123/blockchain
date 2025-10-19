package gn.foncier.api.controller;

import gn.foncier.api.model.ContratFoncier;
import gn.foncier.api.service.FabricService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.validation.Valid;
import java.util.List;
import java.util.Map;

/**
 * Contrôleur REST pour la gestion des contrats fonciers
 */
@RestController
@RequestMapping("/api/v1/contrats")
@Tag(name = "Contrats Fonciers", description = "API de gestion des contrats fonciers ruraux")
@CrossOrigin(origins = "*")
public class ContratController {

    private static final Logger logger = LoggerFactory.getLogger(ContratController.class);
    
    private final FabricService fabricService;

    public ContratController(FabricService fabricService) {
        this.fabricService = fabricService;
    }

    @Operation(summary = "Créer un nouveau contrat", description = "Crée un nouveau contrat foncier sur la blockchain")
    @ApiResponse(responseCode = "201", description = "Contrat créé avec succès")
    @ApiResponse(responseCode = "400", description = "Données invalides")
    @ApiResponse(responseCode = "500", description = "Erreur serveur")
    @PostMapping
    public ResponseEntity<Map<String, Object>> creerContrat(@Valid @RequestBody ContratFoncier contrat) {
        try {
            logger.info("Demande de création de contrat: {}", contrat.getId());
            
            ContratFoncier contratCree = fabricService.creerContrat(contrat);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "success", true,
                "message", "Contrat créé avec succès",
                "data", contratCree
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la création du contrat: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la création: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Lire un contrat", description = "Récupère un contrat par son identifiant")
    @ApiResponse(responseCode = "200", description = "Contrat récupéré avec succès")
    @ApiResponse(responseCode = "404", description = "Contrat non trouvé")
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> lireContrat(
            @Parameter(description = "Identifiant du contrat") @PathVariable String id) {
        try {
            logger.info("Demande de lecture du contrat: {}", id);
            
            ContratFoncier contrat = fabricService.lireContrat(id);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", contrat
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la lecture du contrat {}: {}", id, e.getMessage());
            
            if (e.getMessage().contains("non trouvé")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", "Contrat non trouvé"
                ));
            }
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la lecture: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Modifier un contrat", description = "Modifie un contrat existant")
    @ApiResponse(responseCode = "200", description = "Contrat modifié avec succès")
    @ApiResponse(responseCode = "404", description = "Contrat non trouvé")
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> modifierContrat(
            @Parameter(description = "Identifiant du contrat") @PathVariable String id,
            @Valid @RequestBody ContratFoncier contrat) {
        try {
            logger.info("Demande de modification du contrat: {}", id);
            
            ContratFoncier contratModifie = fabricService.modifierContrat(id, contrat);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Contrat modifié avec succès",
                "data", contratModifie
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la modification du contrat {}: {}", id, e.getMessage());
            
            if (e.getMessage().contains("non trouvé")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", "Contrat non trouvé"
                ));
            }
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la modification: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Archiver un contrat", description = "Archive un contrat (soft delete)")
    @ApiResponse(responseCode = "200", description = "Contrat archivé avec succès")
    @ApiResponse(responseCode = "404", description = "Contrat non trouvé")
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> archiverContrat(
            @Parameter(description = "Identifiant du contrat") @PathVariable String id) {
        try {
            logger.info("Demande d'archivage du contrat: {}", id);
            
            fabricService.archiverContrat(id);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "Contrat archivé avec succès"
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de l'archivage du contrat {}: {}", id, e.getMessage());
            
            if (e.getMessage().contains("non trouvé")) {
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "success", false,
                    "message", "Contrat non trouvé"
                ));
            }
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de l'archivage: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Lister tous les contrats", description = "Récupère la liste de tous les contrats actifs")
    @GetMapping
    public ResponseEntity<Map<String, Object>> listerContrats() {
        try {
            logger.info("Demande de listage de tous les contrats");
            
            List<ContratFoncier> contrats = fabricService.listerContrats();
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", contrats,
                "count", contrats.size()
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors du listage des contrats: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors du listage: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Rechercher par propriétaire", description = "Recherche des contrats par nom du propriétaire")
    @GetMapping("/search/proprietaire")
    public ResponseEntity<Map<String, Object>> rechercherParProprietaire(
            @Parameter(description = "Nom du propriétaire") @RequestParam String nom) {
        try {
            logger.info("Recherche de contrats pour le propriétaire: {}", nom);
            
            List<ContratFoncier> contrats = fabricService.rechercherParProprietaire(nom);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", contrats,
                "count", contrats.size()
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la recherche par propriétaire {}: {}", nom, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la recherche: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Rechercher par région", description = "Recherche des contrats par région")
    @GetMapping("/search/region")
    public ResponseEntity<Map<String, Object>> rechercherParRegion(
            @Parameter(description = "Région") @RequestParam String region) {
        try {
            logger.info("Recherche de contrats pour la région: {}", region);
            
            List<ContratFoncier> contrats = fabricService.rechercherParRegion(region);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", contrats,
                "count", contrats.size()
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la recherche par région {}: {}", region, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la recherche: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Rechercher par type", description = "Recherche des contrats par type")
    @GetMapping("/search/type")
    public ResponseEntity<Map<String, Object>> rechercherParType(
            @Parameter(description = "Type de contrat") @RequestParam String type) {
        try {
            logger.info("Recherche de contrats de type: {}", type);
            
            List<ContratFoncier> contrats = fabricService.rechercherParType(type);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", contrats,
                "count", contrats.size()
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la recherche par type {}: {}", type, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la recherche: " + e.getMessage()
            ));
        }
    }

    @Operation(summary = "Obtenir l'historique", description = "Récupère l'historique complet d'un contrat")
    @GetMapping("/{id}/historique")
    public ResponseEntity<Map<String, Object>> obtenirHistorique(
            @Parameter(description = "Identifiant du contrat") @PathVariable String id) {
        try {
            logger.info("Demande d'historique du contrat: {}", id);
            
            List<Map<String, Object>> historique = fabricService.obtenirHistorique(id);
            
            return ResponseEntity.ok(Map.of(
                "success", true,
                "data", historique,
                "count", historique.size()
            ));
            
        } catch (Exception e) {
            logger.error("Erreur lors de la récupération de l'historique {}: {}", id, e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(Map.of(
                "success", false,
                "message", "Erreur lors de la récupération de l'historique: " + e.getMessage()
            ));
        }
    }
}