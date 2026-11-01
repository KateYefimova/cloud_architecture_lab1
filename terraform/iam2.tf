# Trust Policy, яка визначає, хто може припускати цю роль
data "aws_iam_policy_document" "assume_role_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::667052343720:root"] # Дозволяє іншій сутності/користувачу в цьому ж акаунті приймати роль
    }
  }
}

# Створення самої IAM-ролі
resource "aws_iam_role" "assumable_role" {
  name               = "SandboxAssumableReadOnlyRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role_trust.json
  description        = "A role with view-only access that can be assumed by another principal."
}

# Прикріплення створеної раніше View-Only політики до цієї ролі
resource "aws_iam_role_policy_attachment" "attach_view_only" {
  role       = aws_iam_role.assumable_role.name
  policy_arn = aws_iam_policy.view_only.arn
}