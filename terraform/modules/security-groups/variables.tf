# ============================================================
# Variables - Module Security Groups
# ============================================================

variable "name_prefix" {
  description = "Préfixe pour les noms des security groups"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks autorisés pour l'accès admin (SSH, monitoring)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "api_allowed_cidrs" {
  description = "CIDR blocks autorisés pour l'API REST"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "alb_allowed_cidrs" {
  description = "CIDR blocks autorisés pour l'ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_ssh_access" {
  description = "Autoriser l'accès SSH"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
