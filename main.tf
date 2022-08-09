###############
# ALB
###############
resource "aws_s3_bucket" "alb_logs" {
  bucket = var.alb_logs_bucket_name # グローバルで一意なバケット名
}

resource "aws_s3_bucket_policy" "alb" {
  bucket = aws_s3_bucket.alb_logs.bucket
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ALB
      {
        Sid    = "ALBAccessLogWrite",
        Effect = "Allow",
        Principal = {
          AWS = data.aws_elb_service_account.service_account.arn // リージョンで固定の ELB サービス AWS アカウント ID
        },
        Action = "s3:PutObject",
        Resource = [
          "arn:aws:s3:::${var.alb_logs_bucket_name}/${var.alb_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
          # ALB が複数ある場合はここに列挙する
        ]
      },
    ]
  })
}

###############
# CloudFront
###############
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = var.cloudfront_logs_bucket_name # グローバルで一意なバケット名
}

resource "aws_s3_bucket_acl" "cloudfront_acl" {
  bucket = aws_s3_bucket.cloudfront_logs.bucket

  access_control_policy {
    # CloudFront からのアクセスを許可
    grant {
      grantee {
        id   = data.aws_cloudfront_log_delivery_canonical_user_id.cloudfront.id
        type = "CanonicalUser"
      }
      permission = "FULL_CONTROL"
    }

    owner {
      id = data.aws_canonical_user_id.current.id
    }
  }
}

###############
# GuardDuty
###############
resource "aws_guardduty_detector" "main" {} // Detector がある場合はコメントアウトする
resource "aws_kms_key" "main" {}

resource "aws_s3_bucket" "guardduty_logs" {
  bucket = var.guardduty_logs_bucket_name # グローバルで一意なバケット名
}

resource "aws_s3_bucket_policy" "guardduty" {
  bucket = aws_s3_bucket.guardduty_logs.bucket
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowGuardDutygetBucketLocation",
        Effect : "Allow",
        Principal : {
          Service : "guardduty.amazonaws.com"
        },
        Action : "s3:GetBucketLocation",
        Resource : "arn:aws:s3:::${var.guardduty_logs_bucket_name}",
        Condition : {
          StringEquals : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id,
            // Detector がある場合は <SourceDetectorID> 箇所を変更してコメントを外す
            # "aws:SourceArn" : "arn:aws:guardduty:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:detector/<SourceDetectorID>"
            // Detector を Terraform で作る場合、既存の場合はコメントにする
            "aws:SourceArn" : aws_guardduty_detector.main.arn
          }
        }
      },
      {
        Sid : "AllowGuardDutyPutObject",
        Effect : "Allow",
        Principal : {
          Service : "guardduty.amazonaws.com"
        },
        Action : "s3:PutObject",
        Resource : "arn:aws:s3:::${var.guardduty_logs_bucket_name}/${var.guardduty_logs_prefix}/*",
        Condition : {
          StringEquals : {
            "aws:SourceAccount" : data.aws_caller_identity.current.account_id,
            // Detector がある場合は <SourceDetectorID> 箇所を変更してコメントを外す
            # "aws:SourceArn" : "arn:aws:guardduty:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:detector/<SourceDetectorID>"
            // Detector を Terraform で作る場合、既存の場合はコメントにする
            "aws:SourceArn" : aws_guardduty_detector.main.arn
          }
        }
      },
      {
        Sid : "DenyUnencryptedUploadsThis is optional",
        Effect : "Deny",
        Principal : {
          Service : "guardduty.amazonaws.com"
        },
        Action : "s3:PutObject",
        Resource : "arn:aws:s3:::${var.guardduty_logs_bucket_name}/${var.guardduty_logs_prefix}/*",
        Condition : {
          StringNotEquals : {
            "s3:x-amz-server-side-encryption" : "aws:kms"
          }
        }
      },
      {
        Sid : "DenyIncorrectHeaderThis is optional",
        Effect : "Deny",
        Principal : {
          Service : "guardduty.amazonaws.com"
        },
        Action : "s3:PutObject",
        Resource : "arn:aws:s3:::${var.guardduty_logs_bucket_name}/${var.guardduty_logs_prefix}/*",
        Condition : {
          StringNotEquals : {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" : aws_kms_key.main.arn
          }
        }
      },
      {
        Sid : "DenyNon-HTTPS",
        Effect : "Deny",
        Principal : "*",
        Action : "s3:*",
        Resource : "arn:aws:s3:::${var.guardduty_logs_bucket_name}/${var.guardduty_logs_prefix}/*",
        Condition : {
          Bool : {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}
