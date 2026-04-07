import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    logger.info("event: %s", json.dumps(event))

    method = event["httpMethod"]
    path = event["path"]

    if method == "GET" and path == "/items":
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"items": [{"id": 1, "name": "sample"}]}),
        }

    if method == "POST" and path == "/items":
        body = json.loads(event.get("body") or "{}")
        return {
            "statusCode": 201,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"created": body}),
        }

    return {
        "statusCode": 404,
        "body": json.dumps({"message": "Not Found"}),
    }
