data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.${var.second_octet}.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_subnet" "public" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.${var.second_octet}.${count.index}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}

resource "aws_route_table" "public" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_subnet" "private" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.${var.second_octet}.${length(data.aws_availability_zones.available.names) * 2 + count.index}.0/24"

  tags = {
    Name = "private"
  }
}

resource "aws_route_table" "private" {
  count  = "${var.saving_mode == "true" ? 0 : length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    instance_id = "${element(aws_instance.nat.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${var.saving_mode == "true" ? 0 : length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

resource "aws_security_group" "nat_sg" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_security_group_rule" "nat_from_vpc" {
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.nat_sg.id}"
  to_port = 443
  type = "ingress"
  cidr_blocks = ["${aws_vpc.main.cidr_block}"]
}

resource "aws_security_group_rule" "nat_to_internet" {
  from_port = 443
  protocol = "tcp"
  security_group_id = "${aws_security_group.nat_sg.id}"
  to_port = 443
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "nat" {
  count          = "${var.saving_mode == "true" ? 0 : length(data.aws_availability_zones.available.names)}"
  ami           = "ami-024107e3e3217a248"
  instance_type = "t3.nano"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids = ["${aws_security_group.nat_sg.id}"]
  source_dest_check = false

  tags = {
    Name = "Nat ${count.index}"
  }
}

resource "aws_route53_zone" "public" {
  count = "${var.subdomain != "" ? 1 : 0}"
  name = "${var.subdomain}.${var.domain}"
}

resource "aws_route53_record" "public-ns" {
  count = "${var.subdomain != "" ? 1 : 0}"
  zone_id = "${var.root_domain_zone_id}"
  name    = "${var.subdomain}.${var.domain}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.public.name_servers.0}",
    "${aws_route53_zone.public.name_servers.1}",
    "${aws_route53_zone.public.name_servers.2}",
    "${aws_route53_zone.public.name_servers.3}",
  ]
}

resource "aws_route53_zone" "internal" {
  count = "${var.subdomain != "" ? 1 : 0}"
  name = "internal.${var.subdomain}.${var.domain}"
  vpc {
    vpc_id = "${aws_vpc.main.id}"
  }
}
