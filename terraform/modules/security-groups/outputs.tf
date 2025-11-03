# ============================================================
# Outputs - Module Security Groups
# ============================================================

output "peer_sg_id" {
  description = "ID du security group pour les peers"
  value       = aws_security_group.peer.id
}

output "peer_sg_arn" {
  description = "ARN du security group pour les peers"
  value       = aws_security_group.peer.arn
}

output "orderer_sg_id" {
  description = "ID du security group pour l'orderer"
  value       = aws_security_group.orderer.id
}

output "orderer_sg_arn" {
  description = "ARN du security group pour l'orderer"
  value       = aws_security_group.orderer.arn
}

output "alb_sg_id" {
  description = "ID du security group pour l'ALB"
  value       = aws_security_group.alb.id
}

output "alb_sg_arn" {
  description = "ARN du security group pour l'ALB"
  value       = aws_security_group.alb.arn
}
