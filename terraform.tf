terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "5.7.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.31.0"
    }
  }
}
