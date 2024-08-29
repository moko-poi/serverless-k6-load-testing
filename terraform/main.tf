provider "aws" {
  region = "ap-northeast-1"
}

# Lambda関数
resource "aws_lambda_function" "k6_lambda" {
  function_name = "k6-load-test"
  handler       = "bootstrap"  # カスタムランタイムを使用
  runtime       = "provided.al2"  # Amazon Linux 2のカスタムランタイム
  role          = aws_iam_role.lambda_exec.arn

  memory_size = 1024
  timeout     = 900  # 最大15分

  # ZIPファイルとしてデプロイパッケージを指定する場合
  filename         = "../lambda/k6_lambda.zip"  # デプロイパッケージのパス
  source_code_hash = filebase64sha256("../lambda/k6_lambda.zip")
}

# IAM
resource "aws_iam_role" "lambda_exec" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      }
    ]
  })
}

# Step Functionsの実行ロールを定義
resource "aws_iam_role" "step_functions_exec" {
  name = "step-functions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

# Lambda関数の呼び出しを許可するポリシーを作成
resource "aws_iam_role_policy" "step_functions_lambda_invoke" {
  role = aws_iam_role.step_functions_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = aws_lambda_function.k6_lambda.arn
      }
    ]
  })
}

# 追加でAWSのマネージドポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "step_functions_basic_execution" {
  role       = aws_iam_role.step_functions_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  role       = aws_iam_role.step_functions_exec.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_sfn_state_machine" "k6_state_machine" {
  name     = "k6LoadTestStateMachine"
  role_arn = aws_iam_role.step_functions_exec.arn

  definition = <<DEFINITION
  {
    "StartAt": "RunK6Test",
    "States": {
      "RunK6Test": {
        "Type": "Map",
        "ItemsPath": "$",
        "MaxConcurrency": 1000,
        "Iterator": {
          "StartAt": "InvokeK6Lambda",
          "States": {
            "InvokeK6Lambda": {
              "Type": "Task",
              "Resource": "${aws_lambda_function.k6_lambda.arn}",
              "Parameters": {
                "Payload.$": "$"
              },
              "End": true
            }
          }
        },
        "End": true
      }
    }
  }
  DEFINITION
}
