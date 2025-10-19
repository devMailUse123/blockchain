package gn.foncier.api.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Pattern;
import javax.validation.constraints.Size;

/**
 * Représente une personne physique ou morale dans le système foncier
 */
public class Personne {
    
    @NotBlank(message = "Le nom est obligatoire")
    @Size(max = 100, message = "Le nom ne peut pas dépasser 100 caractères")
    private String nom;
    
    @Size(max = 100, message = "Les prénoms ne peuvent pas dépasser 100 caractères")
    private String prenoms;
    
    @JsonProperty("dateNaissance")
    private String dateNaissance;
    
    @JsonProperty("lieuNaissance")
    @Size(max = 100, message = "Le lieu de naissance ne peut pas dépasser 100 caractères")
    private String lieuNaissance;
    
    @JsonProperty("nomPere")
    @Size(max = 100, message = "Le nom du père ne peut pas dépasser 100 caractères")
    private String nomPere;
    
    @JsonProperty("nomMere")
    @Size(max = 100, message = "Le nom de la mère ne peut pas dépasser 100 caractères")
    private String nomMere;
    
    @NotBlank(message = "Le type de pièce d'identité est obligatoire")
    @Pattern(regexp = "CNI|PASSEPORT|PERMIS", message = "Type de pièce invalide")
    @JsonProperty("typePieceIdentite")
    private String typePieceIdentite;
    
    @NotBlank(message = "Le numéro de pièce est obligatoire")
    @Size(max = 50, message = "Le numéro de pièce ne peut pas dépasser 50 caractères")
    @JsonProperty("numeroPiece")
    private String numeroPiece;
    
    @JsonProperty("dateDelivrance")
    private String dateDelivrance;
    
    @Size(max = 20, message = "Le téléphone ne peut pas dépasser 20 caractères")
    private String telephone;
    
    @Size(max = 200, message = "L'adresse ne peut pas dépasser 200 caractères")
    private String adresse;
    
    @Pattern(regexp = "M|F|", message = "Genre invalide (M ou F)")
    private String genre;
    
    @NotBlank(message = "Le type de personne est obligatoire")
    @Pattern(regexp = "PHYSIQUE|MORALE", message = "Type de personne invalide")
    @JsonProperty("typePersonne")
    private String typePersonne;
    
    // Constructeurs
    public Personne() {}
    
    public Personne(String nom, String prenoms, String typePieceIdentite, 
                   String numeroPiece, String typePersonne) {
        this.nom = nom;
        this.prenoms = prenoms;
        this.typePieceIdentite = typePieceIdentite;
        this.numeroPiece = numeroPiece;
        this.typePersonne = typePersonne;
    }
    
    // Getters et Setters
    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }
    
    public String getPrenoms() { return prenoms; }
    public void setPrenoms(String prenoms) { this.prenoms = prenoms; }
    
    public String getDateNaissance() { return dateNaissance; }
    public void setDateNaissance(String dateNaissance) { this.dateNaissance = dateNaissance; }
    
    public String getLieuNaissance() { return lieuNaissance; }
    public void setLieuNaissance(String lieuNaissance) { this.lieuNaissance = lieuNaissance; }
    
    public String getNomPere() { return nomPere; }
    public void setNomPere(String nomPere) { this.nomPere = nomPere; }
    
    public String getNomMere() { return nomMere; }
    public void setNomMere(String nomMere) { this.nomMere = nomMere; }
    
    public String getTypePieceIdentite() { return typePieceIdentite; }
    public void setTypePieceIdentite(String typePieceIdentite) { this.typePieceIdentite = typePieceIdentite; }
    
    public String getNumeroPiece() { return numeroPiece; }
    public void setNumeroPiece(String numeroPiece) { this.numeroPiece = numeroPiece; }
    
    public String getDateDelivrance() { return dateDelivrance; }
    public void setDateDelivrance(String dateDelivrance) { this.dateDelivrance = dateDelivrance; }
    
    public String getTelephone() { return telephone; }
    public void setTelephone(String telephone) { this.telephone = telephone; }
    
    public String getAdresse() { return adresse; }
    public void setAdresse(String adresse) { this.adresse = adresse; }
    
    public String getGenre() { return genre; }
    public void setGenre(String genre) { this.genre = genre; }
    
    public String getTypePersonne() { return typePersonne; }
    public void setTypePersonne(String typePersonne) { this.typePersonne = typePersonne; }
    
    @Override
    public String toString() {
        return "Personne{" +
                "nom='" + nom + '\'' +
                ", prenoms='" + prenoms + '\'' +
                ", typePieceIdentite='" + typePieceIdentite + '\'' +
                ", numeroPiece='" + numeroPiece + '\'' +
                ", typePersonne='" + typePersonne + '\'' +
                '}';
    }
}