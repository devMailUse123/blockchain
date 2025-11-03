# ============================================================
# Terraform Configuration - Blockchain Foncier AFOR
# Infrastructure AWS pour 4 VMs (3 Organisations + 1 Orderer)
# ============================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Backend S3 pour stocker l'état Terraform (recommandé pour production)
  backend "s3" {
    bucket         = "afor-blockchain-terraform-state"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "afor-blockchain-terraform-locks"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "AFOR-Blockchain"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "AFOR-CI"
    }
  }
}

# ============================================================
# VPC et Réseau
# ============================================================

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  availability_zones   = var.availability_zones
  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ============================================================
# Security Groups
# ============================================================

module "security_groups" {
  source = "./modules/security-groups"
  
  vpc_id      = module.vpc.vpc_id
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  
  # IP autorisées pour SSH (votre IP ou VPN)
  admin_cidr_blocks = var.admin_cidr_blocks
}

# ============================================================
# EC2 Instances - Peers (AFOR, CVGFR, PREFET)
# ============================================================

module "peer_afor" {
  source = "./modules/ec2"
  
  name                   = "peer-afor"
  environment            = var.environment
  instance_type          = var.peer_instance_type
  ami_id                 = var.ubuntu_ami_id
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [
    module.security_groups.peer_sg_id,
    module.security_groups.common_sg_id
  ]
  
  key_name               = var.key_name
  private_ip             = "10.0.1.10"
  
  root_volume_size       = 30
  data_volume_size       = 100
  enable_monitoring      = true
  
  user_data = templatefile("${path.module}/user-data/peer-setup.sh", {
    organization = "afor"
    hostname     = "peer0.afor.foncier.ci"
  })
  
  tags = {
    Organization = "AFOR"
    Role         = "Peer"
    Name         = "VM1-Peer-AFOR"
  }
}

module "peer_cvgfr" {
  source = "./modules/ec2"
  
  name                   = "peer-cvgfr"
  environment            = var.environment
  instance_type          = var.peer_instance_type
  ami_id                 = var.ubuntu_ami_id
  subnet_id              = module.vpc.private_subnet_ids[1]
  vpc_security_group_ids = [
    module.security_groups.peer_sg_id,
    module.security_groups.common_sg_id
  ]
  
  key_name               = var.key_name
  private_ip             = "10.0.2.10"
  
  root_volume_size       = 30
  data_volume_size       = 100
  enable_monitoring      = true
  
  user_data = templatefile("${path.module}/user-data/peer-setup.sh", {
    organization = "cvgfr"
    hostname     = "peer0.cvgfr.foncier.ci"
  })
  
  tags = {
    Organization = "CVGFR"
    Role         = "Peer"
    Name         = "VM2-Peer-CVGFR"
  }
}

module "peer_prefet" {
  source = "./modules/ec2"
  
  name                   = "peer-prefet"
  environment            = var.environment
  instance_type          = var.peer_instance_type
  ami_id                 = var.ubuntu_ami_id
  subnet_id              = module.vpc.private_subnet_ids[2]
  vpc_security_group_ids = [
    module.security_groups.peer_sg_id,
    module.security_groups.common_sg_id
  ]
  
  key_name               = var.key_name
  private_ip             = "10.0.3.10"
  
  root_volume_size       = 30
  data_volume_size       = 100
  enable_monitoring      = true
  
  user_data = templatefile("${path.module}/user-data/peer-setup.sh", {
    organization = "prefet"
    hostname     = "peer0.prefet.foncier.ci"
  })
  
  tags = {
    Organization = "PREFET"
    Role         = "Peer"
    Name         = "VM3-Peer-PREFET"
  }
}

# ============================================================
# EC2 Instance - Orderer
# ============================================================

module "orderer" {
  source = "./modules/ec2"
  
  name                   = "orderer"
  environment            = var.environment
  instance_type          = var.orderer_instance_type
  ami_id                 = var.ubuntu_ami_id
  subnet_id              = module.vpc.private_subnet_ids[0]
  vpc_security_group_ids = [
    module.security_groups.orderer_sg_id,
    module.security_groups.common_sg_id
  ]
  
