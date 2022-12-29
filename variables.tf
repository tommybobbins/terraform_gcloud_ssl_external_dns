// Configure the Google Cloud provider

variable "region" {
  description = "Google Cloud region"
  default     = "europe-west2"
}

variable "project" {
  description = "Google Cloud Project Name"
  default     = "my-project-name"
}

variable "credentials_file" {
  description = "Google Cloud Credentials json file"
  default     = "credentials.json"
}

variable "env" {
  description = "Project environment"
  default     = "dev"
}

variable "alias" {
  description = "Project alias"
  default     = "gb"
}

variable "cost_centre" {
  description = "Project Cost Centre"
  default     = "costly"
}

variable "thisproject" {
  description = "Project Name"
  default     = "projectly"
}

locals {
  project_labels = {
    "env"         = var.env
    "alias"       = var.alias
    "cost_centre" = var.cost_centre
    "project"     = var.thisproject
    "gcp_project" = var.project
  }
  domain_name    = replace(var.domain_name,".","-")
}

variable "domain_name" {
  description = "Domain name"
  default     = "test.chegwin.org"
}
