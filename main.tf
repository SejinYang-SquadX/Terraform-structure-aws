# -------------------- 프로바이더 설정 --------------------
provider "aws" {
  region = var.aws_region
}

# -------------------- 계정 정보 --------------------
data "aws_caller_identity" "current" {}

# -------------------- 유틸리티 리소스 --------------------
resource "random_id" "env_bucket" {
  byte_length = 4
}

# -------------------- 공통 로컬 값 --------------------
locals {
  account_root_arn          = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  resolved_env_bucket_name  = length(trimspace(var.env_bucket_name)) > 0 ? var.env_bucket_name : lower("${var.project_name}-env-${random_id.env_bucket.hex}")
  env_bucket_policy_actions = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
  ecs_task_role_arn         = try(module.ecs_service.task_role_arn, null)
  env_bucket_policy_principals = distinct(concat(
    [local.account_root_arn],
    var.env_bucket_allowed_principals,
    local.ecs_task_role_arn == null ? [] : [local.ecs_task_role_arn]
  ))
  private_instance_user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    if ! apt-get install -y mysql-client-core-8.0; then
      apt-get install -y default-mysql-client
    fi
  EOT
  db_env_file_content = templatefile("${path.module}/templates/database.env.tpl", {
    db_host     = module.database.address
    db_port     = module.database.port
    db_name     = module.database.database_name
    db_username = var.db_username
    db_password = var.db_password
  })
}

# -------------------- AMI 조회 --------------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

# -------------------- VPC 네트워크 모듈 --------------------
module "network" {
  source = "./modules/vpc"

  name                = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnets      = var.public_subnets
  private_subnets     = var.private_subnets
  nat_gateway_enabled = var.nat_gateway_enabled
  tags                = var.tags
}

# -------------------- SSH 키 생성 --------------------
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.ssh.public_key_openssh
  tags       = merge(var.tags, { Name = var.ssh_key_name })
}

resource "local_sensitive_file" "private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = var.ssh_private_key_path
  file_permission = "0600"
}

# -------------------- 보안 그룹 --------------------
resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Allow SSH from trusted CIDR blocks"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-bastion-sg"
  })
}

resource "aws_security_group" "private_app" {
  name        = "${var.project_name}-private-sg"
  description = "Allow SSH only from bastion SG"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-private-sg"
  })
}

# -------------------- EC2 인스턴스 --------------------
module "bastion_instance" {
  source = "./modules/ec2"

  name                = "${var.project_name}-bastion"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = var.public_instance_type
  subnet_id           = module.network.public_subnet_ids[0]
  security_group_ids  = [aws_security_group.bastion.id]
  associate_public_ip = true
  key_name            = aws_key_pair.generated.key_name
  tags                = var.tags
}

module "private_instance" {
  source = "./modules/ec2"

  name                = "${var.project_name}-private"
  ami_id              = data.aws_ami.ubuntu.id
  instance_type       = var.private_instance_type
  subnet_id           = module.network.private_subnet_ids[0]
  security_group_ids  = [aws_security_group.private_app.id]
  associate_public_ip = false
  key_name            = aws_key_pair.generated.key_name
  tags                = var.tags
  user_data           = local.private_instance_user_data
}

# -------------------- RDS (MySQL) --------------------
module "database" {
  source = "./modules/rds"

  identifier                 = "${var.project_name}-mysql"
  database_name              = var.db_name
  master_username            = var.db_username
  master_password            = var.db_password
  instance_class             = var.db_instance_class
  allocated_storage          = var.db_allocated_storage
  engine_version             = var.db_engine_version
  subnet_ids                 = module.network.private_subnet_ids
  vpc_id                     = module.network.vpc_id
  allowed_security_group_ids = [aws_security_group.private_app.id]
  multi_az                   = var.db_multi_az
  backup_retention_period    = var.db_backup_retention
  skip_final_snapshot        = var.db_skip_final_snapshot
  tags                       = var.tags
}

# -------------------- 환경 변수 S3 버킷 --------------------
module "env_bucket" {
  source = "./modules/env_bucket"

  bucket_name = local.resolved_env_bucket_name
  object_key  = var.env_object_key
  env_content = local.db_env_file_content
  tags        = var.tags
}

# -------------------- ECR 리포지토리 --------------------
module "container_registry" {
  source = "./modules/ecr"

  name                  = var.ecr_repository_name
  image_tag_mutability  = var.ecr_image_tag_mutability
  lifecycle_policy_json = var.ecr_lifecycle_policy
  tags                  = var.tags
}

# -------------------- ECS + ALB --------------------
module "ecs_service" {
  source = "./modules/ecs_service"

  name               = "${var.project_name}-app"
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  repository_url     = module.container_registry.repository_url
  image_tag          = var.ecs_container_image_tag
  container_port     = var.ecs_container_port
  desired_count      = var.ecs_desired_count
  task_cpu           = var.ecs_task_cpu
  task_memory        = var.ecs_task_memory
  health_check_path  = var.ecs_health_check_path
  alb_ingress_cidrs  = var.alb_ingress_cidrs
  log_retention_days = var.ecs_log_retention_days
  env_bucket_arn     = module.env_bucket.bucket_arn
  env_bucket_name    = module.env_bucket.bucket_name
  env_object_key     = module.env_bucket.object_key
  environment        = var.ecs_environment_variables
  aws_region         = var.aws_region
  tags               = var.tags
}

# -------------------- 환경 변수 버킷 정책 --------------------
resource "aws_s3_bucket_policy" "env_bucket" {
  bucket = module.env_bucket.bucket_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "RestrictAccessToAllowedPrincipals"
        Effect    = "Deny"
        Principal = "*"
        Action    = local.env_bucket_policy_actions
        Resource = [
          module.env_bucket.bucket_arn,
          "${module.env_bucket.bucket_arn}/*"
        ]
        Condition = {
          StringNotEquals = {
            "aws:PrincipalArn" = local.env_bucket_policy_principals
          }
        }
      }
    ]
  })
}
