# ============================================================
# Variables - Module EC2
# ============================================================

variable "name" {
  description = "Nom de l'instance EC2"
  type        = string
}

variable "role" {
  description = "Rôle de l'instance (peer, orderer, ca)"
  type        = string
}

variable "ami_id" {
  description = "ID de l'AMI à utiliser"
  type        = string
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
}

variable "key_name" {
  description = "Nom de la clé SSH"
  type        = string
}

variable "subnet_id" {
  description = "ID du subnet"
  type        = string
}

variable "security_group_ids" {
  description = "Liste des IDs des security groups"
  type        = list(string)
}

variable "private_ip" {
  description = "Adresse IP privée"
  type        = string
  default     = null
}

variable "associate_public_ip" {
  description = "Associer une IP publique (Elastic IP)"
  type        = bool
  default     = false
}

# Volumes
variable "root_volume_type" {
  description = "Type du volume root (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "root_volume_size" {
  description = "Taille du volume root en GB"
  type        = number
  default     = 30
}

variable "data_volume_size" {
  description = "Taille du volume de données en GB (0 pour désactiver)"
  type        = number
  default     = 100
}

variable "data_volume_type" {
  description = "Type du volume de données (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"
}

variable "data_volume_device" {
  description = "Device name pour le volume de données"
  type        = string
  default     = "/dev/sdf"
}

variable "data_volume_iops" {
  description = "IOPS pour le volume de données (io1/io2)"
  type        = number
  default     = null
}

variable "data_volume_throughput" {
  description = "Throughput pour le volume de données en MB/s (gp3)"
  type        = number
  default     = 125
}

# Sécurité
variable "enable_encryption" {
  description = "Activer le chiffrement EBS"
  type        = bool
  default     = true
}

# Monitoring
variable "enable_detailed_monitoring" {
  description = "Activer le monitoring détaillé CloudWatch"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_alarms" {
  description = "Créer des alarmes CloudWatch"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "ARNs des actions pour les alarmes"
  type        = list(string)
  default     = []
}

# Backups
variable "enable_s3_backup" {
  description = "Activer les backups S3"
  type        = bool
  default     = false
}

variable "backup_bucket_arn" {
  description = "ARN du bucket S3 pour les backups"
  type        = string
  default     = ""
}

variable "enable_ebs_snapshots" {
  description = "Activer les snapshots EBS automatiques"
  type        = bool
  default     = false
}

variable "snapshot_retention_days" {
  description = "Nombre de jours de rétention des snapshots"
  type        = number
  default     = 7
}

# User Data
variable "user_data" {
  description = "Script User Data pour l'initialisation"
  type        = string
  default     = ""
}

variable "user_data_replace_on_change" {
  description = "Remplacer l'instance si le user_data change"
  type        = bool
  default     = false
}

# Tags
variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
