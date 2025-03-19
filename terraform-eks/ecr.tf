resource "aws_ecr_repository" "hello_world_ecr" {
  name = var.ecr_repository_name
  force_delete = true  # Ensures repository is deleted even if images exist

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repository_name
  }
}