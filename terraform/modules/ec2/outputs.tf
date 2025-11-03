# ============================================================
# Outputs - Module EC2
# ============================================================

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN de l'instance EC2"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Adresse IP privée de l'instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Adresse IP publique de l'instance (si Elastic IP)"
  value       = var.associate_public_ip ? aws_eip.main[0].public_ip : null
}

output "availability_zone" {
  description = "Zone de disponibilité de l'instance"
  value       = aws_instance.main.availability_zone
}

output "data_volume_id" {
  description = "ID du volume de données EBS"
  value       = var.data_volume_size > 0 ? aws_ebs_volume.data[0].id : null
}

output "iam_role_name" {
  description = "Nom du rôle IAM de l'instance"
  value       = aws_iam_role.main.name
}

output "iam_role_arn" {
  description = "ARN du rôle IAM de l'instance"
  value       = aws_iam_role.main.arn
}

output "instance_profile_name" {
  description = "Nom du profil d'instance IAM"
  value       = aws_iam_instance_profile.main.name
}

output "instance_profile_arn" {
  description = "ARN du profil d'instance IAM"
  value       = aws_iam_instance_profile.main.arn
}
