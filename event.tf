resource "aws_cloudwatch_event_rule" "eventbridge_rule" {
  name        = "eventbridge_rule"
  description = "Event rule triggering Step Function"
  schedule_expression = "rate(1 minute)" # Run every day at noon UTC
}


resource "aws_iam_role" "eventbridge_target_role" {
  name = "eventbridge_target_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "events.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}
resource "aws_iam_policy" "eventbrigde_step_function_policy" {
  name = "eventbrigde_step_function_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "states:StartExecution",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_step_function_attachment" {
  role       = aws_iam_role.eventbridge_target_role.name
  policy_arn = aws_iam_policy.eventbrigde_step_function_policy.arn
}

# resource "aws_iam_policy" "lambda_invoke_policy" {
#   name = "lambda_invoke_policy"

#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect   = "Allow",
#         Action   = "lambda:InvokeFunction",
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "lambda_invoke_attachment" {
#   role       = aws_iam_role.eventbridge_target_role.name
#   policy_arn = aws_iam_policy.lambda_invoke_policy.arn
# }

resource "aws_cloudwatch_event_target" "step_function_target" {
  rule      = aws_cloudwatch_event_rule.eventbridge_rule.name
  arn       = aws_sfn_state_machine.step_function.arn
  role_arn  = aws_iam_role.eventbridge_target_role.arn
}

