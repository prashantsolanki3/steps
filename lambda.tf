resource "null_resource" "pip_install" {
  provisioner "local-exec" {
    command = "/opt/homebrew/bin/pip3 install -t ${path.module} -r requirements.txt"
    working_dir = "${path.module}/lambda"
  }
}

resource "null_resource" "lambda_zip" {
  depends_on = [ null_resource.pip_install ]
  provisioner "local-exec" {
    command = "zip -r ../payload.zip ."
    working_dir = "${path.module}/lambda"
  }
}

resource "aws_lambda_function" "lambda_function" {
  depends_on = [ null_resource.lambda_zip ]
  filename      = "payload.zip"  # Path to your Lambda function code
  function_name = "lambda_function"
  role          = aws_iam_role.lambda_role.arn  # Update with your Lambda role ARN
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"  # Adjust based on your Lambda runtime
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = "logs:CreateLogGroup",
      Resource = "arn:aws:logs:*:*:*"
    }, {
      Effect   = "Allow",
      Action   = "logs:CreateLogStream",
      Resource = "arn:aws:logs:*:*:*"
    }, {
      Effect   = "Allow",
      Action   = "logs:PutLogEvents",
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}