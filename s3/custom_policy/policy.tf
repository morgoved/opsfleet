resource "aws_iam_policy" "additional_policy" {
  for_each    = var.policy
  description = "Custom Policy ${each.key} for S3 bucket with ${var.bucket}"
  name        = "${var.bucket}-custom-${each.key}"
  path        = "/"
  policy      = each.value
}
