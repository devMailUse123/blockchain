#!/bin/bash
# ============================================================
# Script de Configuration du Backend Terraform
# Crée le bucket S3 et la table DynamoDB pour l'état Terraform
# ============================================================

set -euo pipefail

# Variables
BUCKET_NAME="afor-blockchain-terraform-state"
DYNAMODB_TABLE="afor-blockchain-terraform-locks"
AWS_REGION="${AWS_REGION:-us-east-1}"

# Couleurs pour l'output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Configuration du Backend Terraform"
echo "========================================="
echo ""

# Vérifier que AWS CLI est installé
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI n'est pas installé${NC}"
    echo "Installer avec: pip install awscli"
    exit 1
fi

# Vérifier les credentials AWS
echo -e "${YELLOW}🔍 Vérification des credentials AWS...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ Credentials AWS non configurés${NC}"
    echo "Configurer avec: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo -e "${GREEN}✅ Connecté au compte AWS: $ACCOUNT_ID${NC}"
echo ""

# Créer le bucket S3
echo -e "${YELLOW}📦 Création du bucket S3: $BUCKET_NAME...${NC}"

if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    # Le bucket n'existe pas, le créer
    if [ "$AWS_REGION" = "us-east-1" ]; then
        # us-east-1 ne nécessite pas LocationConstraint
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION"
    else
        # Autres régions nécessitent LocationConstraint
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
    
    echo -e "${GREEN}✅ Bucket S3 créé: $BUCKET_NAME${NC}"
else
    echo -e "${GREEN}✅ Bucket S3 existe déjà: $BUCKET_NAME${NC}"
fi

# Activer le versioning
echo -e "${YELLOW}🔄 Activation du versioning...${NC}"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

echo -e "${GREEN}✅ Versioning activé${NC}"

# Activer le chiffrement
echo -e "${YELLOW}🔒 Activation du chiffrement...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            },
            "BucketKeyEnabled": true
        }]
    }'

echo -e "${GREEN}✅ Chiffrement AES256 activé${NC}"

# Bloquer l'accès public
echo -e "${YELLOW}🛡️  Blocage de l'accès public...${NC}"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,\
        IgnorePublicAcls=true,\
        BlockPublicPolicy=true,\
        RestrictPublicBuckets=true

echo -e "${GREEN}✅ Accès public bloqué${NC}"

# Configurer le lifecycle policy (optionnel)
echo -e "${YELLOW}♻️  Configuration du lifecycle policy...${NC}"
aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
        "Rules": [{
            "Id": "DeleteOldVersions",
            "Status": "Enabled",
            "NoncurrentVersionExpiration": {
                "NoncurrentDays": 90
            }
        }]
    }'

echo -e "${GREEN}✅ Lifecycle policy configuré (suppression des anciennes versions après 90 jours)${NC}"

# Créer la table DynamoDB
echo ""
echo -e "${YELLOW}🗄️  Création de la table DynamoDB: $DYNAMODB_TABLE...${NC}"

if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" &> /dev/null; then
    echo -e "${GREEN}✅ Table DynamoDB existe déjà: $DYNAMODB_TABLE${NC}"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$AWS_REGION" \
        --tags Key=Project,Value=afor-blockchain Key=ManagedBy,Value=terraform
    
    echo -e "${GREEN}✅ Table DynamoDB créée: $DYNAMODB_TABLE${NC}"
    
    # Attendre que la table soit active
    echo -e "${YELLOW}⏳ Attente de l'activation de la table...${NC}"
    aws dynamodb wait table-exists --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION"
    echo -e "${GREEN}✅ Table active${NC}"
fi

# Activer le Point-in-Time Recovery pour DynamoDB
echo -e "${YELLOW}💾 Activation du Point-in-Time Recovery...${NC}"
aws dynamodb update-continuous-backups \
    --table-name "$DYNAMODB_TABLE" \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
    --region "$AWS_REGION"

echo -e "${GREEN}✅ Point-in-Time Recovery activé${NC}"

# Résumé
echo ""
echo "========================================="
echo -e "${GREEN}✅ Configuration du backend terminée !${NC}"
echo "========================================="
echo ""
echo "📋 Résumé:"
echo "  - Bucket S3: $BUCKET_NAME"
echo "  - Région: $AWS_REGION"
echo "  - Versioning: Activé"
echo "  - Chiffrement: AES256"
echo "  - Accès public: Bloqué"
echo "  - Table DynamoDB: $DYNAMODB_TABLE"
echo "  - PITR: Activé"
echo ""
echo "🚀 Prochaines étapes:"
echo "  1. cd ../terraform"
echo "  2. terraform init"
echo "  3. terraform plan"
echo "  4. terraform apply"
echo ""
