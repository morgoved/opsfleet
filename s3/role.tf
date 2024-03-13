module "roles_attach" {
  for_each       = var.buckets
  source         = "./roles_attach"
  roles_ro       = each.value.roles_attach_access_ro
  roles_rw       = each.value.roles_attach_access_rw
  policy_ro_json = data.aws_iam_policy_document.ro[each.key].json
  policy_rw_json = data.aws_iam_policy_document.rw[each.key].json
  bucket         = each.key
  depends_on     = [aws_s3_bucket.this]
}
