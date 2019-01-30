data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block = "10.${var.second_octet}.0.0/16"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.main.id}"
}

resource "aws_eip" "gw" {
  count      = "${length(data.aws_availability_zones.available.names)}"
  vpc        = true
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  subnet_id     = "${element(aws_subnet.nat.*.id, count.index)}"
  allocation_id = "${element(aws_eip.gw.*.id, count.index)}"
  depends_on = ["aws_internet_gateway.gw"]
}

resource "aws_subnet" "nat" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.${var.second_octet}.${count.index}.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "nat"
  }
}

resource "aws_route_table" "nat" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table_association" "nat" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.nat.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.nat.*.id, count.index)}"
}

resource "aws_subnet" "public" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.${var.second_octet}.${length(data.aws_availability_zones.available.names) + count.index}.0/24"
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
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
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
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${element(aws_nat_gateway.gw.*.id, count.index)}"
  }
}

resource "aws_route_table_association" "private" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
