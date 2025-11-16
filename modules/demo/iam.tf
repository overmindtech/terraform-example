data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    sid    = "Logs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:${data.aws_partition.current.partition}:logs:${local.region}:${local.account_id}:*"]
  }

  statement {
    sid    = "DataAccess"
    effect = "Allow"
    actions = [
      "dynamodb:*",
      "s3:*",
      "states:StartExecution",
      "events:PutEvents",
      "secretsmanager:GetSecretValue",
      "ssm:GetParameter",
      "sns:Publish",
      "sqs:SendMessage",
      "rds-data:ExecuteStatement",
      "rds-data:BatchExecuteStatement",
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${local.name_prefix}-lambda"
  policy = data.aws_iam_policy_document.lambda_policy.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "lambda" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda.arn
}

data "aws_iam_policy_document" "states_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.${local.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "step_functions" {
  name               = "${local.name_prefix}-states"
  assume_role_policy = data.aws_iam_policy_document.states_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "states_policy" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync",
      "events:PutEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "states" {
  role   = aws_iam_role.step_functions.id
  policy = data.aws_iam_policy_document.states_policy.json
}

data "aws_iam_policy_document" "bastion_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${local.name_prefix}-bastion"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "bastion_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${local.name_prefix}-bastion"
  role = aws_iam_role.bastion.name
}

data "aws_iam_policy_document" "scheduler_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["scheduler.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "scheduler" {
  name               = "${local.name_prefix}-scheduler"
  assume_role_policy = data.aws_iam_policy_document.scheduler_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "scheduler_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:StopInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "scheduler" {
  role   = aws_iam_role.scheduler.id
  policy = data.aws_iam_policy_document.scheduler_policy.json
}

