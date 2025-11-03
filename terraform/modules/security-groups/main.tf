# ============================================================
# Module Security Groups - Hyperledger Fabric
# ============================================================

# Security Group - Peer Nodes
resource "aws_security_group" "peer" {
  name        = "${var.name_prefix}-peer-sg"
  description = "Security group pour les peers Hyperledger Fabric"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-peer-sg"
      Type = "Peer"
    }
  )
}

# Peer - Règles entrantes
resource "aws_security_group_rule" "peer_ingress_gossip" {
  type              = "ingress"
  from_port         = 7051
  to_port           = 7051
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Peer gRPC"
  security_group_id = aws_security_group.peer.id
}

resource "aws_security_group_rule" "peer_ingress_chaincode" {
  type              = "ingress"
  from_port         = 7052
  to_port           = 7052
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Peer Chaincode"
  security_group_id = aws_security_group.peer.id
}

resource "aws_security_group_rule" "peer_ingress_events" {
  type              = "ingress"
  from_port         = 7053
  to_port           = 7053
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Peer Events"
  security_group_id = aws_security_group.peer.id
}

resource "aws_security_group_rule" "peer_ingress_operations" {
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Peer Operations (metrics)"
  security_group_id = aws_security_group.peer.id
}

# Peer - CouchDB
resource "aws_security_group_rule" "peer_ingress_couchdb" {
  type              = "ingress"
  from_port         = 5984
  to_port           = 5984
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "CouchDB"
  security_group_id = aws_security_group.peer.id
}

# Peer - CA (Certificate Authority)
resource "aws_security_group_rule" "peer_ingress_ca" {
  type              = "ingress"
  from_port         = 7054
  to_port           = 7054
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Fabric CA"
  security_group_id = aws_security_group.peer.id
}

# Peer - API REST
resource "aws_security_group_rule" "peer_ingress_api" {
  type              = "ingress"
  from_port         = 3001
  to_port           = 3001
  protocol          = "tcp"
  cidr_blocks       = var.api_allowed_cidrs
  description       = "API REST"
  security_group_id = aws_security_group.peer.id
}

# Peer - SSH
resource "aws_security_group_rule" "peer_ingress_ssh" {
  count             = var.enable_ssh_access ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "SSH Admin"
  security_group_id = aws_security_group.peer.id
}

# Peer - Règle sortante (tout autorisé)
resource "aws_security_group_rule" "peer_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
  security_group_id = aws_security_group.peer.id
}

# ============================================================
# Security Group - Orderer Nodes
# ============================================================

resource "aws_security_group" "orderer" {
  name        = "${var.name_prefix}-orderer-sg"
  description = "Security group pour l'orderer Hyperledger Fabric"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-orderer-sg"
      Type = "Orderer"
    }
  )
}

# Orderer - Règles entrantes
resource "aws_security_group_rule" "orderer_ingress_general" {
  type              = "ingress"
  from_port         = 7050
  to_port           = 7050
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Orderer gRPC"
  security_group_id = aws_security_group.orderer.id
}

resource "aws_security_group_rule" "orderer_ingress_admin" {
  type              = "ingress"
  from_port         = 7053
  to_port           = 7053
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Orderer Admin"
  security_group_id = aws_security_group.orderer.id
}

resource "aws_security_group_rule" "orderer_ingress_operations" {
  type              = "ingress"
  from_port         = 9443
  to_port           = 9443
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Orderer Operations (metrics)"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - CA
resource "aws_security_group_rule" "orderer_ingress_ca" {
  type              = "ingress"
  from_port         = 7054
  to_port           = 7054
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "Fabric CA Orderer"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - Prometheus
resource "aws_security_group_rule" "orderer_ingress_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "Prometheus"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - Grafana
resource "aws_security_group_rule" "orderer_ingress_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "Grafana"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - Blockchain Explorer
resource "aws_security_group_rule" "orderer_ingress_explorer" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "Blockchain Explorer"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - SSH
resource "aws_security_group_rule" "orderer_ingress_ssh" {
  count             = var.enable_ssh_access ? 1 : 0
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.admin_cidr_blocks
  description       = "SSH Admin"
  security_group_id = aws_security_group.orderer.id
}

# Orderer - Règle sortante
resource "aws_security_group_rule" "orderer_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
  security_group_id = aws_security_group.orderer.id
}

# ============================================================
# Security Group - Application Load Balancer
# ============================================================

resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security group pour l'Application Load Balancer"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
      Type = "ALB"
    }
  )
}

# ALB - HTTP
resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidrs
  description       = "HTTP"
  security_group_id = aws_security_group.alb.id
}

# ALB - HTTPS
resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.alb_allowed_cidrs
  description       = "HTTPS"
  security_group_id = aws_security_group.alb.id
}

# ALB - Sortie vers les peers
resource "aws_security_group_rule" "alb_egress_api" {
  type                     = "egress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.peer.id
  description              = "Vers API des peers"
  security_group_id        = aws_security_group.alb.id
}

# Autoriser ALB à accéder aux peers
resource "aws_security_group_rule" "peer_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "From ALB"
  security_group_id        = aws_security_group.peer.id
}
