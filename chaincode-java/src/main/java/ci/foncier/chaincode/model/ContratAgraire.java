package ci.foncier.chaincode.model;

import com.fasterxml.jackson.annotation.JsonProperty;
import org.hyperledger.fabric.contract.annotation.DataType;
import org.hyperledger.fabric.contract.annotation.Property;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

@DataType()
public class ContratAgraire {

    @Property()
    private String id;

    @Property()
    private String uuid;

    @Property()
    private String codeContract;

    @Property()
    private Person owner;

    @Property()
    private Person beneficiary;

    @Property()
    private Terrain terrain;

    @Property()
    private int isNewContract;

    @Property()
    private LocalDateTime oldContractDate;

    @Property()
    private LocalDateTime creationDate;

    @Property()
    private String type;

    @Property()
    private String version;

    @Property()
    private String variation;

    @Property()
    private String region;

    @Property()
    private String department;

    @Property()
    private String sousPrefecture;

    @Property()
    private String village;

    @Property()
    private int ownerId;

    @Property()
    private int beneficiaryId;

    @Property()
    private int terrainId;

    // Loyer et paiement
    @Property()
    private String rentRevision;

    @Property()
    private String rent;

    @Property()
    private String rentTimeUnit;

    @Property()
    private String rentDate;

    @Property()
    private int rentIsNature;

    @Property()
    private String rentIsNatureDetails;

    @Property()
    private int rentIsEspece;

    @Property()
    private String rentIsEspeceDetails;

    @Property()
    private String rentPeriod;

    @Property()
    private String rentPayedBy;

    // Obligations
    @Property()
    private int hasObligationVivriere;

    @Property()
    private String hasObligationVivriereDetails;

    @Property()
    private int hasObligationPerenne;

    @Property()
    private String hasObligationPerenneDetails;

    @Property()
    private String hasObligationAutreActivite;

    @Property()
    private String hasObligationAutreActiviteDetails;

    // Activités
    @Property()
    private int hasActiviteAssocie;

    @Property()
    private int hasActiviteAssocieLegume;

    @Property()
    private int hasActiviteAssocieVivriere;

    // Autorisations familiales
    @Property()
    private int hasFamilyAuthorization;

    @Property()
    private int hasFamilyAuthorizationLivraison;

    @Property()
    private int hasFamilyAuthorizationVente;

    // Contrepartie
    @Property()
    private int contrepartie;

    @Property()
    private String contrepartiePrime;

    @Property()
    private String contrepartiePrimeAnnuelle;

    @Property()
    private String contrepartiePrimeAnnuelleDetails;

    @Property()
    private int hasPrime;

    @Property()
    private String prime;

    // Détenteur
    @Property()
    private int isOwnerDetenteurDroitFoncier;

    @Property()
    private int isDetenteurDroitFoncier;

    @Property()
    private int hasRent;

    // Récolte
    @Property()
    private String recoltePaiementPercent;

    @Property()
    private String recoltePaiementType;

    @Property()
    private String recoltePaiement;

    @Property()
    private String recoltePaiementDetails;

    // Durée et usages
    @Property()
    private String duration;

    @Property()
    private String durationUnit;

    @Property()
    private String usagesAutorises;

    @Property()
    private String ownerObligations;

    @Property()
    private String beneficiaryObligations;

    // Partage
    @Property()
    private String partageDelay;

    @Property()
    private int partageIsAfterDelay;

    @Property()
    private String delaiTravaux;

    @Property()
    private String delaiTravauxUnit;

    @Property()
    private String dateSignaturePlanterPartage;

    // Montants
    @Property()
    private String montantPret;

    @Property()
    private String montantVente;

    @Property()
    private String paiementTotalAvant;

    // Détails planter/partager
    @Property()
    private String detenteurObligations;

    @Property()
    private String planterPartagerOwnerPercent;

    @Property()
    private String planterPartagerBeneficiaryPercent;

    @Property()
    private String planterPartagerPartageOwnerPercent;

    @Property()
    private String planterPartagerPartageOtherDetails;

    // Signataires
    @Property()
    private List<ContractSignatory> contractSignatory;

    public ContratAgraire() {
        this.contractSignatory = new ArrayList<>();
    }

    // Constructor avec paramètres principaux
    public ContratAgraire(
            @JsonProperty("id") String id,
            @JsonProperty("uuid") String uuid,
            @JsonProperty("codeContract") String codeContract,
            @JsonProperty("owner") Person owner,
            @JsonProperty("beneficiary") Person beneficiary,
            @JsonProperty("terrain") Terrain terrain,
            @JsonProperty("type") String type,
            @JsonProperty("region") String region,
            @JsonProperty("village") String village) {
        this.id = id;
        this.uuid = uuid;
        this.codeContract = codeContract;
        this.owner = owner;
        this.beneficiary = beneficiary;
        this.terrain = terrain;
        this.type = type;
        this.region = region;
        this.village = village;
        this.creationDate = LocalDateTime.now();
        this.contractSignatory = new ArrayList<>();
    }

