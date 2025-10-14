variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "microservice" {
  description = "Name of the microservice, e.g., users-microservice"
  type        = string
}

variable "repository_url" {
  description = "ECR repo URL for this microservice"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name to deploy, e.g., <cluster>-users-microservice-service"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "connection_arn" {
  description = "CodeStar Connections ARN"
  type        = string
}

variable "source_repo" {
  description = "GitHub repo in owner/name format"
  type        = string
}

variable "source_branch" {
  description = "Branch to build"
  type        = string
}

variable "build_context" {
  description = "Relative path to the service folder containing dockerfile and buildspec.yml"
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ECS task execution role ARN for CodePipeline to pass to ECS"
  type        = string
}


