# ============================================================
# Variables Terraform - AFOR Blockchain Infrastructure
# ============================================================

# Région AWS
variable "aws_region" {
  description = "Région AWS pour le déploiement"
  type        = string
  default     = "us-east-1"
}

# Environnement
variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"
  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "L'environnement doit être dev, staging ou production."
  }
}

# VPC et Réseau
variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Zones de disponibilité AWS"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks pour les subnets publics"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks pour les subnets privés"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
}

# Instances EC2
variable "peer_instance_type" {
  description = "Type d'instance EC2 pour les peers"
  type        = string
  default     = "t3.large"
}

variable "orderer_instance_type" {
  description = "Type d'instance EC2 pour l'orderer"
  type        = string
  default     = "t3.xlarge"
}

variable "ubuntu_ami_id" {
  description = "AMI ID Ubuntu 22.04 LTS (à adapter selon votre région)"
  type        = string
  # Ubuntu 22.04 LTS dans us-east-1 (vérifier la dernière version)
  default     = "ami-0c7217cdde317cfec"
}

variable "key_name" {
  description = "Nom de la clé SSH EC2"
  type        = string
  default     = "afor-blockchain-key"
}

# Sécurité
variable "admin_cidr_blocks" {
  description = "CIDR blocks autorisés pour l'accès SSH admin"
  type        = list(string)
  # À remplacer par votre IP publique ou VPN
  default     = ["0.0.0.0/0"]  # ATTENTION: À restreindre en production !
}

# Tags communs
variable "project_tags" {
  description = "Tags communs pour toutes les ressources"
  type        = map(string)
  default = {
    Project     = "AFOR-Blockchain"
    ManagedBy   = "Terraform"
    Country     = "Cote-dIvoire"
    Department  = "AFOR"
  }
}

# Monitoring
variable "enable_detailed_monitoring" {
  description = "Activer le monitoring détaillé CloudWatch"
  type        = bool
  default     = true
}

# Backup
variable "backup_retention_days" {
  description = "Nombre de jours de rétention des backups"
  type        = number
  default     = 30
}
