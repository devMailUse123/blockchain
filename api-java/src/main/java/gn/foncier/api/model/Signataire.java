package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * Représente un signataire d'un contrat foncier
 */
public class Signataire {
    
    @NotBlank(message = "Le nom est obligatoire")
    @Size(max = 100, message = "Le nom ne peut pas dépasser 100 caractères")
    private String nom;
    
    @NotBlank(message = "La qualité est obligatoire")
    @Pattern(regexp = "PROPRIETAIRE|BENEFICIAIRE|TEMOIN|AUTORITE", 
             message = "Qualité invalide")
    private String qualite;
    
    @Pattern(regexp = "AFOR|CVGFR|PREFET|", message = "Organisation invalide")
    private String organisation;
    
    @JsonProperty("dateSignature")
    private String dateSignature;
    
    @JsonProperty("signatureHash")
    @Size(max = 256, message = "Le hash de signature ne peut pas dépasser 256 caractères")
    private String signatureHash;
    
    private Boolean temoin = false;
    
    // Constructeurs
    public Signataire() {}
    
    public Signataire(String nom, String qualite, String organisation) {
        this.nom = nom;
        this.qualite = qualite;
        this.organisation = organisation;
        this.temoin = "TEMOIN".equals(qualite);
    }
    
    // Getters et Setters
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    
    public String getQualite() { return qualite; }
    public void setQualite(String qualite) { 
        this.qualite = qualite;
        this.temoin = "TEMOIN".equals(qualite);
    }
    
    public String getOrganisation() { return organisation; }
    public void setOrganisation(String organisation) { this.organisation = organisation; }
    
    public String getDateSignature() { return dateSignature; }
    public void setDateSignature(String dateSignature) { this.dateSignature = dateSignature; }
    
    public String getSignatureHash() { return signatureHash; }
    public void setSignatureHash(String signatureHash) { this.signatureHash = signatureHash; }
    
    public Boolean getTemoin() { return temoin; }
    public void setTemoin(Boolean temoin) { this.temoin = temoin; }
    
    /**
     * Vérifie si le signataire a signé
     */
    public boolean aSigné() {
        return dateSignature != null && !dateSignature.trim().isEmpty();
    }
    
    /**
     * Vérifie si le signataire est une autorité
     */
    public boolean estAutorite() {
        return "AUTORITE".equals(qualite);
    }
    
    @Override
    public String toString() {
        return "Signataire{" +
                "nom='" + nom + '\'' +
                ", qualite='" + qualite + '\'' +
                ", organisation='" + organisation + '\'' +
                ", dateSignature='" + dateSignature + '\'' +
                ", temoin=" + temoin +
                '}';
    }
}