resource "aws_iam_role" "step_function_role" {
  name = "step_function_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "step_function_policy" {
  name = "step_function_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = "logs:CreateLogGroup",
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_attachment" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}

resource "aws_sfn_state_machine" "step_function" {
  name     = "step_function"
  role_arn = aws_iam_role.step_function_role.arn

  definition = <<DEFINITION
{
  "Comment": "An example of the Amazon States Language using Pass states",
  "StartAt": "Lambda1",
  "States": {
    "Lambda1": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_function.arn}",
      "ResultPath": "$.output1",
      "Next": "Lambda2"
    },
    "Lambda2": {
      "Type": "Task",
      "Resource": "${aws_lambda_function.lambda_function.arn}",
      "InputPath": "$.output1",
      "End": true
    }
  }
}
DEFINITION
}