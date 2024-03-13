* Added able to use ACL and lifecycle configuration.
* For able to use should be added `addon` key in map with folowing example.

(all additional keys ids etc. check into terraform documentation, module supported all functional of this resource)

    locals {
      buckets = {
        module-s3-test-sandbox = {
          tags = {
            Business-meaningful = "AWS_ToYou_FTest"
            ManagedBy           = "Terraform"
          }
          custom-policy          = {}
          roles_attach_access_rw = ["DSR-PowerDeveloperAccess", "DSR-PowerQAAccess"]
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
    }

## 1.0.1 (2023-02-13)




