# -------------------- DB 전용 보안 그룹 --------------------
resource "aws_security_group" "db" {
  name        = "${var.identifier}-sg"
  description = "Allow MySQL only from allowed SGs"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.identifier}-sg"
  })
}

# -------------------- DB Subnet Group --------------------
resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.identifier}-subnets"
  })
}

# -------------------- RDS 인스턴스 --------------------
resource "aws_db_instance" "this" {
  identifier                   = var.identifier
  allocated_storage            = var.allocated_storage
  engine                       = "mysql"
  engine_version               = var.engine_version
  instance_class               = var.instance_class
  db_name                      = var.database_name
  username                     = var.master_username
  password                     = var.master_password
  port                         = 3306
  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.db.id]
  multi_az                     = var.multi_az
  publicly_accessible          = false
  backup_retention_period      = var.backup_retention_period
  skip_final_snapshot          = var.skip_final_snapshot
  delete_automated_backups     = true
  storage_type                 = "gp3"
  auto_minor_version_upgrade   = true
  apply_immediately            = true
  performance_insights_enabled = false

  tags = merge(var.tags, {
    Name = var.identifier
  })
}
