resource "aws_ecr_repository" "microservices" {
  for_each             = var.microservices
  name                 = "${var.cluster_name}-${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.cluster_name}-${each.key}"
    Service     = each.key
  }
}

resource "aws_ecr_lifecycle_policy" "microservices" {
  for_each   = var.microservices
  repository = aws_ecr_repository.microservices[each.key].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}