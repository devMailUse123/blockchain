# 🚀 Guide de Déploiement Terraform - Infrastructure Multi-VM

Ce guide détaille le processus complet de déploiement de l'infrastructure AWS pour le réseau Hyperledger Fabric.

## 📋 Prérequis

### 1. Outils Requis
```bash
# Terraform >= 1.5.0
terraform --version

# AWS CLI v2
aws --version

# Compte AWS avec permissions appropriées
aws sts get-caller-identity
```

### 2. Configuration AWS

**Créer une clé SSH pour les instances EC2:**
```bash
# Générer la paire de clés
aws ec2 create-key-pair \
  --key-name afor-blockchain-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/afor-blockchain-key.pem

# Définir les permissions
chmod 400 ~/.ssh/afor-blockchain-key.pem
```

**Variables d'environnement AWS:**
```bash
export AWS_PROFILE=default  # ou votre profil
export AWS_REGION=us-east-1
```

### 3. Créer le Backend S3 + DynamoDB

**Option 1: Script automatique**
```bash
cd terraform
./scripts/setup-backend.sh
```

**Option 2: Commandes manuelles**
```bash
# Créer le bucket S3 pour l'état Terraform
aws s3api create-bucket \
  --bucket afor-blockchain-terraform-state \
  --region us-east-1

# Activer le versioning
aws s3api put-bucket-versioning \
  --bucket afor-blockchain-terraform-state \
  --versioning-configuration Status=Enabled

# Activer le chiffrement
aws s3api put-bucket-encryption \
  --bucket afor-blockchain-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Bloquer l'accès public
aws s3api put-public-access-block \
  --bucket afor-blockchain-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,\
    IgnorePublicAcls=true,\
    BlockPublicPolicy=true,\
    RestrictPublicBuckets=true

# Créer la table DynamoDB pour le verrouillage
aws dynamodb create-table \
  --table-name afor-blockchain-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 🏗️ Déploiement de l'Infrastructure

### Étape 1: Initialiser Terraform

```bash
cd terraform

# Initialiser Terraform (télécharge les providers)
terraform init

# Vérifier la configuration
terraform validate

# Formatter le code
terraform fmt -recursive
```

### Étape 2: Planifier le Déploiement

```bash
# Créer un plan de déploiement
terraform plan -out=tfplan

# Examiner le plan en détail
terraform show tfplan
```

**Le plan va créer:**
- 1 VPC avec 3 subnets publics + 4 subnets privés
- 3 NAT Gateways (haute disponibilité)
- 4 instances EC2 (3 peers t3.large + 1 orderer t3.xlarge)
- 8 volumes EBS (4 root + 4 data)
- 1 Application Load Balancer
- 1 zone Route53 privée avec 8 enregistrements DNS
- 3 Security Groups
- 1 bucket S3 pour les backups
- 4 CloudWatch Log Groups

**Estimation des coûts mensuels (us-east-1):**
- 3x EC2 t3.large (24/7): ~$150
- 1x EC2 t3.xlarge (24/7): ~$100
- 3x NAT Gateway: ~$100
- EBS Storage (630 GB): ~$65
- ALB: ~$20
- CloudWatch + S3: ~$15
- **Total estimé: ~$450/mois**

### Étape 3: Appliquer le Déploiement

```bash
# Appliquer les changements
terraform apply tfplan

# Ou directement (avec confirmation interactive)
terraform apply

# Sauvegarder les outputs
terraform output -json > outputs.json
```

⏱️ **Durée estimée:** 5-10 minutes

### Étape 4: Vérifier le Déploiement

```bash
# Afficher les outputs
terraform output

# Vérifier les instances EC2
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=afor-blockchain" \
  --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Vérifier le Load Balancer
aws elbv2 describe-load-balancers \
  --names afor-blockchain-api-lb \
  --query 'LoadBalancers[*].[LoadBalancerName,DNSName,State.Code]' \
  --output table

# Vérifier les logs CloudWatch
aws logs describe-log-groups \
  --log-group-name-prefix /aws/ec2/fabric \
  --query 'logGroups[*].[logGroupName,creationTime]' \
  --output table
```

## 🔐 Accès aux Instances

### SSH via IP Privée (depuis un bastion ou VPN)

```bash
# Peer AFOR
ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@10.0.1.10

# Peer CVGFR
ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@10.0.2.10

# Peer PREFET
ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@10.0.3.10

# Orderer
ssh -i ~/.ssh/afor-blockchain-key.pem ubuntu@10.0.4.10
```

### Accès via AWS Systems Manager (Session Manager)

**Pas besoin d'IP publique ou de bastion !**

```bash
# Se connecter au peer AFOR
INSTANCE_ID=$(terraform output -json | jq -r '.peer_afor_instance_id.value')
aws ssm start-session --target $INSTANCE_ID

# Se connecter à l'orderer
ORDERER_ID=$(terraform output -json | jq -r '.orderer_instance_id.value')
aws ssm start-session --target $ORDERER_ID
```

## 🔄 Mises à Jour et Modifications

### Modifier des variables

**Option 1: Fichier terraform.tfvars**
```hcl
# Créer terraform/terraform.tfvars
aws_region          = "us-east-1"
environment         = "production"
peer_instance_type  = "t3.xlarge"  # Augmenter la taille
admin_cidr_blocks   = ["1.2.3.4/32"]  # Restreindre l'accès
```

**Option 2: Ligne de commande**
```bash
terraform apply -var="peer_instance_type=t3.xlarge"
```

### Appliquer les modifications

```bash
# Voir les changements
terraform plan

# Appliquer
terraform apply

