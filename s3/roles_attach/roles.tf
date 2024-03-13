resource "aws_iam_role_policy" "roles_attach_ro" {
  count  = length(var.roles_ro)
  name   = "s3-bucket-${var.bucket}-${var.roles_ro[count.index]}-ro"
  policy = var.policy_ro_json
  role   = var.roles_ro[count.index]
}

resource "aws_iam_role_policy" "roles_attach_rw" {
  count  = length(var.roles_rw)
  name   = "s3-bucket-${var.bucket}-${var.roles_rw[count.index]}-rw"
  policy = var.policy_rw_json
  role   = var.roles_rw[count.index]
}