    // Getters et Setters (tous les champs)
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getUuid() { return uuid; }
    public void setUuid(String uuid) { this.uuid = uuid; }

    public String getCodeContract() { return codeContract; }
    public void setCodeContract(String codeContract) { this.codeContract = codeContract; }

    public Person getOwner() { return owner; }
    public void setOwner(Person owner) { this.owner = owner; }

    public Person getBeneficiary() { return beneficiary; }
    public void setBeneficiary(Person beneficiary) { this.beneficiary = beneficiary; }

    public Terrain getTerrain() { return terrain; }
    public void setTerrain(Terrain terrain) { this.terrain = terrain; }

    public int getIsNewContract() { return isNewContract; }
    public void setIsNewContract(int isNewContract) { this.isNewContract = isNewContract; }

    public LocalDateTime getOldContractDate() { return oldContractDate; }
    public void setOldContractDate(LocalDateTime oldContractDate) { this.oldContractDate = oldContractDate; }

    public LocalDateTime getCreationDate() { return creationDate; }
    public void setCreationDate(LocalDateTime creationDate) { this.creationDate = creationDate; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getVersion() { return version; }
    public void setVersion(String version) { this.version = version; }

    public String getVariation() { return variation; }
    public void setVariation(String variation) { this.variation = variation; }

    public String getRegion() { return region; }
    public void setRegion(String region) { this.region = region; }

    public String getDepartment() { return department; }
    public void setDepartment(String department) { this.department = department; }

    public String getSousPrefecture() { return sousPrefecture; }
    public void setSousPrefecture(String sousPrefecture) { this.sousPrefecture = sousPrefecture; }

    public String getVillage() { return village; }
    public void setVillage(String village) { this.village = village; }

    public int getOwnerId() { return ownerId; }
    public void setOwnerId(int ownerId) { this.ownerId = ownerId; }

    public int getBeneficiaryId() { return beneficiaryId; }
    public void setBeneficiaryId(int beneficiaryId) { this.beneficiaryId = beneficiaryId; }

    public int getTerrainId() { return terrainId; }
    public void setTerrainId(int terrainId) { this.terrainId = terrainId; }

    public String getRentRevision() { return rentRevision; }
    public void setRentRevision(String rentRevision) { this.rentRevision = rentRevision; }

    public String getRent() { return rent; }
    public void setRent(String rent) { this.rent = rent; }

    public String getRentTimeUnit() { return rentTimeUnit; }
    public void setRentTimeUnit(String rentTimeUnit) { this.rentTimeUnit = rentTimeUnit; }

    public String getRentDate() { return rentDate; }
    public void setRentDate(String rentDate) { this.rentDate = rentDate; }

    public int getRentIsNature() { return rentIsNature; }
    public void setRentIsNature(int rentIsNature) { this.rentIsNature = rentIsNature; }

    public String getRentIsNatureDetails() { return rentIsNatureDetails; }
    public void setRentIsNatureDetails(String rentIsNatureDetails) { this.rentIsNatureDetails = rentIsNatureDetails; }

    public int getRentIsEspece() { return rentIsEspece; }
    public void setRentIsEspece(int rentIsEspece) { this.rentIsEspece = rentIsEspece; }

    public String getRentIsEspeceDetails() { return rentIsEspeceDetails; }
    public void setRentIsEspeceDetails(String rentIsEspeceDetails) { this.rentIsEspeceDetails = rentIsEspeceDetails; }

    public String getRentPeriod() { return rentPeriod; }
    public void setRentPeriod(String rentPeriod) { this.rentPeriod = rentPeriod; }

    public String getRentPayedBy() { return rentPayedBy; }
    public void setRentPayedBy(String rentPayedBy) { this.rentPayedBy = rentPayedBy; }

    public int getHasObligationVivriere() { return hasObligationVivriere; }
    public void setHasObligationVivriere(int hasObligationVivriere) { this.hasObligationVivriere = hasObligationVivriere; }

    public String getHasObligationVivriereDetails() { return hasObligationVivriereDetails; }
    public void setHasObligationVivriereDetails(String hasObligationVivriereDetails) { this.hasObligationVivriereDetails = hasObligationVivriereDetails; }

    public int getHasObligationPerenne() { return hasObligationPerenne; }
    public void setHasObligationPerenne(int hasObligationPerenne) { this.hasObligationPerenne = hasObligationPerenne; }

    public String getHasObligationPerenneDetails() { return hasObligationPerenneDetails; }
    public void setHasObligationPerenneDetails(String hasObligationPerenneDetails) { this.hasObligationPerenneDetails = hasObligationPerenneDetails; }

    public String getHasObligationAutreActivite() { return hasObligationAutreActivite; }
    public void setHasObligationAutreActivite(String hasObligationAutreActivite) { this.hasObligationAutreActivite = hasObligationAutreActivite; }

    public String getHasObligationAutreActiviteDetails() { return hasObligationAutreActiviteDetails; }
    public void setHasObligationAutreActiviteDetails(String hasObligationAutreActiviteDetails) { this.hasObligationAutreActiviteDetails = hasObligationAutreActiviteDetails; }

    public int getHasActiviteAssocie() { return hasActiviteAssocie; }
    public void setHasActiviteAssocie(int hasActiviteAssocie) { this.hasActiviteAssocie = hasActiviteAssocie; }

    public int getHasActiviteAssocieLegume() { return hasActiviteAssocieLegume; }
    public void setHasActiviteAssocieLegume(int hasActiviteAssocieLegume) { this.hasActiviteAssocieLegume = hasActiviteAssocieLegume; }

    public int getHasActiviteAssocieVivriere() { return hasActiviteAssocieVivriere; }
    public void setHasActiviteAssocieVivriere(int hasActiviteAssocieVivriere) { this.hasActiviteAssocieVivriere = hasActiviteAssocieVivriere; }

    public int getHasFamilyAuthorization() { return hasFamilyAuthorization; }
    public void setHasFamilyAuthorization(int hasFamilyAuthorization) { this.hasFamilyAuthorization = hasFamilyAuthorization; }

    public int getHasFamilyAuthorizationLivraison() { return hasFamilyAuthorizationLivraison; }
    public void setHasFamilyAuthorizationLivraison(int hasFamilyAuthorizationLivraison) { this.hasFamilyAuthorizationLivraison = hasFamilyAuthorizationLivraison; }

    public int getHasFamilyAuthorizationVente() { return hasFamilyAuthorizationVente; }
    public void setHasFamilyAuthorizationVente(int hasFamilyAuthorizationVente) { this.hasFamilyAuthorizationVente = hasFamilyAuthorizationVente; }

    public int getContrepartie() { return contrepartie; }
    public void setContrepartie(int contrepartie) { this.contrepartie = contrepartie; }

    public String getContrepartiePrime() { return contrepartiePrime; }
    public void setContrepartiePrime(String contrepartiePrime) { this.contrepartiePrime = contrepartiePrime; }

    public String getContrepartiePrimeAnnuelle() { return contrepartiePrimeAnnuelle; }
    public void setContrepartiePrimeAnnuelle(String contrepartiePrimeAnnuelle) { this.contrepartiePrimeAnnuelle = contrepartiePrimeAnnuelle; }

    public String getContrepartiePrimeAnnuelleDetails() { return contrepartiePrimeAnnuelleDetails; }
    public void setContrepartiePrimeAnnuelleDetails(String contrepartiePrimeAnnuelleDetails) { this.contrepartiePrimeAnnuelleDetails = contrepartiePrimeAnnuelleDetails; }

    public int getHasPrime() { return hasPrime; }
    public void setHasPrime(int hasPrime) { this.hasPrime = hasPrime; }

    public String getPrime() { return prime; }
    public void setPrime(String prime) { this.prime = prime; }

    public int getIsOwnerDetenteurDroitFoncier() { return isOwnerDetenteurDroitFoncier; }
    public void setIsOwnerDetenteurDroitFoncier(int isOwnerDetenteurDroitFoncier) { this.isOwnerDetenteurDroitFoncier = isOwnerDetenteurDroitFoncier; }

    public int getIsDetenteurDroitFoncier() { return isDetenteurDroitFoncier; }
    public void setIsDetenteurDroitFoncier(int isDetenteurDroitFoncier) { this.isDetenteurDroitFoncier = isDetenteurDroitFoncier; }

    public int getHasRent() { return hasRent; }
    public void setHasRent(int hasRent) { this.hasRent = hasRent; }

    public String getRecoltePaiementPercent() { return recoltePaiementPercent; }
    public void setRecoltePaiementPercent(String recoltePaiementPercent) { this.recoltePaiementPercent = recoltePaiementPercent; }

    public String getRecoltePaiementType() { return recoltePaiementType; }
    public void setRecoltePaiementType(String recoltePaiementType) { this.recoltePaiementType = recoltePaiementType; }

    public String getRecoltePaiement() { return recoltePaiement; }
    public void setRecoltePaiement(String recoltePaiement) { this.recoltePaiement = recoltePaiement; }

    public String getRecoltePaiementDetails() { return recoltePaiementDetails; }
    public void setRecoltePaiementDetails(String recoltePaiementDetails) { this.recoltePaiementDetails = recoltePaiementDetails; }

    public String getDuration() { return duration; }
    public void setDuration(String duration) { this.duration = duration; }

    public String getDurationUnit() { return durationUnit; }
    public void setDurationUnit(String durationUnit) { this.durationUnit = durationUnit; }

    public String getUsagesAutorises() { return usagesAutorises; }
    public void setUsagesAutorises(String usagesAutorises) { this.usagesAutorises = usagesAutorises; }

    public String getOwnerObligations() { return ownerObligations; }
    public void setOwnerObligations(String ownerObligations) { this.ownerObligations = ownerObligations; }

    public String getBeneficiaryObligations() { return beneficiaryObligations; }
    public void setBeneficiaryObligations(String beneficiaryObligations) { this.beneficiaryObligations = beneficiaryObligations; }

    public String getPartageDelay() { return partageDelay; }
    public void setPartageDelay(String partageDelay) { this.partageDelay = partageDelay; }

    public int getPartageIsAfterDelay() { return partageIsAfterDelay; }
    public void setPartageIsAfterDelay(int partageIsAfterDelay) { this.partageIsAfterDelay = partageIsAfterDelay; }

    public String getDelaiTravaux() { return delaiTravaux; }
    public void setDelaiTravaux(String delaiTravaux) { this.delaiTravaux = delaiTravaux; }

    public String getDelaiTravauxUnit() { return delaiTravauxUnit; }
    public void setDelaiTravauxUnit(String delaiTravauxUnit) { this.delaiTravauxUnit = delaiTravauxUnit; }

    public String getDateSignaturePlanterPartage() { return dateSignaturePlanterPartage; }
    public void setDateSignaturePlanterPartage(String dateSignaturePlanterPartage) { this.dateSignaturePlanterPartage = dateSignaturePlanterPartage; }

    public String getMontantPret() { return montantPret; }
    public void setMontantPret(String montantPret) { this.montantPret = montantPret; }

    public String getMontantVente() { return montantVente; }
    public void setMontantVente(String montantVente) { this.montantVente = montantVente; }

    public String getPaiementTotalAvant() { return paiementTotalAvant; }
    public void setPaiementTotalAvant(String paiementTotalAvant) { this.paiementTotalAvant = paiementTotalAvant; }

    public String getDetenteurObligations() { return detenteurObligations; }
    public void setDetenteurObligations(String detenteurObligations) { this.detenteurObligations = detenteurObligations; }

    public String getPlanterPartagerOwnerPercent() { return planterPartagerOwnerPercent; }
    public void setPlanterPartagerOwnerPercent(String planterPartagerOwnerPercent) { this.planterPartagerOwnerPercent = planterPartagerOwnerPercent; }

    public String getPlanterPartagerBeneficiaryPercent() { return planterPartagerBeneficiaryPercent; }
    public void setPlanterPartagerBeneficiaryPercent(String planterPartagerBeneficiaryPercent) { this.planterPartagerBeneficiaryPercent = planterPartagerBeneficiaryPercent; }

    public String getPlanterPartagerPartageOwnerPercent() { return planterPartagerPartageOwnerPercent; }
    public void setPlanterPartagerPartageOwnerPercent(String planterPartagerPartageOwnerPercent) { this.planterPartagerPartageOwnerPercent = planterPartagerPartageOwnerPercent; }

    public String getPlanterPartagerPartageOtherDetails() { return planterPartagerPartageOtherDetails; }
    public void setPlanterPartagerPartageOtherDetails(String planterPartagerPartageOtherDetails) { this.planterPartagerPartageOtherDetails = planterPartagerPartageOtherDetails; }

    public List<ContractSignatory> getContractSignatory() { return contractSignatory; }
    public void setContractSignatory(List<ContractSignatory> contractSignatory) { this.contractSignatory = contractSignatory; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ContratAgraire that = (ContratAgraire) o;
        return Objects.equals(id, that.id) && Objects.equals(codeContract, that.codeContract);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id, codeContract);
    }

    @Override
    public String toString() {
        return "ContratAgraire{" +
                "id='" + id + '\'' +
                ", codeContract='" + codeContract + '\'' +
                ", type='" + type + '\'' +
                ", region='" + region + '\'' +
                ", village='" + village + '\'' +
                '}';
    }
}
