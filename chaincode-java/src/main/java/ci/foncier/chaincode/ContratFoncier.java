package ci.foncier.chaincode;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Classe représentant un contrat foncier rural en Côte d'Ivoire
 */
@DataType()
public class ContratFoncier {

    @Property()
    @NotBlank(message = "L'ID du contrat ne peut pas être vide")
    @Size(max = 50, message = "L'ID du contrat ne peut pas dépasser 50 caractères")
    private String id;

    @Property()
    @NotBlank(message = "Le type de contrat ne peut pas être vide")
    @Size(max = 30, message = "Le type de contrat ne peut pas dépasser 30 caractères")
    private String typeContrat;

    @Property()
    @NotBlank(message = "Le propriétaire ne peut pas être vide")
    @Size(max = 100, message = "Le nom du propriétaire ne peut pas dépasser 100 caractères")
    private String proprietaire;

    @Property()
    @NotBlank(message = "Le locataire ne peut pas être vide")
    @Size(max = 100, message = "Le nom du locataire ne peut pas dépasser 100 caractères")
    private String locataire;

    @Property()
    @NotBlank(message = "La parcelle ne peut pas être vide")
    @Size(max = 50, message = "L'ID de la parcelle ne peut pas dépasser 50 caractères")
    private String parcelle;

    @Property()
    @NotNull(message = "La superficie ne peut pas être nulle")
    private Double superficie;

    @Property()
    @NotBlank(message = "La localisation ne peut pas être vide")
    @Size(max = 200, message = "La localisation ne peut pas dépasser 200 caractères")
    private String localisation;

    @Property()
    @NotNull(message = "Le montant ne peut pas être nul")
    private Double montant;

    @Property()
    @NotBlank(message = "La durée ne peut pas être vide")
    @Size(max = 20, message = "La durée ne peut pas dépasser 20 caractères")
    private String duree;

    @Property()
    @NotBlank(message = "Le statut ne peut pas être vide")
    @Size(max = 20, message = "Le statut ne peut pas dépasser 20 caractères")
    private String statut;

    @Property()
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dateCreation;

    @Property()
    @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
    private LocalDateTime dateModification;

    @Property()
    @Size(max = 100, message = "L'organisation ne peut pas dépasser 100 caractères")
    private String organisation;

    @Property()
    @Size(max = 500, message = "Les remarques ne peuvent pas dépasser 500 caractères")
    private String remarques;

    // Constructeur par défaut
    public ContratFoncier() {
        this.dateCreation = LocalDateTime.now();
        this.dateModification = LocalDateTime.now();
        this.statut = "ACTIF";
    }

    // Constructeur complet
    public ContratFoncier(String id, String typeContrat, String proprietaire, String locataire, 
                         String parcelle, Double superficie, String localisation, Double montant, 
                         String duree, String organisation) {
        this();
        this.id = id;
        this.typeContrat = typeContrat;
        this.proprietaire = proprietaire;
        this.locataire = locataire;
        this.parcelle = parcelle;
        this.superficie = superficie;
        this.localisation = localisation;
        this.montant = montant;
        this.duree = duree;
        this.organisation = organisation;
    }

    // Getters et Setters
    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTypeContrat() {
        return typeContrat;
    }

    public void setTypeContrat(String typeContrat) {
        this.typeContrat = typeContrat;
    }

    public String getProprietaire() {
        return proprietaire;
    }

    public void setProprietaire(String proprietaire) {
        this.proprietaire = proprietaire;
    }

    public String getLocataire() {
        return locataire;
    }

    public void setLocataire(String locataire) {
        this.locataire = locataire;
    }

    public String getParcelle() {
        return parcelle;
    }

    public void setParcelle(String parcelle) {
        this.parcelle = parcelle;
    }

    public Double getSuperficie() {
        return superficie;
    }

    public void setSuperficie(Double superficie) {
        this.superficie = superficie;
    }

    public String getLocalisation() {
        return localisation;
    }

    public void setLocalisation(String localisation) {
        this.localisation = localisation;
    }

    public Double getMontant() {
        return montant;
    }

    public void setMontant(Double montant) {
        this.montant = montant;
    }

    public String getDuree() {
        return duree;
    }

    public void setDuree(String duree) {
        this.duree = duree;
    }

    public String getStatut() {
        return statut;
    }

    public void setStatut(String statut) {
        this.statut = statut;
        this.dateModification = LocalDateTime.now();
    }

    public LocalDateTime getDateCreation() {
        return dateCreation;
    }

    public void setDateCreation(LocalDateTime dateCreation) {
        this.dateCreation = dateCreation;
    }

    public LocalDateTime getDateModification() {
        return dateModification;
    }

    public void setDateModification(LocalDateTime dateModification) {
        this.dateModification = dateModification;
    }

    public String getOrganisation() {
        return organisation;
    }

    public void setOrganisation(String organisation) {
        this.organisation = organisation;
    }

    public String getRemarques() {
        return remarques;
    }

    public void setRemarques(String remarques) {
        this.remarques = remarques;
        this.dateModification = LocalDateTime.now();
    }

    // Méthodes utilitaires
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ContratFoncier that = (ContratFoncier) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }

    @Override
    public String toString() {
        return "ContratFoncier{" +
                "id='" + id + '\'' +
                ", typeContrat='" + typeContrat + '\'' +
                ", proprietaire='" + proprietaire + '\'' +
                ", locataire='" + locataire + '\'' +
                ", parcelle='" + parcelle + '\'' +
                ", superficie=" + superficie +
                ", localisation='" + localisation + '\'' +
                ", montant=" + montant +
                ", duree='" + duree + '\'' +
                ", statut='" + statut + '\'' +
                ", organisation='" + organisation + '\'' +
                '}';
    }

    /**
     * Valide si le contrat est dans un état modifiable
     */
    public boolean estModifiable() {
        return "ACTIF".equals(statut) || "BROUILLON".equals(statut);
    }

    /**
     * Marque le contrat comme archivé
     */
    public void archiver() {
        this.statut = "ARCHIVE";
        this.dateModification = LocalDateTime.now();
    }

    /**
     * Calcule la valeur totale du contrat
     */
    public double getValeurTotale() {
        return montant * superficie;
    }
}