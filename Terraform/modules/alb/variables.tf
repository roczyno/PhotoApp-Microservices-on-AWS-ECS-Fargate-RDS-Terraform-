variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "photoapp-cluster"
}

variable "public_subnet_ids" {
  description = "IDs of public subnets for ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID for target groups"
  type        = string
}

variable "alb_sg_id" {
  description = "Security group ID for ALB"
  type        = string
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
      desired_count = 1
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