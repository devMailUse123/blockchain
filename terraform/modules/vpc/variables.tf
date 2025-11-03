# ============================================================
# Variables - Module VPC
# ============================================================

variable "name_prefix" {
  description = "Préfixe pour les noms des ressources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
}

variable "availability_zones" {
  description = "Liste des zones de disponibilité"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks pour les subnets publics"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks pour les subnets privés"
  type        = list(string)
}

variable "enable_dns_hostnames" {
  description = "Activer les hostnames DNS"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Activer le support DNS"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Créer des NAT Gateways"
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "Activer les VPC Flow Logs"
  type        = bool
  default     = false
}

variable "create_network_acls" {
  description = "Créer des Network ACLs"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
