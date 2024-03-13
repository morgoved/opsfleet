#
# ~ Copyright © 2023 Aram Meem Company Limited.  All Rights Reserved.
#
resource "aws_iam_role_policy_attachment" "service_account" {
  count      = length(var.service_account_policy_arns)
  policy_arn = var.service_account_policy_arns[count.index]
  role       = var.role
}
