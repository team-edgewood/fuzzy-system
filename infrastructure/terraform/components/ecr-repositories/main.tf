resource "aws_ecr_repository" "repo" {
  name = "hello-world"
}
resource "aws_ecr_repository" "cd-repo" {
  name = "cd"
}
