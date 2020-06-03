resource "aws_cloudwatch_log_group" "logging-api-log-group" {
  name  = "pttp-monitoring-docker-log-group"

  retention_in_days = 90
}

resource "aws_lb" "api-alb" {
  name     = "pttp-api-alb"
  internal = false
  subnets  = var.subnet_ids

  security_groups = [
    "${aws_security_group.api-alb-in.id}",
    "${aws_security_group.api-alb-out.id}"
  ]

  load_balancer_type = "application"

  tags = {
    Name = "pttp"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.api-alb.arn}"
  port              = "3000"
//  protocol          = "HTTPS"
  protocol          = "HTTP"
//  certificate_arn   = "${var.elb-ssl-cert-arn}"
//  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

  default_action {
    target_group_arn = "${aws_alb_target_group.logging-api-tg.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group" "logging-api-tg" {
  depends_on  = ["aws_lb.api-alb"]
  name        = "pttp-logging-api"
  port        = "3000"
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"

  tags = {
    Name = "pttp-monitoring-api-tg"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 10
    path                = "/login"
  }
}

resource "aws_ecr_repository" "logging-api-ecr" {
  name  = "pttp-monitoring-service"
}

resource "aws_ecs_task_definition" "logging-api-task" {
  family                   = "logging-api-task"
  task_role_arn            = "${aws_iam_role.logging-api-task-role.arn}"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
  memory                   = 512
  cpu                      = "256"
  network_mode             = "awsvpc"

  container_definitions = <<EOF
[
    {
      "volumesFrom": [],
      "memory": 512,
      "extraHosts": null,
      "dnsServers": null,
      "disableNetworking": null,
      "dnsSearchDomains": null,
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "hostname": null,
      "essential": true,
      "entryPoint": null,
      "mountPoints": [],
      "name": "logging",
      "ulimits": null,
      "dockerSecurityOptions": null,
      "environment": [
      ],
      "links": null,
      "workingDirectory": null,
      "readonlyRootFilesystem": null,
      "image": "grafana/grafana",
      "command": null,
      "user": null,
      "dockerLabels": null,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.logging-api-log-group.name}",
          "awslogs-region": "${var.aws-region}",
          "awslogs-stream-prefix": "pttp-monitoring-api-docker-logs"
        }
      },
      "cpu": 0,
      "privileged": null,
      "expanded": true
    }
]
EOF
}

resource "aws_ecs_cluster" "api-cluster" {
  name = "pttp-monitoring-api-cluster"
}

resource "aws_security_group" "api-alb-in" {
  name        = "loadbalancer-in"
  description = "Allow Inbound Traffic To The ALB"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name = "pttp"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "api-alb-out" {
  name        = "loadbalancer-out"
  description = "Allow Outbound Traffic To The ALB"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name = "pttp"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "api-in" {
  name        = "api-in"
  description = "Allow Inbound Traffic To API"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name = "pttp"
  }

  ingress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.api-alb-out.id}"]
  }
}

resource "aws_security_group" "api-out" {
  name        = "api-out"
  description = "Allow Outbound Traffic From the API"
  vpc_id      = "${var.vpc_id}"

  tags = {
    Name = "pttp"
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "logging-api-service" {
  name            = "logging-api-service"
  cluster         = "${aws_ecs_cluster.api-cluster.id}"
  task_definition = "${aws_ecs_task_definition.logging-api-task.arn}"
  desired_count   = "1"
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
      "${aws_security_group.api-in.id}",
      "${aws_security_group.api-out.id}"
    ]

    subnets          = var.subnet_ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.logging-api-tg.arn}"
    container_name   = "logging"
    container_port   = "3000"
  }
}
//
//resource "aws_alb_listener_rule" "logging-api-lr" {
//  depends_on   = ["aws_alb_target_group.logging-api-tg"]
//  listener_arn = "${aws_alb_listener.alb_listener.arn}"
//  priority     = 3
//
//  action {
//    type             = "forward"
//    target_group_arn = "${aws_alb_target_group.logging-api-tg.id}"
//  }
//
//  condition {
//    field  = "path-pattern"
//    values = ["/*"]
//  }
//}

resource "aws_iam_role" "logging-api-task-role" {
  name  = "pttp-logging-api-task-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "logging-api-task-policy" {
  name       = "pttp-logging-api-task-policy"
  role       = "${aws_iam_role.logging-api-task-role.id}"
  depends_on = ["aws_iam_role.logging-api-task-role"]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
