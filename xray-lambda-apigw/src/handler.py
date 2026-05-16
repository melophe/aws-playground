import json
import os


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "message": "hello from x-ray enabled lambda",
            "env": os.environ.get("ENV", "dev"),
            "request_id": context.aws_request_id
        })
    }
