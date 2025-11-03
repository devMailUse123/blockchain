# ============================================================
# Outputs Terraform - AFOR Blockchain Infrastructure
# ============================================================

# VPC Outputs
output "vpc_id" {
  description = "ID du VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block du VPC"
  value       = module.vpc.vpc_cidr
}

output "private_subnet_ids" {
  description = "IDs des subnets privés"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs des subnets publics"
  value       = module.vpc.public_subnet_ids
}

# EC2 Instances - Peers
output "peer_afor_instance_id" {
  description = "ID de l'instance EC2 AFOR"
  value       = module.peer_afor.instance_id
}

output "peer_afor_private_ip" {
  description = "IP privée de l'instance AFOR"
  value       = module.peer_afor.private_ip
}

output "peer_cvgfr_instance_id" {
  description = "ID de l'instance EC2 CVGFR"
  value       = module.peer_cvgfr.instance_id
}

output "peer_cvgfr_private_ip" {
  description = "IP privée de l'instance CVGFR"
  value       = module.peer_cvgfr.private_ip
}

output "peer_prefet_instance_id" {
  description = "ID de l'instance EC2 PREFET"
  value       = module.peer_prefet.instance_id
}

output "peer_prefet_private_ip" {
  description = "IP privée de l'instance PREFET"
  value       = module.peer_prefet.private_ip
}

# EC2 Instance - Orderer
output "orderer_instance_id" {
  description = "ID de l'instance EC2 Orderer"
  value       = module.orderer.instance_id
}

output "orderer_private_ip" {
  description = "IP privée de l'instance Orderer"
  value       = module.orderer.private_ip
}

# DNS
output "route53_zone_id" {
  description = "ID de la zone Route53 privée"
  value       = aws_route53_zone.private.zone_id
}

output "dns_nameservers" {
  description = "Serveurs DNS de la zone privée"
  value       = aws_route53_zone.private.name_servers
}

# Load Balancer
output "alb_dns_name" {
  description = "DNS du Load Balancer pour les APIs"
  value       = aws_lb.api.dns_name
}

output "alb_arn" {
  description = "ARN du Load Balancer"
  value       = aws_lb.api.arn
}

# S3 Backup Bucket
output "backup_bucket_name" {
  description = "Nom du bucket S3 pour les backups"
  value       = aws_s3_bucket.backups.id
}

output "backup_bucket_arn" {
  description = "ARN du bucket S3 pour les backups"
  value       = aws_s3_bucket.backups.arn
}

# Security Groups
output "peer_security_group_id" {
  description = "ID du security group pour les peers"
  value       = module.security_groups.peer_sg_id
}

output "orderer_security_group_id" {
  description = "ID du security group pour l'orderer"
  value       = module.security_groups.orderer_sg_id
}

# Connexion SSH
output "ssh_connection_commands" {
  description = "Commandes SSH pour se connecter aux instances"
  value = {
    afor    = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.peer_afor.private_ip}"
    cvgfr   = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.peer_cvgfr.private_ip}"
    prefet  = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.peer_prefet.private_ip}"
    orderer = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${module.orderer.private_ip}"
  }
}

# Résumé du déploiement
output "deployment_summary" {
  description = "Résumé du déploiement"
  value = {
    environment = var.environment
    region      = var.aws_region
    vpc_id      = module.vpc.vpc_id
    instances = {
      afor = {
        id         = module.peer_afor.instance_id
        private_ip = module.peer_afor.private_ip
        dns        = "peer0.afor.foncier.ci"
      }
      cvgfr = {
        id         = module.peer_cvgfr.instance_id
        private_ip = module.peer_cvgfr.private_ip
        dns        = "peer0.cvgfr.foncier.ci"
      }
      prefet = {
        id         = module.peer_prefet.instance_id
        private_ip = module.peer_prefet.private_ip
        dns        = "peer0.prefet.foncier.ci"
      }
      orderer = {
        id         = module.orderer.instance_id
        private_ip = module.orderer.private_ip
        dns        = "orderer.foncier.ci"
      }
    }
    api_endpoint = "http://${aws_lb.api.dns_name}"
  }
}
