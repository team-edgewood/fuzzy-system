resource "aws_instance" "example" {
  ami           = "ami-00035f41c82244dab"
  instance_type = "t2.micro"
}
