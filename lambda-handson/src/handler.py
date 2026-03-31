import json
import logging
import os

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))


def lambda_handler(event, context):
    
    logger.info("Received event: %s", json.dumps(event))

    name = event.get("name", "World")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Hello, {name}!"}),
    }
