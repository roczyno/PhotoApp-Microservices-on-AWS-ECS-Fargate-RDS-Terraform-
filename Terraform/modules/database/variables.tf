variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "photoapp-cluster"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "Name of the database"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
  default     = "changeme123!"
}

variable "db_subnet_group_name" {
  description = "Database subnet group name"
  type        = string
}

variable "rds_sg_id" {
  description = "RDS security group ID"
  type        = string
}