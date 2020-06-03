resource "aws_lb_target_group" "test" {
  name     = "tf-example-lb-tg"
  port     = 3000
  protocol = "TCP_UDP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_target_group" "test-udp" {
  name = "tf-example-lb-tg-udp"
  port = 53
  protocol = "UDP"
  vpc_id = "${var.vpc_id}"
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.test-udp.arn
  target_id        = aws_instance.radius.id
  port             = 53
}

resource "aws_lb_listener" "front_end_udp" {
  load_balancer_arn = aws_lb.test.arn
  port              = "53"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test-udp.arn
  }
}

resource "aws_ecs_cluster" "frontend-cluster" {
  name = "pttp-test-cluster"
}

resource "aws_cloudwatch_log_group" "frontend-log-group" {
  name = "frontend-log-group"

  retention_in_days = 90
}

resource "aws_ecr_repository" "govwifi-frontend-ecr" {
  name  = "govwifi-frontend"
}

resource "aws_ecs_task_definition" "radius-task" {
  family        = "pttp-test"
  task_role_arn = "${aws_iam_role.ecs-task-role.arn}"

  depends_on = [
    aws_ecr_repository.govwifi-frontend-ecr
  ]

  container_definitions = <<EOF
[
  {
    "memory": 1500,
    "portMappings": [
      {
        "hostPort": 3000,
        "containerPort": 3000,
        "protocol": "tcp"
      },
      {
        "hostPort": 1530,
        "containerPort": 1530,
        "protocol": "udp"
      },
      {
        "hostPort": 53,
        "containerPort": 53,
        "protocol": "udp"
      }
    ],
    "essential": true,
    "name": "frontend-radius",
    "environment": [
      {
        "name": "AUTHORISATION_API_BASE_URL",
        "value": "test"
      },{
        "name": "LOGGING_API_BASE_URL",
        "value": "test"
      },{
        "name": "BACKEND_API_KEY",
        "value": "test"
      },{
        "name": "HEALTH_CHECK_RADIUS_KEY",
        "value": "test"
      },{
        "name": "HEALTH_CHECK_SSID",
        "value": "test"
      },{
        "name": "HEALTH_CHECK_IDENTITY",
        "value": "test"
      },{
        "name": "HEALTH_CHECK_PASSWORD",
        "value": "test"
      },{
        "name": "SERVICE_DOMAIN",
        "value": "test"
      },{
        "name": "RADIUSD_PARAMS",
        "value": "test"
      },{
        "name": "RACK_ENV",
        "value": "test"
      }
    ],
    "image": "261219435789.dkr.ecr.eu-west-2.amazonaws.com/govwifi-frontend:latest",
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.frontend-log-group.name}",
        "awslogs-region": "eu-west-2",
        "awslogs-stream-prefix": "eu-west-2-docker-logs"
      }
    },
    "cpu": 1000,
    "expanded": true
  }
]
EOF
}

resource "aws_lb" "test" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids

  enable_deletion_protection = false

  tags = {
    Environment = "test"
  }
}

resource "aws_ecs_service" "frontend-service" {
  name            = "pttp-service"
  cluster         = "${aws_ecs_cluster.frontend-cluster.id}"
  task_definition = "${aws_ecs_task_definition.radius-task.arn}"
  desired_count   = "1"

  depends_on = [
    aws_ecr_repository.govwifi-frontend-ecr,
    aws_lb_target_group.test-udp,
    aws_lb.test
  ]

  load_balancer {
    target_group_arn = aws_lb_target_group.test-udp.arn
    container_name   = "frontend-radius"
    container_port   = 3000
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}


//data "aws_ecs_container_definition" "ecs-container-def" {
//  task_definition = aws_ecs_task_definition.radius-task.id
//  container_name  = "frontend-radius"
//}
