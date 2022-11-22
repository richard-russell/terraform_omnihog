
resource "tfe_workspace" "workspace" {
  name         = var.workspace_name
  organization = var.organization
  tag_names    = var.tag_names
  auto_apply   = true
  execution_mode = var.agent_pool_id != null ? "agent" : "remote"
  agent_pool_id  = var.agent_pool_id
  vcs_repo {
    identifier     = var.workspace_repo_name
    oauth_token_id = var.tfe_oauth_token_id
  }
}

resource "tfe_variable" "duration" {
  key          = "duration"
  value        = var.duration
  category     = "terraform"
  workspace_id = tfe_workspace.workspace.id
  description  = "How long to hog the memory"
}

resource "tfe_variable" "memory" {
  key          = "memory"
  value        = var.memory
  category     = "terraform"
  workspace_id = tfe_workspace.workspace.id
  description  = "Amount of memory to hog"
}
