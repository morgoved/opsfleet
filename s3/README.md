
### General

* Description: this module creates s3 bucket and roles with fixed ACL
* Created By: a.chernyaev@arammeem.com
* Module Dependencies:
    * missing
* Provider Dependencies:
    * aws: 4.54.0
* Terraform Version: ~> 1.3.7


### Usage

* Terraform (basic example):

```hcl
module "arm_s3_sa" {
  source = "./s3"
  buckets = module-s3-test-sandbox = {
                tags = {
                  Business-meaningful = "FTest"
                  ManagedBy           = "Terraform"
                }
                custom-policy          = {}
                roles_attach_access_rw = ["PowerDeveloperAccess", "PowerQAAccess"]
                roles_attach_access_ro = []
                addon = {
                  acl = {
                    acl = null
                    grants = [
                      {
                        permission = "READ"
                        type = "Group"
                        id = "xxxx"
                        uri = "xxx.com"
                      }
                    ]
                  }
                  lifecycle_rules = [
                    {
                      id = "rule-1"
                      filter = {
                        prefix = "logs/"
                      }
                      status = "Enabled"
                    },
                    {
                      id = "rule-2"
                      abort_incomplete_multipart_upload_days = 10
                      filter = {
                        prefix = "logs/"
                      }
                      status = "Enabled"
                      expiration = {
                          days = 90
                      }
                    }
                  ]
                }
            }
}
```
