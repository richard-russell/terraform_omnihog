provider "github" {
  token = var.github_token
}

provider "tfe" {
  hostname = var.tfe_hostname
}

provider "random" {}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.aws_default_tags
  }
}

# Random pet name to use in resource names
resource "random_pet" "prefix" {
  length = 2
  prefix = var.prefix
}

# Create OAUTH client to use for VCS-backed repos and attaching policy-sets
resource "tfe_oauth_client" "demo" {
  count            = var.oauth_client_token_id == null ? 1 : 0
  organization     = var.organization
  api_url          = "https://api.github.com"
  http_url         = "https://github.com"
  oauth_token      = var.github_token
  service_provider = "github"
}

locals {
  tfe_token_id = var.oauth_client_token_id != null ? var.oauth_client_token_id : tfe_oauth_client.demo[0].oauth_token_id
}

# Agent pools
resource "tfe_agent_pool" "test-agent-pool" {
  count        = var.pool_count
  name         = "${var.prefix}-${format("%04d", count.index + 1)}"
  organization = var.organization
}

resource "tfe_agent_token" "test-agent-token" {
  count         = var.pool_count
  agent_pool_id = tfe_agent_pool.test-agent-pool[count.index].id
  description   = "${var.prefix}-${format("%04d", count.index + 1)}"
}



# Workspaces
module "workspaces_1min" {
  count               = 10
  source              = "./modules/workspace"
  organization        = var.organization
  tfe_oauth_token_id  = local.tfe_token_id
  duration            = "60s"
  memory              = "50M"
  workspace_name      = "omnihog_1min_${count.index}"
  workspace_repo_name = var.workspace_repo_name
}

module "workspaces_2min" {
  count               = 10
  source              = "./modules/workspace"
  organization        = var.organization
  tfe_oauth_token_id  = local.tfe_token_id
  duration            = "120s"
  memory              = "100M"
  workspace_name      = "omnihog_2min_${count.index}"
  workspace_repo_name = var.workspace_repo_name
}

module "workspaces_5min" {
  count               = 10
  source              = "./modules/workspace"
  organization        = var.organization
  tfe_oauth_token_id  = local.tfe_token_id
  agent_pool_id       = tfe_agent_pool.test-agent-pool[0].id
  duration            = "300s"
  memory              = "400M"
  workspace_name      = "omnihog_5min_${count.index}"
  workspace_repo_name = var.workspace_repo_name
}
