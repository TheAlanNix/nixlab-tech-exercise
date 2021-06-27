resource "aws_s3_bucket" "mongodb_backups" {
  bucket = "nixlab-mongodb-backups"
  acl    = "public-read"
}
