variable "aws_region" {
  description = "AWS region for the S3 bucket (CloudFront itself is global)"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Globally-unique S3 bucket name used as the CloudFront origin"
  type        = string
}

variable "gitlab_oidc_url" {
  description = "GitLab OIDC issuer URL (use https://gitlab.com, or your self-managed instance URL)"
  type        = string
  default     = "https://gitlab.com"
}

variable "gitlab_project_path" {
  description = "GitLab project path allowed to assume the deploy role, e.g. \"my-group/my-static-site\""
  type        = string
}

variable "allowed_ref" {
  description = "Git branch allowed to assume the deploy role and publish to prod"
  type        = string
  default     = "main"
}
