variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  default     = "20c17ce1-c880-4374-ab18-0c3a72158cf7"
}

variable "project_code" {
  description = "Short project code"
  type        = string
  default     = "dam"
}

variable "project_name" {
  description = "Full project name"
  type        = string
  default     = "Datadog Azure Monitoring"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "Canada Central"
}