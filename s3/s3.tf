resource "aws_s3_bucket" "this" {
  for_each = var.buckets
  bucket   = each.key
  tags = merge(
    each.value.tags,
  )
}

module "addon" {
  for_each   = var.buckets
  source     = "./addon"
  addon      = try(each.value.addon, {})
  bucket_id  = aws_s3_bucket.this[each.key].id
  depends_on = [aws_s3_bucket.this]
}

