#
# ~ Copyright © 2023 Aram Meem Company Limited. All Rights Reserved.
#
output "s3_bucket_arn" {
  value = { for k, v in aws_s3_bucket.this : k => v.arn }
}

output "policy_rw" {
  value = { for k, v in aws_iam_policy.rw_bucket : k => v.arn }
}

output "policy_ro" {
  value = { for k, v in aws_iam_policy.ro_bucket : k => v.arn }
}

output "policy_custom_arn" {
  value = { for k, v in module.custom_policy : k => v.policy_custom_arn }
}
