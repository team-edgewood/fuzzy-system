output "vpc_id" {
  value = "${aws_vpc.main.id}"
}
output "public_subnets" {
  value = "${aws_subnet.public.*.id}"
}
output "private_subnets" {
  value = "${aws_subnet.private.*.id}"
}
output "public_dns_zone_id" {
  value = "${aws_route53_zone.public.id}"
}
output "public_dns_zone_name" {
  value = "${aws_route53_zone.public.name}"
}
output "internal_dns_zone_id" {
  value = "${aws_route53_zone.internal.id}"
}
output "internal_dns_zone_name" {
  value = "${aws_route53_zone.internal.name}"
}
