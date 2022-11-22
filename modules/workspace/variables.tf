variable "organization" {
  type        = string
  description = "The organization under which to create the workspace"
}

variable "tag_names" {
  type = list(string)
  description = "Tags to apply to the workspace"
  default = []
}

variable "tfe_oauth_token_id" {
    type = string
    description = "Github oauth token id for TFC"
}

variable "duration" {
  type = string
  description = "Time to hold the memory for in seconds (or with bash-friendly time unit suffix)"
  default = "60s"
}

variable "memory" {
  type        = string
  description = "Amount of memory to hold, in bytes (or with bash-friendly multiplier suffix)"
}

variable "workspace_name" {
  type        = string
  description = "The name of the workspace"
}

variable "workspace_repo_name" {
  type = string
  description = "Repo used for VCS-backed workspace"
}

variable "agent_pool_id" {
  type        = string
  description = "Agent pool ID to assign the workspace to"
  default     = null
}