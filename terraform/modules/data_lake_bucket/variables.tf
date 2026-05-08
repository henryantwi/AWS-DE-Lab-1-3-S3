variable "bucket_name" {
  description = "Name of the main data lake bucket"
  type        = string
}

variable "logging_bucket_id" {
  description = "Name of the access-log destination bucket"
  type        = string
}

variable "project" {
  description = "Project name for tagging"
  type        = string
}

variable "lab" {
  description = "Lab identifier for tagging"
  type        = string
}

variable "environment" {
  description = "Environment for governance tagging"
  type        = string
}

variable "owner" {
  description = "Owner for governance tagging"
  type        = string
}

variable "purpose" {
  description = "Purpose for governance tagging"
  type        = string
}

variable "cost_center" {
  description = "Cost centre for governance tagging"
  type        = string
}
