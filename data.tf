# 現在の AWS アカウント
data "aws_caller_identity" "current" {}

# AWS ELB のサービス AWS アカウント（リージョン共通）
data "aws_elb_service_account" "service_account" {}

# バケット ACL に付与する CloudFront の被付与者 ID
data "aws_cloudfront_log_delivery_canonical_user_id" "cloudfront" {}

# 現在の AWS アカウントの被付与者 ID
data "aws_canonical_user_id" "current" {}

# 現在のリージョン
data "aws_region" "current" {}
