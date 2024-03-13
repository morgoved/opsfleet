data "aws_iam_policy_document" "rw" {
  for_each = var.buckets
  statement {
    sid = "VisualEditor0"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:*ObjectTagging",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.this[each.key].arn}",
      "${aws_s3_bucket.this[each.key].arn}/*",
    ]
  }
}

data "aws_iam_policy_document" "ro" {
  for_each = var.buckets
  statement {
    sid = "VisualEditor0"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:GetObjectTagging"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.this[each.key].arn}",
      "${aws_s3_bucket.this[each.key].arn}/*",
    ]
  }
}

resource "aws_iam_policy" "ro_bucket" {
  for_each    = var.buckets
  description = "Policy for allow RO S3 bucket with ${each.key}"
  name        = "${each.key}-ro"
  path        = "/"
  policy      = data.aws_iam_policy_document.ro[each.key].json
  depends_on  = [data.aws_iam_policy_document.ro, data.aws_iam_policy_document.rw]
  tags = merge(
    each.value.tags,
  )
}

resource "aws_iam_policy" "rw_bucket" {
  for_each    = var.buckets
  description = "Policy for allow RW S3 bucket with ${each.key}"
  name        = "${each.key}-rw"
  path        = "/"
  policy      = data.aws_iam_policy_document.rw[each.key].json
  depends_on  = [data.aws_iam_policy_document.ro, data.aws_iam_policy_document.rw]
  tags = merge(
    each.value.tags,
  )
}

module "custom_policy" {
  for_each = var.buckets
  source   = "./custom_policy"
  policy   = each.value.custom-policy
  bucket   = each.key
}
