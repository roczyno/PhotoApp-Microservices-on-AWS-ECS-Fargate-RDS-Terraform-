variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "photoapp-cluster"
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for alarm dimensions"
  type        = string
}

variable "ecs_service_names" {
  description = "Map of microservice keys to ECS service names"
  type        = map(string)
}

variable "rds_instance_id" {
  description = "RDS instance identifier for alarm dimensions (legacy single DB)"
  type        = string
  default     = null
}

variable "rds_instance_ids" {
  description = "Map of per-service RDS instance identifiers"
  type        = map(string)
  default     = {}
}

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