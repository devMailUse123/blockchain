package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Métadonnées techniques d'un contrat foncier
 */
public class Metadonnees {
    
    @JsonProperty("organisationCreatrice")
    private String organisationCreatrice;
    
    @JsonProperty("utilisateurCreateur")
    private String utilisateurCreateur;
    
    @JsonProperty("dateCreation")
    private String dateCreation;
    
    @JsonProperty("derniereMaj")
    private String derniereMaj;
    
    private Integer version = 1;
    
    private String checksum;
    
    // Constructeurs
    public Metadonnees() {}
    
    public Metadonnees(String organisationCreatrice, String utilisateurCreateur) {
        this.organisationCreatrice = organisationCreatrice;
        this.utilisateurCreateur = utilisateurCreateur;
        this.version = 1;
    }
    
    // Getters et Setters
    public String getOrganisationCreatrice() { return organisationCreatrice; }
    public void setOrganisationCreatrice(String organisationCreatrice) { this.organisationCreatrice = organisationCreatrice; }
    
    public String getUtilisateurCreateur() { return utilisateurCreateur; }
    public void setUtilisateurCreateur(String utilisateurCreateur) { this.utilisateurCreateur = utilisateurCreateur; }
    
    public String getDateCreation() { return dateCreation; }
    public void setDateCreation(String dateCreation) { this.dateCreation = dateCreation; }
    
    public String getDerniereMaj() { return derniereMaj; }
    public void setDerniereMaj(String derniereMaj) { this.derniereMaj = derniereMaj; }
    
    public Integer getVersion() { return version; }
    public void setVersion(Integer version) { this.version = version; }
    
    public String getChecksum() { return checksum; }
    public void setChecksum(String checksum) { this.checksum = checksum; }
    
    /**
     * Incrémente la version
     */
    public void incrementerVersion() {
        this.version = (this.version == null) ? 1 : this.version + 1;
    }
    
    @Override
    public String toString() {
        return "Metadonnees{" +
                "organisationCreatrice='" + organisationCreatrice + '\'' +
                ", utilisateurCreateur='" + utilisateurCreateur + '\'' +
                ", version=" + version +
                '}';
    }
}