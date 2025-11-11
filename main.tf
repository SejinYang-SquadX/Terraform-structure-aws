# -------------------- 프로바이더 설정 --------------------
provider "aws" {
  region = var.aws_region
}

# -------------------- 공통 로컬 값 --------------------
locals {
  private_instance_user_data = <<-EOT
    #!/bin/bash
    set -euo pipefail
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y mysql-client
  EOT
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
