output "cluster_arn" {
  value = "${aws_ecs_cluster.cluster.arn}"
}
output "cluster_name" {
  value = "${aws_ecs_cluster.cluster.name}"
}
output "ecs_role_arn" {
  value = "${aws_iam_role.ecs_role.arn}"
}
