variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "microservices" {
  description = "Configuration for microservices"
  type = map(object({
    port          = number
    cpu           = number
    memory        = number
    desired_count = number
    health_path   = string
  }))
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "dbs" {
  description = "Per-service database settings"
  type = map(object({
    db_name     = string
    db_username = string
    db_password = string
  }))
}
