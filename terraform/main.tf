data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_extract_lambda" {
  name               = "iam_for_extract_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "extract_lambda_script" {
  type        = "zip"
  source_file = "${path.module}/../ETL/extract/extract.py"
  output_path = "${path.module}/../ETL/extract/extract_lambda_payload.zip"
}

resource "aws_lambda_function" "extract_lambda" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename      = "${path.module}/../ETL/extract/extract_lambda_payload.zip"
  function_name = "extract"
  role          = aws_iam_role.iam_for_extract_lambda.arn
  handler       = "extract.extract"

  source_code_hash = data.archive_file.extract_lambda_script.output_base64sha256

  runtime = "python3.11"

}

resource "aws_s3_bucket" "raw_data" {
  bucket = "imdb-etl-raw-data-bucket"
}

resource "aws_s3_object" "object" {
  bucket = "imdb-etl-raw-data-bucket"
  key    = "movies.csv"
  source = "${path.module}/../data/movies.csv"
}