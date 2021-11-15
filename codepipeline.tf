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
        ProjectName = "sat_project"
      }
      input_artifacts = ["SourceArtifact"]
      output_artifacts = ["BuildArtifact"]
    }

  }

}
