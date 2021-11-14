provider "aws" {
  region = "us-east-1"
}
resource "aws_codestarconnections_connection" "github" {
  name          = "sat_connection"
  provider_type = "GitHub"
}
data "template_file" "buildspec" {
  template = "${file("buildspec.yml")}"
}

resource "aws_codebuild_project" "sat_proj" {
  name = "sat_project"
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false
    type                        = "LINUX_CONTAINER"
  }
   source {
    buildspec           = data.template_file.buildspec.rendered
    git_clone_depth     = 0
    insecure_ssl        = false
    report_build_status = false
    type                = "CODEPIPELINE"
  }
  service_role = aws_iam_role.sat_build_role.arn
}
resource "aws_s3_bucket" "sat_bucket" {
  bucket = "sat-bucket-11-13-srini"
  acl = "private"
}
resource "aws_iam_role" "sat_role" {
  name = "sat_role"
  assume_role_policy = <<EOF
{
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "codepipeline.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
}
EOF
}
resource "aws_iam_role" "sat_build_role" {
  name = "sat_build_role"
  assume_role_policy = <<EOF
{
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
}
EOF
}
resource "aws_iam_role_policy" "sat_policy" {
  name = "sat_policy"
  role = aws_iam_role.sat_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${aws_s3_bucket.sat_bucket.arn}",
        "${aws_s3_bucket.sat_bucket.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "codestar-connections:UseConnection",
      "Resource": "${aws_codestarconnections_connection.github.arn}"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "sat_codepipeline" {
  name     = "sat_codepipeline"
  role_arn = aws_iam_role.sat_role.arn #create this role
  artifact_store {
    location = aws_s3_bucket.sat_bucket.bucket
    type     = "S3"
  }
  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      provider = "CodeStarSourceConnection"
      version = "1"
      output_artifacts = ["SourceArtifact"]
      configuration = {
        ConnectionArn = aws_codestarconnections_connection.github.arn
        FullRepositoryId = "srinin01/terra_test2"
        BranchName = "main"
        DetectChanges = "true"
      }
    }
  }
  stage {
    name = "Build"
    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      provider = "CodeBuild"
      version = 1
      configuration = {
        ProjectName = "sat_proj"
      }
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
    }

  }

}

resource "aws_codepipeline_webhook" "codepipeline_webhook" {
  name = "webhook_github_sat"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = aws_codepipeline.sat_codepipeline.name
  authentication_configuration {
    secret_token = random_string.github_secret.result
  }
    filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}
# resource "github_repository_webhook" "github_hook" {
#   repository = "terra_test2"

#   configuration {
#     url          = aws_codepipeline_webhook.codepipeline_webhook.url
#     content_type = "json"
#     insecure_ssl = false
#     secret       = random_string.github_secret.result
#   }

#   events = ["push"]
# }
resource "random_string" "github_secret" {
  length  = 99
  special = false
}
