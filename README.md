# terraform_omnihog
Test queueing and memory reporting on TFE by creating workspaces to eat up memory on the workers.

This repo creates sets of VCS-backed workspaces, a specified number of agent pool, and optionally assigns sets of workspaces to agent pools.

The test workspaces should be VCS-backed to your local fork of the accompanying [Terraform Worker Ramhog](https://github.com/richard-russell/terraform_worker_ramhog) repository.

Terraform code to deploy ECS on AWS fargate borrowed from [Andy Assareh's Terraform Cloud Agent examples](https://github.com/assareh/tfc-agent/blob/master/tfc-agent-ecs/producer/main.tf).


## Disclaimer
“By using the software in this repository (the “Software”), you acknowledge that: (1) the Software is still in development, may change, and has not been released as a commercial product by HashiCorp and is not currently supported in any way by HashiCorp; (2) the Software is provided on an “as-is” basis, and may include bugs, errors, or other issues; (3) the Software is NOT INTENDED FOR PRODUCTION USE, use of the Software may result in unexpected results, loss of data, or other unexpected results, and HashiCorp disclaims any and all liability resulting from use of the Software; and (4) HashiCorp reserves all rights to make all decisions about the features, functionality and commercial release (or non-release) of the Software, at any time and without any obligation or liability whatsoever."