# Appliquer uniquement une ressource spécifique
terraform apply -target=module.peer_afor
```

## 📊 Monitoring et Logs

### CloudWatch Logs

```bash
# Suivre les logs en temps réel - Peer AFOR
INSTANCE_ID=$(terraform output -json | jq -r '.peer_afor_instance_id.value')
aws logs tail /aws/ec2/fabric-peer --follow \
  --filter-pattern "$INSTANCE_ID"

# Logs d'installation
aws logs tail /aws/ec2/fabric-peer --follow \
  --filter-pattern "setup"
```

### Métriques CloudWatch

```bash
# CPU du peer AFOR
INSTANCE_ID=$(terraform output -json | jq -r '.peer_afor_instance_id.value')
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value=$INSTANCE_ID \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

## 🛡️ Sécurité

### Restreindre l'accès SSH

```hcl
# Dans terraform.tfvars
admin_cidr_blocks = [
  "203.0.113.10/32",  # IP bureau
  "198.51.100.5/32"   # IP VPN
]
```

### Activer le chiffrement KMS

```hcl
# Dans variables.tf ou terraform.tfvars
enable_kms_encryption = true
kms_key_id           = "arn:aws:kms:us-east-1:ACCOUNT_ID:key/KEY_ID"
```

### Revoir les Security Groups

```bash
# Lister les règles du security group peer
PEER_SG=$(terraform output -json | jq -r '.peer_security_group_id.value')
aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$PEER_SG" \
  --query 'SecurityGroupRules[*].[GroupId,IpProtocol,FromPort,ToPort,CidrIpv4]' \
  --output table
```

## 🧹 Nettoyage et Destruction

### Détruire l'infrastructure

**⚠️ ATTENTION: Cette action est irréversible !**

```bash
# Voir ce qui sera détruit
terraform plan -destroy

# Détruire toutes les ressources
terraform destroy

# Détruire une ressource spécifique
terraform destroy -target=module.peer_prefet

# Forcer la destruction (ne pas demander confirmation)
terraform destroy -auto-approve  # ⚠️ DANGER
```

### Sauvegarder avant destruction

```bash
# Sauvegarder l'état Terraform
aws s3 cp s3://afor-blockchain-terraform-state/production/terraform.tfstate \
  ./terraform.tfstate.backup

# Sauvegarder les outputs
terraform output -json > outputs-final.json

# Créer un snapshot des volumes EBS
AFOR_INSTANCE=$(terraform output -json | jq -r '.peer_afor_instance_id.value')
VOLUMES=$(aws ec2 describe-volumes \
  --filters "Name=attachment.instance-id,Values=$AFOR_INSTANCE" \
  --query 'Volumes[*].VolumeId' --output text)

for vol in $VOLUMES; do
  aws ec2 create-snapshot \
    --volume-id $vol \
    --description "Backup avant destruction - $(date +%Y%m%d)"
done
```

## 📁 Structure des Fichiers Terraform

```
terraform/
├── main.tf                    # Configuration principale
├── variables.tf               # Définitions des variables
├── outputs.tf                 # Outputs exposés
├── backend.tf                 # Configuration backend S3
├── terraform.tfvars           # Valeurs des variables (à créer)
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── security-groups/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── user-data/
    ├── peer-setup.sh          # Script d'init peers
    └── orderer-setup.sh       # Script d'init orderer
```

## 🆘 Dépannage

### Erreur: Backend S3 not initialized

```bash
# Vérifier que le bucket existe
aws s3 ls s3://afor-blockchain-terraform-state

# Si non, le créer
./scripts/setup-backend.sh
```

### Erreur: InvalidKeyPair.NotFound

```bash
# Vérifier la clé
aws ec2 describe-key-pairs --key-names afor-blockchain-key

# La créer si nécessaire
aws ec2 create-key-pair --key-name afor-blockchain-key \
  --query 'KeyMaterial' --output text > ~/.ssh/afor-blockchain-key.pem
chmod 400 ~/.ssh/afor-blockchain-key.pem
```

### Erreur: VPC Limit Exceeded

```bash
# Vérifier les limites
aws ec2 describe-account-attributes \
  --attribute-names max-elastic-ips

# Demander une augmentation via AWS Support
```

### Instance ne démarre pas

```bash
# Vérifier les logs d'initialisation
INSTANCE_ID=$(terraform output -json | jq -r '.peer_afor_instance_id.value')

# Via console-output
aws ec2 get-console-output --instance-id $INSTANCE_ID

# Via CloudWatch Logs
aws logs tail /aws/ec2/fabric-peer --follow \
  --filter-pattern "$INSTANCE_ID/setup"
```

### Terraform state lock

```bash
# Si un déploiement a échoué et le verrou reste actif
terraform force-unlock LOCK_ID

# Trouver le LOCK_ID dans DynamoDB
aws dynamodb scan \
  --table-name afor-blockchain-terraform-locks \
  --query 'Items[*].LockID.S'
```

## 📚 Ressources Additionnelles

- [Documentation Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Hyperledger Fabric Deployment Guide](https://hyperledger-fabric.readthedocs.io/en/latest/deployment_guide_overview.html)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-best-practices.html)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

## 🔗 Prochaines Étapes

Après le déploiement Terraform:

1. ✅ **Ansible**: Déployer les configurations Fabric
2. ✅ **MSP**: Distribuer les certificats aux VMs
3. ✅ **Docker Compose**: Lancer les conteneurs Fabric
4. ✅ **Channel**: Créer et joindre le channel
5. ✅ **Chaincode**: Déployer le chaincode Java
6. ✅ **API**: Déployer l'API REST Node.js
7. ✅ **Monitoring**: Configurer Prometheus/Grafana
8. ✅ **Tests**: Valider le réseau end-to-end

---

**✨ Bon déploiement !**
