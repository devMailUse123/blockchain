package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Représente un événement dans l'historique d'un contrat
 */
public class Evenement {
    
    private String date;
    
    private String type; // "CREATION", "MODIFICATION", "SIGNATURE", "VALIDATION", "ARCHIVAGE"
    
    private String description;
    
    private String auteur;
    
    private String organisation;
    
    @JsonProperty("statutAvant")
    private String statutAvant;
    
    @JsonProperty("statutApres")
    private String statutApres;
    
    @JsonProperty("transactionId")
    private String transactionId;
    
    // Constructeurs
    public Evenement() {}
    
    public Evenement(String type, String description, String auteur, String organisation) {
        this.type = type;
        this.description = description;
        this.auteur = auteur;
        this.organisation = organisation;
    }
    
    // Getters et Setters
    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }
    
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getAuteur() { return auteur; }
    public void setAuteur(String auteur) { this.auteur = auteur; }
    
    public String getOrganisation() { return organisation; }
    public void setOrganisation(String organisation) { this.organisation = organisation; }
    
    public String getStatutAvant() { return statutAvant; }
    public void setStatutAvant(String statutAvant) { this.statutAvant = statutAvant; }
    
    public String getStatutApres() { return statutApres; }
    public void setStatutApres(String statutApres) { this.statutApres = statutApres; }
    
    public String getTransactionId() { return transactionId; }
    public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
    
    @Override
    public String toString() {
        return "Evenement{" +
                "date='" + date + '\'' +
                ", type='" + type + '\'' +
                ", description='" + description + '\'' +
                ", auteur='" + auteur + '\'' +
                ", organisation='" + organisation + '\'' +
                '}';
    }
}