resource "aws_ecr_repository" "main" {
  name                 = "${var.project}-${var.service}"
  image_tag_mutability = var.image_tag_mutability == true ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }
}

locals {
  aws_accounts_arns = [for account_id in var.account_ids : "arn:aws:iam::${account_id}:root"]
}

data "aws_iam_policy_document" "main" {
  statement {
    sid    = "AccountsPull"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.aws_accounts_arns
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
  }

  statement {
    sid    = "AccountsPush"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = local.aws_accounts_arns
    }

    actions = [
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload"
    ]
  }
}

resource "aws_ecr_repository_policy" "main" {
  repository = aws_ecr_repository.main.name
  policy     = data.aws_iam_policy_document.main.json
}

resource "aws_iam_user" "main" {
  name = "${var.project}-${var.service}-ecr"
}

resource "aws_iam_user_policy" "main" {
  name = "${var.project}-${var.service}-ecr-policy"
  user = aws_iam_user.main.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.main.arn
      }
    ]
  })
}
