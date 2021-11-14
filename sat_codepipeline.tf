provider "aws" {
  region = "us-east-1"
}
resource "aws_codestarconnections_connection" "github" {
  name          = "sat_connection"
  provider_type = "GitHub"
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
    secret_token = "1234567890"
  }
    filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}
resource "github_repository_webhook" "github_hook" {
  repository = "srinin01/terra_test2"

  configuration {
    url          = aws_codepipeline_webhook.codepipeline_webhook.url
    content_type = "json"
    insecure_ssl = false
    secret       = "1234567890"
  }

  events = ["push"]
}
