
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
