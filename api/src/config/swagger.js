const swaggerJsdoc = require('swagger-jsdoc');

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'API Blockchain AFOR - Sécurisation Foncière',
      version: '1.0.0',
      description: `
API REST pour communiquer avec le réseau Hyperledger Fabric de sécurisation foncière rurale en Côte d'Ivoire.

## Fonctionnalités

- Gestion complète des contrats fonciers (CRUD)
- Gestion des utilisateurs
- Recherche avancée de contrats
- Historique des transactions blockchain
- Health checks du système

## Architecture

Cette API communique avec un réseau Hyperledger Fabric 3.1.1 comprenant:
- 3 organisations: AFOR, CVGFR, PREFET
- 1 canal applicatif: contrat-agraire
- Chaincode Java v4.0

## Authentification

**🔐 Authentification Keycloak JWT**

Cette API utilise Keycloak pour l'authentification. Pour accéder aux endpoints protégés:

1. Obtenez un token JWT depuis votre serveur Keycloak
2. Dans Swagger UI, cliquez sur le bouton **Authorize** 🔓
3. Entrez votre token dans le format: \`Bearer <votre_token>\`
4. Cliquez sur **Authorize** puis **Close**

**Exemple d'en-tête:**
\`\`\`
Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
\`\`\`

**Rôles disponibles:**
- \`afor-admin\`: Administrateur AFOR (accès complet)
- \`afor-agent\`: Agent AFOR (lecture/écriture)
- \`cvgfr-president\`: Président CVGFR (validation contrats)
- \`prefet\`: Préfet (approbation finale)
      `,
      contact: {
        name: 'AFOR - Agence Foncière Rurale',
        email: 'contact@afor.ci'
      },
      license: {
        name: 'Apache 2.0',
        url: 'https://www.apache.org/licenses/LICENSE-2.0.html'
      }
    },
    servers: [
      {
        url: 'http://localhost:3000',
        description: 'Serveur de développement'
      },
      {
        url: 'https://api.afor.ci',
        description: 'Serveur de production'
      }
    ],
    tags: [
      {
        name: 'Health',
        description: 'Endpoints de santé du système'
      },
      {
        name: 'Contrats',
        description: 'Gestion des contrats fonciers'
      },
      {
        name: 'Utilisateurs',
        description: 'Gestion des utilisateurs'
      }
    ],
    security: [
      {
        BearerAuth: []
      }
    ],
    components: {
      securitySchemes: {
        BearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Token JWT obtenu depuis Keycloak. Format: Bearer <token>'
        }
      },
      schemas: {
        ContratAgraire: {
          type: 'object',
          required: ['codeContract', 'type', 'ownerId', 'beneficiaryId', 'terrainId', 'village'],
          properties: {
            codeContract: {
              type: 'string',
              description: 'Code unique du contrat',
              example: 'CA-2024-001'
            },
            type: {
              type: 'string',
              enum: ['VENTE', 'LOCATION', 'PRET', 'DON', 'HERITAGE'],
              description: 'Type de contrat',
              example: 'VENTE'
            },
            ownerId: {
              type: 'string',
              description: 'ID du propriétaire',
              example: 'USER001'
            },
            beneficiaryId: {
              type: 'string',
              description: 'ID du bénéficiaire',
              example: 'USER002'
            },
            terrainId: {
              type: 'string',
              description: 'ID du terrain',
              example: 'TERRAIN001'
            },
            village: {
              type: 'string',
              description: 'Village',
              example: 'Abobo'
            },
            sousPrefecture: {
              type: 'string',
              description: 'Sous-préfecture',
              example: 'Abobo'
            },
            department: {
              type: 'string',
              description: 'Département',
              example: 'Abidjan'
            },
            duration: {
              type: 'integer',
              description: 'Durée du contrat',
              example: 99
            },
            durationUnit: {
              type: 'string',
              enum: ['JOUR', 'MOIS', 'ANNEE', 'ILLIMITE'],
              description: 'Unité de durée',
              example: 'ANNEE'
            },
            rent: {
              type: 'number',
              description: 'Montant du loyer',
              example: 50000
            },
            rentTimeUnit: {
              type: 'string',
              enum: ['JOUR', 'MOIS', 'ANNEE'],
              description: 'Unité de temps du loyer',
              example: 'MOIS'
            },
            rentPeriod: {
              type: 'integer',
              description: 'Période de paiement du loyer',
              example: 1
            },
            usagesAutorises: {
              type: 'array',
              items: {
                type: 'string'
              },
              description: 'Liste des usages autorisés',
              example: ['HABITATION', 'AGRICULTURE']
            },
            montantVente: {
              type: 'number',
              description: 'Montant de vente (pour type VENTE)',
              example: 5000000
            },
            creationDate: {
              type: 'string',
              format: 'date-time',
              description: 'Date de création du contrat',
              readOnly: true
            },
            version: {
              type: 'integer',
              description: 'Version du contrat',
              readOnly: true
            }
          }
        },
        User: {
          type: 'object',
          required: ['userId', 'nom', 'prenoms'],
          properties: {
            userId: {
              type: 'string',
              description: 'ID unique de l\'utilisateur',
              example: 'USER001'
            },
            nom: {
              type: 'string',
              description: 'Nom de famille',
              example: 'Kouassi'
            },
            prenoms: {
              type: 'string',
              description: 'Prénoms',
              example: 'Jean'
            },
            dateNaissance: {
              type: 'string',
              format: 'date',
              description: 'Date de naissance',
              example: '1980-01-01'
            },
            lieuNaissance: {
              type: 'string',
              description: 'Lieu de naissance',
              example: 'Abidjan'
            },
            typeIdentite: {
              type: 'string',
              enum: ['CNI', 'PASSPORT', 'ATTESTATION'],
              description: 'Type de pièce d\'identité',
              example: 'CNI'
            },
            numeroIdentite: {
              type: 'string',
              description: 'Numéro de pièce d\'identité',
              example: 'CI123456'
            },
            contact: {
              type: 'string',
              description: 'Numéro de téléphone',
              example: '+225 01 02 03 04 05'
            }
          }
        },
        SuccessResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: true
            },
            message: {
              type: 'string',
              example: 'Opération réussie'
            },
            data: {
              type: 'object',
              description: 'Données de la réponse'
            }
          }
        },
        ErrorResponse: {
          type: 'object',
          properties: {
            success: {
              type: 'boolean',
              example: false
            },
            message: {
              type: 'string',
              example: 'Erreur lors de l\'opération'
            },
            error: {
              type: 'string',
              description: 'Détails de l\'erreur'
            }
          }
        },
        HealthResponse: {
          type: 'object',
          properties: {
            status: {
              type: 'string',
              enum: ['UP', 'DOWN'],
              example: 'UP'
            },
            timestamp: {
              type: 'string',
              format: 'date-time',
              example: '2025-10-21T00:00:00.000Z'
            },
            uptime: {
              type: 'number',
              description: 'Temps de fonctionnement en secondes',
              example: 123.45
            },
            environment: {
              type: 'string',
              example: 'development'
            },
            version: {
              type: 'string',
              example: '1.0.0'
            }
          }
        }
      },
      responses: {
        Unauthorized: {
          description: 'Non authentifié - Token manquant ou invalide',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: {
                    type: 'boolean',
                    example: false
                  },
                  error: {
                    type: 'string',
                    example: 'Token d\'authentification manquant'
                  },
                  message: {
                    type: 'string',
                    example: 'Veuillez fournir un token JWT valide'
                  }
                }
              }
            }
          }
        },
        Forbidden: {
          description: 'Accès refusé - Permissions insuffisantes',
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  success: {
                    type: 'boolean',
                    example: false
                  },
                  error: {
                    type: 'string',
                    example: 'Accès refusé'
                  },
                  message: {
                    type: 'string',
                    example: 'Vous n\'avez pas les permissions requises'
                  }
                }
              }
            }
          }
        },
        BadRequest: {
          description: 'Requête invalide',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              }
            }
          }
        },
        NotFound: {
          description: 'Ressource non trouvée',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              }
            }
          }
        },
        InternalError: {
          description: 'Erreur interne du serveur',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              }
            }
          }
        },
        BlockchainError: {
          description: 'Erreur de communication avec la blockchain',
          content: {
            'application/json': {
              schema: {
                $ref: '#/components/schemas/ErrorResponse'
              }
            }
          }
        }
      }
    }
  },
  apis: ['./src/routes/*.js', './src/controllers/*.js']
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
