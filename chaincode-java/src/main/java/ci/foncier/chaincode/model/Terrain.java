package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.util.Objects;

@DataType()
public class Terrain {

    @Property()
    private int id;

    @Property()
    private String localisation;

    @Property()
    private double surface;

    @Property()
    private String cvgfr;

    @Property()
    private String contratPartiel;

    @Property()
    private String certificatFoncier;

    @Property()
    private String certificatFoncierType;

    @Property()
    private String titreFoncier;

    @Property()
    private String statut;

    @Property()
    private String idufci;

    @Property()
    private String natureServitude;

    @Property()
    private String surfaceMethod;

    @Property()
    private String surfaceMeasurment;

    @Property()
    private String croquisDisponible;

    public Terrain() {
    }

    public Terrain(@JsonProperty("id") int id,
                   @JsonProperty("localisation") String localisation,
                   @JsonProperty("surface") double surface,
                   @JsonProperty("cvgfr") String cvgfr,
                   @JsonProperty("contratPartiel") String contratPartiel,
                   @JsonProperty("certificatFoncier") String certificatFoncier,
                   @JsonProperty("certificatFoncierType") String certificatFoncierType,
                   @JsonProperty("titreFoncier") String titreFoncier,
                   @JsonProperty("statut") String statut,
                   @JsonProperty("idufci") String idufci,
                   @JsonProperty("natureServitude") String natureServitude,
                   @JsonProperty("surfaceMethod") String surfaceMethod,
                   @JsonProperty("surfaceMeasurment") String surfaceMeasurment,
                   @JsonProperty("croquisDisponible") String croquisDisponible) {
        this.id = id;
        this.localisation = localisation;
        this.surface = surface;
        this.cvgfr = cvgfr;
        this.contratPartiel = contratPartiel;
        this.certificatFoncier = certificatFoncier;
        this.certificatFoncierType = certificatFoncierType;
        this.titreFoncier = titreFoncier;
        this.statut = statut;
        this.idufci = idufci;
        this.natureServitude = natureServitude;
        this.surfaceMethod = surfaceMethod;
        this.surfaceMeasurment = surfaceMeasurment;
        this.croquisDisponible = croquisDisponible;
    }

    // Getters et Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getLocalisation() { return localisation; }
    public void setLocalisation(String localisation) { this.localisation = localisation; }

    public double getSurface() { return surface; }
    public void setSurface(double surface) { this.surface = surface; }

    public String getCvgfr() { return cvgfr; }
    public void setCvgfr(String cvgfr) { this.cvgfr = cvgfr; }

    public String getContratPartiel() { return contratPartiel; }
    public void setContratPartiel(String contratPartiel) { this.contratPartiel = contratPartiel; }

    public String getCertificatFoncier() { return certificatFoncier; }
    public void setCertificatFoncier(String certificatFoncier) { this.certificatFoncier = certificatFoncier; }

    public String getCertificatFoncierType() { return certificatFoncierType; }
    public void setCertificatFoncierType(String certificatFoncierType) { this.certificatFoncierType = certificatFoncierType; }

    public String getTitreFoncier() { return titreFoncier; }
    public void setTitreFoncier(String titreFoncier) { this.titreFoncier = titreFoncier; }

    public String getStatut() { return statut; }
    public void setStatut(String statut) { this.statut = statut; }

    public String getIdufci() { return idufci; }
    public void setIdufci(String idufci) { this.idufci = idufci; }

    public String getNatureServitude() { return natureServitude; }
    public void setNatureServitude(String natureServitude) { this.natureServitude = natureServitude; }

    public String getSurfaceMethod() { return surfaceMethod; }
    public void setSurfaceMethod(String surfaceMethod) { this.surfaceMethod = surfaceMethod; }

    public String getSurfaceMeasurment() { return surfaceMeasurment; }
    public void setSurfaceMeasurment(String surfaceMeasurment) { this.surfaceMeasurment = surfaceMeasurment; }

    public String getCroquisDisponible() { return croquisDisponible; }
    public void setCroquisDisponible(String croquisDisponible) { this.croquisDisponible = croquisDisponible; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Terrain terrain = (Terrain) o;
        return id == terrain.id;
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
