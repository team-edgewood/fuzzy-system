

resource "aws_lb" "lb" {
  name               = "${var.name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb_sg.id}"]
  subnets            = ["${var.subnets}"]

  enable_deletion_protection = false
}

resource "aws_security_group" "lb_sg" {
  name        = "${var.name}-lb-sg"
  description = "Allow all inbound traffic"
  vpc_id      = "${var.vpc_id}"
}

resource "aws_security_group_rule" "internet_in" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.lb_sg.id}"
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = "${var.vpc_id}"
  target_type = "ip"
}

# Redirect all traffic from the ALB to the target group
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = "${aws_lb.lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.tg.id}"
    type             = "forward"
  }
}
