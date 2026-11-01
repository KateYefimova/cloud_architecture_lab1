resource "aws_iam_policy" "view_only" {
  name        = "SandboxViewOnlyPolicy"
  description = "Allows read-only access to resources for Milestone 1 demonstration."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowReadOnlyAccess"
        Effect   = "Allow"
        Action   = [
          "ec2:Describe*",
          "s3:Get*",
          "s3:List*",
          "rds:Describe*",
          "cloudformation:Describe*",
          "cloudformation:Get*",
          "vpc:Describe*"
        ]
        Resource = "*"
      }
    ]
  })
}