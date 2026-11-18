variable "project_id" {
  description = "Existing GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "asia-south1"
}

variable "zone" {
  description = "GCP Zone for Jenkins VM"
  type        = string
  default     = "asia-south1-a"
}