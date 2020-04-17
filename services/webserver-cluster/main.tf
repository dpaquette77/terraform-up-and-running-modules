

provider "aws" {
  region = "us-east-2"
}

locals {
    http_port = 80
    backend_http_port = 8080
    any_port = 0
    any_protocol = "-1"
    tcp_protocol = "tcp"
    all_ips = ["0.0.0.0/0"]
}

data "terraform_remote_state" "db" {
    backend = "s3"

    config = {
        bucket = var.db_remote_state_bucket
        key = var.db_remote_state_key
        region = "us-east-2"
    }
}

resource "aws_security_group" "instance" {
    name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "allow_inbound_http_instance" {
    type = "ingress"
    security_group_id = aws_security_group.instance.id

    from_port = local.backend_http_port
    to_port = local.backend_http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips    
}

data "template_file" "user_data" {
    template = file("${path.module}/user-data.sh")
    vars = {
        db_address = data.terraform_remote_state.db.outputs.address
        db_port = data.terraform_remote_state.db.outputs.port
        server_port = local.backend_http_port
    }
}

resource "aws_launch_configuration" "example" {
    image_id = "ami-0c55b159cbfafe1f0"
    instance_type = var.instance_type
    security_groups = [aws_security_group.instance.id]
    user_data = data.template_file.user_data.rendered

    lifecycle {
        create_before_destroy = true
    }
}

resource "aws_autoscaling_group" "example" {
    launch_configuration = aws_launch_configuration.example.name
    min_size = var.min_size
    max_size = var.max_size
    vpc_zone_identifier = data.aws_subnet_ids.default.ids

    tag {
        key = "Name"
        value = "${var.cluster_name}-asg"
        propagate_at_launch = true
    }

    dynamic "tag" {
        for_each = var.asg_custom_tags
        content {
            Key = tag.key
            Value = tag.value
            propagate_at_launch = true
        }
    }

    target_group_arns = [aws_lb_target_group.mytarget-group.arn]
    health_check_type = "ELB"
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}


resource "aws_lb" "example" {
    name = "${var.cluster_name}-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "example" {
    load_balancer_arn = aws_lb.example.arn
    port = local.http_port
    protocol = "HTTP"

    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404
        }
    }
}

resource "aws_security_group" "alb_sg" {
    name = "${var.cluster_name}-alb"
}

resource "aws_security_group_rule" "allow_http_in" {
    type = "ingress"
    security_group_id = aws_security_group.alb_sg.id
    
    from_port = local.http_port
    to_port = local.http_port
    protocol = local.tcp_protocol
    cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_out" {
    type = "egress"
    security_group_id = aws_security_group.alb_sg.id

    from_port = local.any_port
    to_port = local.any_port
    protocol = local.any_protocol
    cidr_blocks = local.all_ips    
}

resource "aws_lb_target_group" "mytarget-group" {
    name = "${var.cluster_name}-target-group"
    port = local.backend_http_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id
    
    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "lblistenerrule" {
    listener_arn = aws_lb_listener.example.arn
    priority = 100
    # testing
    condition {
        field = "path-pattern"
        values = ["*"]
    }

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.mytarget-group.arn
    }
  
}


