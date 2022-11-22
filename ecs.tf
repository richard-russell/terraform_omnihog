resource "aws_ecs_cluster" "tfc_agent" {
  name = "${var.prefix}-cluster"
}

resource "aws_ecs_service" "tfc_agent" {
  count           = var.pool_count
  name            = "${var.prefix}-${format("%04d", count.index + 1)}"
  cluster         = aws_ecs_cluster.tfc_agent.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.tfc_agent[count.index].arn
  desired_count   = var.agent_per_pool_count
  network_configuration {
    security_groups  = [aws_security_group.tfc_agent.id]
    subnets          = [aws_subnet.tfc_agent.id]
    assign_public_ip = true
  }
}

resource "aws_ecs_task_definition" "tfc_agent" {
  count                    = var.pool_count
  family                   = "${var.prefix}-${format("%04d", count.index + 1)}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.agent_init.arn
  task_role_arn            = aws_iam_role.agent.arn
  cpu                      = var.agent_cpu
  memory                   = var.agent_memory
  container_definitions = jsonencode(
    [
      {
        name : "${var.prefix}-${format("%04d", count.index + 1)}"
        image : "hashicorp/tfc-agent:latest"
        essential : true
        cpu : var.agent_cpu
        memory : var.agent_memory
        logConfiguration : {
          logDriver : "awslogs",
          options : {
            awslogs-create-group : "true",
            awslogs-group : "awslogs-tfc-agent"
            awslogs-region : var.aws_region
            awslogs-stream-prefix : "awslogs-tfc-agent"
          }
        }
        environment = [
          {
            name  = "TFC_AGENT_SINGLE",
            value = "true"
          },
          {
            name  = "TFC_AGENT_NAME",
            value = "${var.prefix}-${format("%04d", count.index + 1)}"
          },
          {
            name  = "TFC_AGENT_LOG_LEVEL",
            value = "debug"
          },
          {
            name  = "TFC_ADDRESS",
            value = "https://${var.tfe_hostname}"
          }
        ]
        secrets = [
          {
            name      = "TFC_AGENT_TOKEN",
            valueFrom = aws_ssm_parameter.agent_token[count.index].arn
          }
        ]
      }
    ]
  )
}

resource "aws_ssm_parameter" "agent_token" {
  count       = var.pool_count
  name        = "${var.prefix}-${format("%04d", count.index + 1)}"
  description = "Terraform Cloud agent token ${format("%04d", count.index + 1)}"
  type        = "SecureString"
  value       = tfe_agent_token.test-agent-token[count.index].token
}

# task execution role for agent init
resource "aws_iam_role" "agent_init" {
  name               = "${var.prefix}-ecs-tfc-agent-task-init-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy_definition.json
}

resource "aws_iam_role_policy" "agent_init_policy" {
  role   = aws_iam_role.agent_init.name
  name   = "AccessSSMParameterforAgentToken"
  policy = data.aws_iam_policy_document.agent_init_policy.json
}

resource "aws_iam_role_policy_attachment" "agent_init_policy" {
  role       = aws_iam_role.agent_init.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "agent_init_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = aws_ssm_parameter.agent_token.*.arn
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# task role for agent
resource "aws_iam_role" "agent" {
  name               = "${var.prefix}-ecs-tfc-agent-role"
  assume_role_policy = data.aws_iam_policy_document.agent_assume_role_policy_definition.json
}

data "aws_iam_policy_document" "agent_assume_role_policy_definition" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role_policy" "agent_policy" {
  name = "${var.prefix}-ecs-tfc-agent-policy"
  role = aws_iam_role.agent.id

  policy = data.aws_iam_policy_document.agent_policy_definition.json
}

data "aws_iam_policy_document" "agent_policy_definition" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform_dev_role.arn]
  }
}

resource "aws_iam_role_policy_attachment" "agent_task_policy" {
  role       = aws_iam_role.agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# a role for terraform consumer to assume into
# you'll need to customize IAM policies to access resources as desired
resource "aws_iam_role" "terraform_dev_role" {
  name = "${var.prefix}-terraform_dev_role"

  assume_role_policy = data.aws_iam_policy_document.dev_assume_role_policy_definition.json
}

data "aws_iam_policy_document" "dev_assume_role_policy_definition" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    principals {
      identifiers = [aws_iam_role.agent.arn]
      type        = "AWS"
    }
  }
}

resource "aws_iam_role_policy_attachment" "dev_ec2_role_attach" {
  role       = aws_iam_role.terraform_dev_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

# networking for agents to reach internet
resource "aws_vpc" "main" {
  cidr_block = var.ip_cidr_vpc
}

resource "aws_subnet" "tfc_agent" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.ip_cidr_agent_subnet
  availability_zone = "${var.aws_region}a"
}

resource "aws_security_group" "tfc_agent" {
  name_prefix = "${var.prefix}-sg"
  description = "Security group for tfc-agent-vpc"
  vpc_id      = aws_vpc.main.id
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_egress" {
  security_group_id = aws_security_group.tfc_agent.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  # to peer to an HVN add your route here, for example
  #   route {
  #     cidr_block                = "172.25.16.0/24"
  #     vpc_peering_connection_id = "pcx-07ee5501175307837"
  #   }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.tfc_agent.id
  route_table_id = aws_route_table.main.id
}
