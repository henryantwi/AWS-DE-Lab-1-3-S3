variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name applied to all resource tags"
  type        = string
  default     = "data-platform"
}

variable "lab" {
  description = "Lab identifier applied to all resource tags"
  type        = string
  default     = "lab-1-3-s3"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Team or individual responsible for these resources"
  type        = string
  default     = "data-engineering-team"
}

variable "purpose" {
  description = "Business purpose of the resources"
  type        = string
  default     = "data-lake-foundation"
}

variable "cost_center" {
  description = "Cost centre for billing allocation"
  type        = string
  default     = "de-platform"
}
