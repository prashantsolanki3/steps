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
# {
#   "Comment": "An example of the Amazon States Language using Pass states",
#   "StartAt": "Lambda1",
#   "States": {
#     "Lambda1": {
#       "Type": "Task",
#       "Resource": "${aws_lambda_function.lambda_function.arn}",
#       "ResultPath": "$.output1",
#       "Next": "Lambda2"
#     },
#     "Lambda2": {
#       "Type": "Task",
#       "Resource": "${aws_lambda_function.lambda_function.arn}",
#       "InputPath": "$.output1",
#       "End": true
#     }
#   }
# }
  definition = <<DEFINITION
{
  "Comment": "Import Step Function",
  "StartAt": "Lambda - ME - Create Temp Tables",
  "States": {
    "Lambda - ME - Create Temp Tables": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.lambda_function.arn}",
        "Payload": {
          "job_name": "Create temporary tables",
          "microservice": "MapEditor"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Wait - ME - Create tem tables"
    },
    "Wait - ME - Create tem tables": {
      "Type": "Wait",
      "Seconds": 2,
      "Next": "Lambda - Chceck - ME - Create tem tables"
    },
    "Lambda - Chceck - ME - Create tem tables": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.lambda_function.arn}",
        "Payload": {
          "job_name": "Create temporary tables",
          "microservice": "MapEditor"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Choice - ME - Create tem tables"
    },
    "Choice - ME - Create tem tables": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Payload.job_status",
          "StringMatches": "Succeed",
          "Next": "Lambda - ME - Create empty changeset"
        },
        {
          "Variable": "$.Payload.job_status",
          "StringMatches": "Failed",
          "Next": "Lambda - ME - Create tem tables"
        }
      ]
    },
    "Lambda - ME - Create empty changeset": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.lambda_function.arn}",
        "Payload": {
          "job_name": "Create empty changeset",
          "microservice": "MapEditor"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Wait - ME -  Create empty changeset"
    },
    "Wait - ME -  Create empty changeset": {
      "Type": "Wait",
      "Seconds": 2,
      "Next": "Lambda - Check - ME - Create empty changeset"
    },
    "Lambda - Check - ME - Create empty changeset": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "Parameters": {
        "Payload": {
          "job_name": "Create empty changeset",
          "microservice": "MapEditor"
        },
        "FunctionName": "${aws_lambda_function.lambda_function.arn}"
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "Next": "Choice - ME - Create empty changeset"
    },
    "Choice - ME - Create empty changeset": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.Payload.job_status",
          "StringMatches": "Succeed",
          "Next": "Lambda - MI - Ingest"
        },
        {
          "Variable": "$.Payload.job_status",
          "StringMatches": "Fail",
          "Next": "Lambda - ME - Create empty changeset"
        }
      ]
    },
    "Lambda - MI - Ingest": {
      "Type": "Task",
      "Resource": "arn:aws:states:::lambda:invoke",
      "OutputPath": "$.Payload",
      "Parameters": {
        "FunctionName": "${aws_lambda_function.lambda_function.arn}",
        "Payload": {
          "job_name": "Ingest",
          "microservice": "MapImporter"
        }
      },
      "Retry": [
        {
          "ErrorEquals": [
            "Lambda.ServiceException",
            "Lambda.AWSLambdaException",
            "Lambda.SdkClientException",
            "Lambda.TooManyRequestsException"
          ],
          "IntervalSeconds": 2,
          "MaxAttempts": 6,
          "BackoffRate": 2
        }
      ],
      "End": true
    }
  }
}
DEFINITION
}