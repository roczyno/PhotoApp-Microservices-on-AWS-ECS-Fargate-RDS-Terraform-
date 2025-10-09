provider "aws" {
  region = "eu-west-1"
}


module "networking" {
  source = "./modules/networking"
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr  
}

module "ecr" {
  source = "./modules/ecr"
  microservices = var.microservices
  cluster_name = var.cluster_name
}

module "database_users" {
  source = "./modules/database"
  cluster_name         = "${var.cluster_name}-users"
  db_instance_class    = var.db_instance_class
  db_name              = var.dbs["users-microservice"].db_name
  db_username          = var.dbs["users-microservice"].db_username
  db_password          = var.dbs["users-microservice"].db_password
  db_subnet_group_name = module.networking.db_subnet_group_name
  rds_sg_id            = module.networking.rds_sg_id
}

module "database_albums" {
  source = "./modules/database"
  cluster_name         = "${var.cluster_name}-albums"
  db_instance_class    = var.db_instance_class
  db_name              = var.dbs["photo-microservice"].db_name
  db_username          = var.dbs["photo-microservice"].db_username
  db_password          = var.dbs["photo-microservice"].db_password
  db_subnet_group_name = module.networking.db_subnet_group_name
  rds_sg_id            = module.networking.rds_sg_id
}

module "alb" {
  source          = "./modules/alb"
  cluster_name    = var.cluster_name
  microservices   = var.microservices
  public_subnet_ids = module.networking.public_subnet_ids
  vpc_id            = module.networking.vpc_id
  alb_sg_id         = module.networking.alb_sg_id
}

module "ecs" {
  source                 = "./modules/ecs"
  cluster_name           = var.cluster_name
  microservices          = var.microservices
  private_subnet_ids     = module.networking.private_subnet_ids
  ecs_sg_id              = module.networking.ecs_sg_id
  alb_target_group_arns  = module.alb.target_groups
  ecr_repository_urls    = module.ecr.repositories
  db_names               = {
    "users-microservice" = var.dbs["users-microservice"].db_name
    "photo-microservice" = var.dbs["photo-microservice"].db_name
  }
  db_endpoints           = {
    "users-microservice" = module.database_users.address
    "photo-microservice" = module.database_albums.address
  }
  db_ports               = {
    "users-microservice" = module.database_users.port
    "photo-microservice" = module.database_albums.port
  }
  db_secret_arns         = {
    "users-microservice" = module.database_users.secret_arn
    "photo-microservice" = module.database_albums.secret_arn
  }
}

module "monitoring" {
  source            = "./modules/monitoring"
  cluster_name      = var.cluster_name
  microservices     = var.microservices
  ecs_cluster_name  = module.ecs.cluster_name
  ecs_service_names = module.ecs.services
  rds_instance_ids  = {
    "users-microservice" = module.database_users.rds_id
    "photo-microservice" = module.database_albums.rds_id
  }
}



