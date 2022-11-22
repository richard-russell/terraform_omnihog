variable "agent_cpu" {
  type        = number
  default     = 1024
  description = "The CPU capacity per agent container."
}

variable "agent_memory" {
  type        = number
  default     = 2048
  description = "The memory capacity per agent container."
}

variable "aws_default_tags" {
  description = "Common tags for AWS resources"
  type        = map(string)
}

variable "aws_region" {
  description = "The region where the resources are created."
  default     = "us-east-2"
}

variable "github_token" {
  type        = string
  description = "github oauth token for creating repos and attaching policy set"
}

variable "ip_cidr_vpc" {
  description = "IP CIDR for VPC"
  default     = "172.31.0.0/16"
}

variable "ip_cidr_agent_subnet" {
  description = "IP CIDR for tfc-agent subnet"
  default     = "172.31.16.0/24"
}

variable "oauth_client_token_id" {
  type        = string
  description = "Existing OAUTH token to re-use. If null, create a new one"
  default     = null
}

variable "organization" {
  type        = string
  description = "TFC/TFE organization used for the demo"
}

variable "pool_count" {
  type        = number
  default     = 1
  description = "The number of agent pools and associated ECS services to create."
}

variable "agent_per_pool_count" {
  type        = number
  default     = 4
  description = "The number of agents per agent pools and associated containers per ECS service."
}

variable "prefix" {
  type        = string
  default     = "tfc-sentinel-demo"
  description = "String prefix for the workspace and policy-sets"
}

variable "tfe_hostname" {
  type = string
}

variable "workspace_repo_name" {
  type        = string
  description = "Github repo to back all workspaces"
}
