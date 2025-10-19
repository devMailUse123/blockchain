package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import javax.validation.constraints.DecimalMin;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * Représente les informations d'un terrain dans le système foncier
 */
public class Terrain {
    
    @NotBlank(message = "La localisation est obligatoire")
    @Size(max = 200, message = "La localisation ne peut pas dépasser 200 caractères")
    private String localisation;
    
    @NotNull(message = "La superficie est obligatoire")
    @DecimalMin(value = "0.0", inclusive = false, message = "La superficie doit être positive")
    private Double superficie;
    
    @NotBlank(message = "L'unité est obligatoire")
    @Pattern(regexp = "HECTARE|M2", message = "Unité invalide (HECTARE ou M2)")
    private String unite;
    
    @JsonProperty("numeroTitreFoncier")
    @Size(max = 50, message = "Le numéro de titre foncier ne peut pas dépasser 50 caractères")
    private String numeroTitreFoncier;
    
    @JsonProperty("numeroCertificat")
    @Size(max = 50, message = "Le numéro de certificat ne peut pas dépasser 50 caractères")
    private String numeroCertificat;
    
    @NotBlank(message = "Le type de titre est obligatoire")
    @Pattern(regexp = "TITRE_FONCIER|CERTIFICAT|AUTRE", message = "Type de titre invalide")
    @JsonProperty("typeTitre")
    private String typeTitre;
    
    @Size(max = 500, message = "Les coordonnées ne peuvent pas dépasser 500 caractères")
    private String coordonnees;
    
    @JsonProperty("croquisDisponible")
    private Boolean croquisDisponible = false;
    
    @NotBlank(message = "Le statut juridique est obligatoire")
    @Pattern(regexp = "PRIVE|DOMANIAL|COUTUMIER", message = "Statut juridique invalide")
    @JsonProperty("statutJuridique")
    private String statutJuridique;
    
    @NotBlank(message = "L'usage autorisé est obligatoire")
    @Pattern(regexp = "AGRICOLE|HABITATION|MIXTE", message = "Usage autorisé invalide")
    @JsonProperty("usageAutorise")
    private String usageAutorise;
    
    // Constructeurs
    public Terrain() {}
    
    public Terrain(String localisation, Double superficie, String unite, 
                  String typeTitre, String statutJuridique, String usageAutorise) {
        this.localisation = localisation;
        this.superficie = superficie;
        this.unite = unite;
        this.typeTitre = typeTitre;
        this.statutJuridique = statutJuridique;
        this.usageAutorise = usageAutorise;
        this.croquisDisponible = false;
    }
    
    // Getters et Setters
    public String getLocalisation() { return localisation; }
    public void setLocalisation(String localisation) { this.localisation = localisation; }
    
    public Double getSuperficie() { return superficie; }
    public void setSuperficie(Double superficie) { this.superficie = superficie; }
    
    public String getUnite() { return unite; }
    public void setUnite(String unite) { this.unite = unite; }
    
    public String getNumeroTitreFoncier() { return numeroTitreFoncier; }
    public void setNumeroTitreFoncier(String numeroTitreFoncier) { this.numeroTitreFoncier = numeroTitreFoncier; }
    
    public String getNumeroCertificat() { return numeroCertificat; }
    public void setNumeroCertificat(String numeroCertificat) { this.numeroCertificat = numeroCertificat; }
    
    public String getTypeTitre() { return typeTitre; }
    public void setTypeTitre(String typeTitre) { this.typeTitre = typeTitre; }
    
    public String getCoordonnees() { return coordonnees; }
    public void setCoordonnees(String coordonnees) { this.coordonnees = coordonnees; }
    
    public Boolean getCroquisDisponible() { return croquisDisponible; }
    public void setCroquisDisponible(Boolean croquisDisponible) { this.croquisDisponible = croquisDisponible; }
    
    public String getStatutJuridique() { return statutJuridique; }
    public void setStatutJuridique(String statutJuridique) { this.statutJuridique = statutJuridique; }
    
    public String getUsageAutorise() { return usageAutorise; }
    public void setUsageAutorise(String usageAutorise) { this.usageAutorise = usageAutorise; }
    
    /**
     * Calcule la superficie en mètres carrés
     */
    public double getSuperficieEnM2() {
        if (superficie == null) return 0.0;
        
        if ("HECTARE".equals(unite)) {
            return superficie * 10000; // 1 hectare = 10 000 m²
        }
        return superficie; // déjà en m²
    }
    
    @Override
    public String toString() {
        return "Terrain{" +
                "localisation='" + localisation + '\'' +
                ", superficie=" + superficie +
                ", unite='" + unite + '\'' +
                ", typeTitre='" + typeTitre + '\'' +
                ", statutJuridique='" + statutJuridique + '\'' +
                ", usageAutorise='" + usageAutorise + '\'' +
                '}';
    }
}