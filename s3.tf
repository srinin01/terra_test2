resource "aws_s3_bucket" "sat_bucket" {
  bucket = "sat-bucket-11-13-srini"
  acl = "private"
}
resource "aws_s3_bucket" "test_bucket" {
  bucket = "sat-bucket-1-srini"
  acl = "private"
}
resource "aws_s3_bucket" "test_bucket2" {
  bucket = "sat-bucket-2-srini"
  acl = "private"
}