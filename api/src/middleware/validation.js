const Joi = require('joi');

/**
 * Schéma de validation pour un contrat foncier
 */
const contractSchema = Joi.object({
  codeContract: Joi.string().required().min(3).max(50),
  type: Joi.string().required().valid('VENTE', 'LOCATION', 'PRET', 'DON', 'HERITAGE'),
  ownerId: Joi.string().required(),
  beneficiaryId: Joi.string().required(),
  terrainId: Joi.string().required(),
  village: Joi.string().required(),
  sousPrefecture: Joi.string().optional(),
  department: Joi.string().optional(),
  duration: Joi.number().integer().min(0).optional(),
  durationUnit: Joi.string().valid('JOUR', 'MOIS', 'ANNEE', 'ILLIMITE').optional(),
  rent: Joi.number().min(0).optional(),
  rentTimeUnit: Joi.string().valid('JOUR', 'MOIS', 'ANNEE').optional(),
  rentPeriod: Joi.number().integer().min(1).optional(),
  rentDate: Joi.string().optional(),
  rentPayedBy: Joi.string().valid('OWNER', 'BENEFICIARY').optional(),
  rentIsEspece: Joi.boolean().optional(),
  rentIsNatureDetails: Joi.string().optional(),
  rentRevision: Joi.boolean().optional(),
  variation: Joi.number().optional(),
  montantVente: Joi.number().min(0).optional(),
  montantPret: Joi.number().min(0).optional(),
  isNewContract: Joi.boolean().optional(),
  oldContractDate: Joi.string().optional(),
  usagesAutorises: Joi.array().items(Joi.string()).optional(),
  ownerObligations: Joi.string().optional(),
  beneficiaryObligations: Joi.string().optional(),
  detenteurObligations: Joi.string().optional(),
  hasObligationVivriere: Joi.boolean().optional(),
  hasObligationVivriereDetails: Joi.string().optional(),
  hasObligationPerenneDetails: Joi.string().optional(),
  hasObligationAutreActivite: Joi.boolean().optional(),
  hasActiviteAssocieVivriere: Joi.boolean().optional(),
  hasFamilyAuthorizationVente: Joi.boolean().optional(),
  recoltePaiement: Joi.boolean().optional(),
  recoltePaiementType: Joi.string().valid('ESPECE', 'NATURE', 'MIXTE').optional(),
  recoltePaiementPercent: Joi.number().min(0).max(100).optional(),
  recoltePaiementDetails: Joi.string().optional(),
  planterPartagerOwnerPercent: Joi.number().min(0).max(100).optional(),
  planterPartagerPartageOwnerPercent: Joi.number().min(0).max(100).optional(),
  partageDelay: Joi.number().integer().min(0).optional(),
  delaiTravaux: Joi.number().integer().min(0).optional(),
  delaiTravauxUnit: Joi.string().valid('JOUR', 'MOIS', 'ANNEE').optional(),
  contrepartiePrime: Joi.boolean().optional(),
  contrepartiePrimeAnnuelleDetails: Joi.string().optional(),
  isOwnerDetenteurDroitFoncier: Joi.boolean().optional(),
  contractSignatory: Joi.string().optional()
});

/**
 * Middleware de validation pour les contrats
 */
const validateContract = (req, res, next) => {
  const { error } = contractSchema.validate(req.body, { abortEarly: false });
  
  if (error) {
    const errors = error.details.map(detail => ({
      field: detail.path.join('.'),
      message: detail.message
    }));
    
    return res.status(400).json({
      success: false,
      message: 'Validation échouée',
      errors
    });
  }
  
  next();
};

module.exports = {
  validateContract,
  contractSchema
};
