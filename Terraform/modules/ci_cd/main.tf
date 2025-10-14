resource "aws_s3_bucket" "artifacts" {
  bucket = "${var.cluster_name}-${var.microservice}-artifacts"
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name = "${var.cluster_name}-${var.microservice}-codepipeline-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codepipeline.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${var.cluster_name}-${var.microservice}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject","s3:GetObjectVersion","s3:PutObject","s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["codebuild:BatchGetBuilds","codebuild:StartBuild"],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = ["codestar-connections:UseConnection"],
        Resource = [var.connection_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition", 
          "ecs:RegisterTaskDefinition",
          "ecs:UpdateService",
          "ecs:DescribeClusters",
          "ecs:ListTasks",
          "ecs:DescribeTasks"
        ],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = ["iam:PassRole"],
        Resource = ["*"],
        Condition = { StringLikeIfExists = { "iam:PassedToService": "ecs-tasks.amazonaws.com" } }
      }
    ]
  })
}

resource "aws_iam_role" "codebuild_role" {
  name = "${var.cluster_name}-${var.microservice}-codebuild-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "codebuild.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${var.cluster_name}-${var.microservice}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],
        Resource = ["*"]
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject","s3:GetObject","s3:GetObjectVersion","s3:ListBucket"],
        Resource = [
          aws_s3_bucket.artifacts.arn,
          "${aws_s3_bucket.artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = ["ecr:BatchCheckLayerAvailability","ecr:CompleteLayerUpload","ecr:InitiateLayerUpload","ecr:PutImage","ecr:UploadLayerPart","ecr:BatchGetImage","ecr:DescribeRepositories"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_codebuild_project" "build" {
  name         = "${var.cluster_name}-${var.microservice}-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
    environment_variable {
      name  = "AWS_REGION"
      value = var.region
    }
    environment_variable {
      name  = "IMAGE_REPO_URI"
      value = var.repository_url
    }
    environment_variable {
      name  = "SERVICE_NAME"
      value = var.microservice
    }
  }

  source {
    type         = "CODEPIPELINE"
    buildspec    = "${var.build_context}/buildspec.yml"
    insecure_ssl = false
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/codebuild/${var.cluster_name}-${var.microservice}"
      stream_name = "build"
    }
  }
}

resource "aws_codepipeline" "pipeline" {
  name     = "${var.cluster_name}-${var.microservice}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.artifacts.bucket
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.connection_arn
        FullRepositoryId = var.source_repo
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "DeployToECS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
        FileName    = "imagedefinitions.json"
      }
    }
  }
}


