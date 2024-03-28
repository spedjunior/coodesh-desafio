resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
  depends_on = [ aws_s3_bucket_ownership_controls.ownership_controls ]
}

resource "null_resource" "upload_script" {
  provisioner "local-exec" {
    command = "bash ./scripts/upload_site.sh ${aws_s3_bucket.bucket.id}"
  }
  depends_on = [aws_s3_bucket.bucket]
}