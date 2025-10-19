package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.ArrayList;
import java.util.List;

/**
 * Représente un contrat foncier rural dans le système blockchain
 */
public class ContratFoncier {
    
    private String id;
    
    @JsonProperty("codeContrat")
    private String codeContrat;
    
    private String type; // "LOCATION", "VENTE", "CONCESSION", "CONTRAT_AGRAIRE"
    
    private String statut; // "BROUILLON", "ACTIF", "SUSPENDU", "ARCHIVE", "VALIDE"
    
    private String region;
    
    @JsonProperty("sousPrefecture")
    private String sousPrefecture;
    
    private String village;
    
    private Personne proprietaire;
    
    private Personne beneficiaire;
    
    private Terrain terrain;
    
    private List<Signataire> signataires = new ArrayList<>();
    
    @JsonProperty("dateCreation")
    private String dateCreation;
    
    @JsonProperty("dateExpiration")
    private String dateExpiration;
    
    private Double montant;
    
    private String devise = "GNF"; // Franc Côte d'Ivoiren par défaut
    
    private List<Evenement> historique = new ArrayList<>();
    
    private Metadonnees metadonnees;
    
    // Nouveaux champs pour la spécialisation
    @JsonProperty("typeDocument")
    private String typeDocument; // "CONTRAT_AGRAIRE", "CERTIFICAT_FONCIER"
    
    @JsonProperty("numeroEnregistrement")
    private String numeroEnregistrement;
    
    @JsonProperty("autoriteValidatrice")
    private String autoriteValidatrice;
    
    // Constructeurs
    public ContratFoncier() {
        this.signataires = new ArrayList<>();
        this.historique = new ArrayList<>();
    }
    
    public ContratFoncier(String id, String type, String region) {
        this();
        this.id = id;
        this.type = type;
        this.region = region;
        this.statut = "BROUILLON";
        this.devise = "GNF";
    }
    
    // Getters et Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    
    public String getCodeContrat() { return codeContrat; }
    public void setCodeContrat(String codeContrat) { this.codeContrat = codeContrat; }
    
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    
    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }
    
    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }
    
    public String getSousPrefecture() { return sousPrefecture; }
    public void setSousPrefecture(String sousPrefecture) { this.sousPrefecture = sousPrefecture; }
    
    public String getVillage() { return village; }
    public void setVillage(String village) { this.village = village; }
    
    public Personne getProprietaire() { return proprietaire; }
    public void setProprietaire(Personne proprietaire) { this.proprietaire = proprietaire; }
    
    public Personne getBeneficiaire() { return beneficiaire; }
    public void setBeneficiaire(Personne beneficiaire) { this.beneficiaire = beneficiaire; }
    
    public Terrain getTerrain() { return terrain; }
    public void setTerrain(Terrain terrain) { this.terrain = terrain; }
    
    public List<Signataire> getSignataires() { return signataires; }
    public void setSignataires(List<Signataire> signataires) { 
        this.signataires = signataires != null ? signataires : new ArrayList<>(); 
    }
    
    public String getDateCreation() { return dateCreation; }
    public void setDateCreation(String dateCreation) { this.dateCreation = dateCreation; }
    
    public String getDateExpiration() { return dateExpiration; }
    public void setDateExpiration(String dateExpiration) { this.dateExpiration = dateExpiration; }
    
    public Double getMontant() { return montant; }
    public void setMontant(Double montant) { this.montant = montant; }
    
    public String getDevise() { return devise; }
    public void setDevise(String devise) { this.devise = devise; }
    
    public List<Evenement> getHistorique() { return historique; }
    public void setHistorique(List<Evenement> historique) { 
        this.historique = historique != null ? historique : new ArrayList<>(); 
    }
    
    public Metadonnees getMetadonnees() { return metadonnees; }
    public void setMetadonnees(Metadonnees metadonnees) { this.metadonnees = metadonnees; }
    
    public String getTypeDocument() { return typeDocument; }
    public void setTypeDocument(String typeDocument) { this.typeDocument = typeDocument; }
    
    public String getNumeroEnregistrement() { return numeroEnregistrement; }
    public void setNumeroEnregistrement(String numeroEnregistrement) { this.numeroEnregistrement = numeroEnregistrement; }
    
    public String getAutoriteValidatrice() { return autoriteValidatrice; }
    public void setAutoriteValidatrice(String autoriteValidatrice) { this.autoriteValidatrice = autoriteValidatrice; }
    
    // Méthodes utilitaires
    
    /**
     * Ajoute un signataire au contrat
     */
    public void ajouterSignataire(Signataire signataire) {
        if (this.signataires == null) {
            this.signataires = new ArrayList<>();
        }
        this.signataires.add(signataire);
    }
    
    /**
     * Ajoute un événement à l'historique
     */
    public void ajouterEvenement(Evenement evenement) {
        if (this.historique == null) {
            this.historique = new ArrayList<>();
        }
        this.historique.add(evenement);
    }
    
    /**
     * Vérifie si le contrat est valide (toutes les signatures requises)
     */
    public boolean estValide() {
        if (signataires == null || signataires.isEmpty()) {
            return false;
        }
        
        boolean proprietaireSigne = false;
        boolean beneficiaireSigne = false;
        boolean autoriteSigne = false;
        
        for (Signataire sig : signataires) {
            if (sig.aSigné()) {
                if ("PROPRIETAIRE".equals(sig.getQualite())) {
                    proprietaireSigne = true;
                } else if ("BENEFICIAIRE".equals(sig.getQualite())) {
                    beneficiaireSigne = true;
                } else if ("AUTORITE".equals(sig.getQualite())) {
                    autoriteSigne = true;
                }
            }
        }
        
        return proprietaireSigne && beneficiaireSigne && autoriteSigne;
    }
    
    /**
     * Vérifie si le contrat est un contrat agraire
     */
    public boolean estContratAgraire() {
        return "CONTRAT_AGRAIRE".equals(type) || "CONTRAT_AGRAIRE".equals(typeDocument);
    }
    
    /**
     * Vérifie si le contrat est un certificat foncier
     */
    public boolean estCertificatFoncier() {
        return "CERTIFICAT_FONCIER".equals(typeDocument) || 
               ("CERTIFICAT".equals(type));
    }
    
    /**
     * Génère un code de contrat unique basé sur le type et la région
     */
    public static String genererCodeContrat(String type, String region, String numeroSequence) {
        String prefixe = "CONTRAT_AGRAIRE".equals(type) ? "CA" : 
                        "CERTIFICAT_FONCIER".equals(type) ? "CF" : "CT";
        String regionCode = region != null ? region.substring(0, Math.min(3, region.length())).toUpperCase() : "GEN";
        return String.format("%s-%s-%s", prefixe, regionCode, numeroSequence);
    }
    
    @Override
    public String toString() {
        return "ContratFoncier{" +
                "id='" + id + '\'' +
                ", codeContrat='" + codeContrat + '\'' +
                ", type='" + type + '\'' +
                ", statut='" + statut + '\'' +
                ", region='" + region + '\'' +
                ", typeDocument='" + typeDocument + '\'' +
                '}';
    }
}