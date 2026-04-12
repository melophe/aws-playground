resource "aws_dynamodb_table" "orders" {
  name         = "${var.env}-orders"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "user_id"
  range_key = "order_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "order_id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  global_secondary_index {
    name            = "status-created_at-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  tags = {
    Name        = "${var.env}-orders"
    Environment = var.env
  }
}
