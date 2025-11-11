# -------------------- 로컬 구성 --------------------
locals {
  container_name = "${var.name}-app"
  log_group_name = "/ecs/${var.name}"
  merged_environment = concat(
    var.environment,
    [
      {
        name  = "S3_ENV_BUCKET"
        value = var.env_bucket_name
      },
      {
        name  = "S3_ENV_KEY"
        value = var.env_object_key
      }
    ]
  )
}

# -------------------- 로그 그룹 --------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# -------------------- ECS 클러스터 --------------------
resource "aws_ecs_cluster" "this" {
  name = "${var.name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# -------------------- IAM 역할 --------------------
data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "${var.name}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_default" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "task_s3_access" {
  name = "${var.name}-s3-access"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.env_bucket_arn,
          "${var.env_bucket_arn}/*"
        ]
      }
    ]
  })
}

# -------------------- 네트워킹 (보안 그룹) --------------------
resource "aws_security_group" "alb" {
  name        = "${var.name}-alb-sg"
  description = "Front-end access"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.alb_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "service" {
  name        = "${var.name}-svc-sg"
  description = "Allow ALB to reach ECS service"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-svc-sg" })
}

# -------------------- ALB --------------------
resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
  tags               = var.tags
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    healthy_threshold   = 2
    unhealthy_threshold = 5
    matcher             = "200-399"
    interval            = 30
  }

  tags = var.tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# -------------------- ECS 태스크 정의 --------------------
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-task"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = "${var.repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.merged_environment
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = var.name
        }
      }
    }
  ])
}

# -------------------- ECS 서비스 --------------------
resource "aws_ecs_service" "this" {
  name            = "${var.name}-svc"
  cluster         = aws_ecs_cluster.this.id
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.this.arn

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.service.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = local.container_name
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.http]
  tags       = var.tags
}
