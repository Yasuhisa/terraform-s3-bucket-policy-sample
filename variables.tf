variable "alb_logs_bucket_name" {
  description = "ALB Logs Bucket Name. Required Global Unique Name."
  type        = string
  default     = "example" // FIXME: 一意の名前に変更してください。
}

variable "alb_logs_prefix" {
  description = "ALB Logs Prefix."
  type        = string
  default     = "example" // 任意のプレフィックスに変更してください。
}

variable "cloudfront_logs_bucket_name" {
  description = "CloudFront Logs Bucket Name. Required Global Unique Name."
  type        = string
  default     = "example" // FIXME: 一意の名前に変更してください。
}

variable "guardduty_logs_bucket_name" {
  description = "GuardDuty Logs Bucket Name. Required Global Unique Name."
  type        = string
  default     = "example" // FIXME: 一意の名前に変更してください。
}

variable "guardduty_logs_prefix" {
  description = "GuardDuty Logs Prefix."
  type        = string
  default     = "example" // 任意のプレフィックスに変更してください。
}
