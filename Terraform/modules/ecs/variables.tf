variable "microservices" {
  description = "Configuration for microservices"
  type = map(object({
    port        = number
    cpu         = number
    memory      = number
    desired_count = number
    health_path = string
  }))
  default = {
    "users-microservice" = {
      port          = 8081
      cpu           = 256
      memory        = 512
      desired_count = 2
      health_path   = "/actuator/health"
    }
    "photo-microservice" = {
      port          = 8080
      cpu           = 256
      memory        = 512
      desired_count = 1
      health_path   = "/actuator/health"
    }
  }
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "photoapp-cluster"
}

variable "db_names" {
  description = "Map of service key to database name"
  type        = map(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS services"
  type        = list(string)
}

variable "ecs_sg_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "alb_target_group_arns" {
  description = "Map of microservice keys to ALB target group ARNs"
  type        = map(string)
}

variable "ecr_repository_urls" {
  description = "Map of microservice keys to ECR repository URLs"
  type        = map(string)
}

variable "db_endpoints" {
  description = "Map of service key to database endpoint hostname"
  type        = map(string)
}

variable "db_ports" {
  description = "Map of service key to database port"
  type        = map(number)
}

variable "db_secret_arns" {
  description = "Map of service key to Secrets Manager ARN containing DB credentials"
  type        = map(string)
}