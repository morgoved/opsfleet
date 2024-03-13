output "policy_custom_arn" {
  value = { for k, v in aws_iam_policy.additional_policy : k => v.arn }
}
