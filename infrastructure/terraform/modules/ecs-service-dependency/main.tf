resource "aws_security_group_rule" "service_to_lb" {
  type = "egress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  security_group_id = "${var.from_service_sg}"
  source_security_group_id = "${var.to_lb_sg}"
}


resource "aws_security_group_rule" "lb_from_service" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  security_group_id = "${var.to_lb_sg}"
  source_security_group_id = "${var.from_service_sg}"
}
