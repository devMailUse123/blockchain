# ============================================================
# Terraform Backend Configuration
# État stocké dans S3 avec verrouillage DynamoDB
# ============================================================

terraform {
  backend "s3" {
    bucket         = "afor-blockchain-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "afor-blockchain-terraform-locks"
    
    # Optionnel: Versioning activé sur le bucket S3
    # versioning    = true
    
    # Optionnel: KMS pour chiffrement avancé
    # kms_key_id    = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
  }
}

# Note: Avant d'utiliser ce backend, créer:
# 1. Bucket S3: afor-blockchain-terraform-state
# 2. Table DynamoDB: afor-blockchain-terraform-locks
#    - Partition key: LockID (String)
#
# Commandes AWS CLI:
#
# aws s3api create-bucket \
#   --bucket afor-blockchain-terraform-state \
#   --region us-east-1
#
# aws s3api put-bucket-versioning \
#   --bucket afor-blockchain-terraform-state \
#   --versioning-configuration Status=Enabled
#
# aws s3api put-bucket-encryption \
#   --bucket afor-blockchain-terraform-state \
#   --server-side-encryption-configuration '{
#     "Rules": [{
#       "ApplyServerSideEncryptionByDefault": {
#         "SSEAlgorithm": "AES256"
#       }
#     }]
#   }'
#
# aws dynamodb create-table \
#   --table-name afor-blockchain-terraform-locks \
#   --attribute-definitions AttributeName=LockID,AttributeType=S \
#   --key-schema AttributeName=LockID,KeyType=HASH \
#   --billing-mode PAY_PER_REQUEST \
#   --region us-east-1