  key_name               = var.key_name
  private_ip             = "10.0.4.10"
  
  root_volume_size       = 30
  data_volume_size       = 200
  enable_monitoring      = true
  
  user_data = templatefile("${path.module}/user-data/orderer-setup.sh", {
    hostname = "orderer.foncier.ci"
  })
  
  tags = {
    Organization = "Orderer"
    Role         = "Orderer"
    Name         = "VM4-Orderer"
  }
}

# ============================================================
# Route 53 - DNS Privé
# ============================================================

resource "aws_route53_zone" "private" {
  name = "foncier.ci"
  
  vpc {
    vpc_id = module.vpc.vpc_id
  }
  
  tags = {
    Name = "Private DNS Zone - Blockchain"
  }
}

# DNS Records - Peers
resource "aws_route53_record" "peer_afor" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "peer0.afor.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_afor.private_ip]
}

resource "aws_route53_record" "peer_cvgfr" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "peer0.cvgfr.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_cvgfr.private_ip]
}

resource "aws_route53_record" "peer_prefet" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "peer0.prefet.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_prefet.private_ip]
}

# DNS Record - Orderer
resource "aws_route53_record" "orderer" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "orderer.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.orderer.private_ip]
}

# DNS Records - CAs
resource "aws_route53_record" "ca_afor" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ca.afor.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_afor.private_ip]
}

resource "aws_route53_record" "ca_cvgfr" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ca.cvgfr.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_cvgfr.private_ip]
}

resource "aws_route53_record" "ca_prefet" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ca.prefet.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.peer_prefet.private_ip]
}

resource "aws_route53_record" "ca_orderer" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "ca-orderer.foncier.ci"
  type    = "A"
  ttl     = 300
  records = [module.orderer.private_ip]
}

# ============================================================
# Application Load Balancer (pour APIs publiques)
# ============================================================

resource "aws_lb" "api" {
  name               = "afor-blockchain-api-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [module.security_groups.alb_sg_id]
  subnets            = module.vpc.public_subnet_ids
  
  enable_deletion_protection = var.environment == "production" ? true : false
  
  tags = {
    Name = "AFOR-Blockchain-API-LB"
  }
}

# Target Group pour API
resource "aws_lb_target_group" "api" {
  name     = "afor-blockchain-api-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
  
  tags = {
    Name = "AFOR-Blockchain-API-TG"
  }
}

# Attacher les instances au Target Group
resource "aws_lb_target_group_attachment" "api_afor" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = module.peer_afor.instance_id
  port             = 3001
}

resource "aws_lb_target_group_attachment" "api_cvgfr" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = module.peer_cvgfr.instance_id
  port             = 3001
}

resource "aws_lb_target_group_attachment" "api_prefet" {
  target_group_arn = aws_lb_target_group.api.arn
  target_id        = module.peer_prefet.instance_id
  port             = 3001
}

# Listener HTTP (redirection vers HTTPS en production)
resource "aws_lb_listener" "api_http" {
  load_balancer_arn = aws_lb.api.arn
  port              = "80"
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

# ============================================================
# CloudWatch Log Groups
# ============================================================

resource "aws_cloudwatch_log_group" "peers" {
  for_each = toset(["afor", "cvgfr", "prefet"])
  
  name              = "/aws/ec2/blockchain-peer-${each.key}"
  retention_in_days = 30
  
  tags = {
    Name = "Peer ${upper(each.key)} Logs"
  }
}

resource "aws_cloudwatch_log_group" "orderer" {
  name              = "/aws/ec2/blockchain-orderer"
  retention_in_days = 30
  
  tags = {
    Name = "Orderer Logs"
  }
}

# ============================================================
# S3 Bucket pour Backups
# ============================================================

resource "aws_s3_bucket" "backups" {
  bucket = "afor-blockchain-backups-${var.environment}"
  
  tags = {
    Name = "AFOR Blockchain Backups"
  }
}

resource "aws_s3_bucket_versioning" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  bucket = aws_s3_bucket.backups.id
  
  rule {
    id     = "archive-old-backups"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    expiration {
      days = 365
    }
  }
}
