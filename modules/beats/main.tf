resource "aws_s3_bucket" "functionbeat-deploy" {
  bucket = "pttp-test-functionbeat-deploy"
  acl    = "private"

  tags = {
    Name        = "My bucket"
    Environment = "Dev"
  }
}