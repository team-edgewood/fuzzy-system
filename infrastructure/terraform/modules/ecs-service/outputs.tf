output "service_sg" {
  value = "${aws_security_group.service_sg.id}"
}
output "lb_sg" {
  value = "${aws_security_group.lb_sg.id}"
}
