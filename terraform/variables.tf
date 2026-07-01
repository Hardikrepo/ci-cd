variable "aws_region" {
  description = "AWS region for the S3 bucket (CloudFront itself is global)"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name used as the CloudFront origin"
  type        = string
}

variable "github_repository" {
  description = "GitHub \"owner/repo\" allowed to assume the deploy role, e.g. \"Hardikrepo/ci-cd\""
  type        = string
}

variable "allowed_ref" {
  description = "Git branch allowed to assume the deploy role and publish to prod"
  type        = string
  default     = "main"
}
