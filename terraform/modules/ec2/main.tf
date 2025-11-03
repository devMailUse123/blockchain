# ============================================================
# Module EC2 - Hyperledger Fabric Nodes
# ============================================================

# Instance EC2
resource "aws_instance" "main" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  private_ip             = var.private_ip
  
  iam_instance_profile = aws_iam_instance_profile.main.name

  root_block_device {
    volume_type           = var.root_volume_type
    volume_size           = var.root_volume_size
    encrypted             = var.enable_encryption
    delete_on_termination = true

    tags = merge(
      var.tags,
      {
        Name = "${var.name}-root-volume"
      }
    )
  }

  user_data                   = var.user_data
  user_data_replace_on_change = var.user_data_replace_on_change

  monitoring = var.enable_detailed_monitoring

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 obligatoire
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = merge(
    var.tags,
    {
      Name = var.name
      Role = var.role
    }
  )

  lifecycle {
    ignore_changes = [
      ami,
      user_data
    ]
  }
}

# EBS Volume additionnel pour les données
resource "aws_ebs_volume" "data" {
  count             = var.data_volume_size > 0 ? 1 : 0
  availability_zone = aws_instance.main.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
  encrypted         = var.enable_encryption
  iops              = var.data_volume_type == "io1" || var.data_volume_type == "io2" ? var.data_volume_iops : null
  throughput        = var.data_volume_type == "gp3" ? var.data_volume_throughput : null

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-data-volume"
    }
  )
}

# Attachement du volume de données
resource "aws_volume_attachment" "data" {
  count       = var.data_volume_size > 0 ? 1 : 0
  device_name = var.data_volume_device
  volume_id   = aws_ebs_volume.data[0].id
  instance_id = aws_instance.main.id
}

# Elastic IP (optionnel)
resource "aws_eip" "main" {
  count    = var.associate_public_ip ? 1 : 0
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.name}-eip"
    }
  )
}

# IAM Role pour l'instance
resource "aws_iam_role" "main" {
  name = "${var.name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "main" {
  name = "${var.name}-profile"
  role = aws_iam_role.main.name

  tags = var.tags
}

# Politique IAM pour CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.name}-cloudwatch-logs"
  role = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:*:*:log-group:/aws/ec2/${var.name}",
          "arn:aws:logs:*:*:log-group:/aws/ec2/${var.name}:*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
      }
    ]
  })
}

# Politique IAM pour S3 (backups)
resource "aws_iam_role_policy" "s3_backup" {
  count = var.enable_s3_backup ? 1 : 0
  name  = "${var.name}-s3-backup"
  role  = aws_iam_role.main.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          var.backup_bucket_arn,
          "${var.backup_bucket_arn}/*"
        ]
      }
    ]
  })
}

# Politique IAM pour SSM (Systems Manager)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Alarm - CPU élevé
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Cette alarme surveille l'utilisation CPU de ${var.name}"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = var.tags
}

# CloudWatch Alarm - Status Check Failed
resource "aws_cloudwatch_metric_alarm" "status_check" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.name}-status-check-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0"
  alarm_description   = "Cette alarme surveille les status checks de ${var.name}"
  alarm_actions       = var.alarm_actions

  dimensions = {
    InstanceId = aws_instance.main.id
  }

  tags = var.tags
}

# Snapshot EBS quotidien (optionnel)
resource "aws_dlm_lifecycle_policy" "ebs_snapshot" {
  count              = var.enable_ebs_snapshots ? 1 : 0
  description        = "Politique de snapshots pour ${var.name}"
  execution_role_arn = aws_iam_role.dlm[0].arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["VOLUME"]

    schedule {
      name = "Daily snapshots"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }

      retain_rule {
        count = var.snapshot_retention_days
      }

      tags_to_add = {
        SnapshotCreator = "DLM"
        Instance        = var.name
      }

      copy_tags = true
    }

    target_tags = {
      Name = var.name
    }
  }

  tags = var.tags
}

# IAM Role pour DLM (Data Lifecycle Manager)
resource "aws_iam_role" "dlm" {
  count = var.enable_ebs_snapshots ? 1 : 0
  name  = "${var.name}-dlm-lifecycle-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "dlm.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Politique IAM pour DLM
resource "aws_iam_role_policy" "dlm" {
  count = var.enable_ebs_snapshots ? 1 : 0
  name  = "${var.name}-dlm-lifecycle-policy"
  role  = aws_iam_role.dlm[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateSnapshot",
          "ec2:CreateSnapshots",
          "ec2:DeleteSnapshot",
          "ec2:DescribeInstances",
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateTags"
        ]
        Resource = "arn:aws:ec2:*::snapshot/*"
      }
    ]
  })
}
