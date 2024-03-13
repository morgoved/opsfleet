variable "addon" {
  type = any
}

variable "bucket_id" {
  type = any
}

variable "acl" {
  description = "(Optional) The canned ACL to apply. Conflicts with `grant`"
  type        = string
  default     = null
}
