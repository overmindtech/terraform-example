import json
import os
import time
import uuid

import boto3

s3 = boto3.client("s3")


def handler(event, _context):
    recipe_pk = json.loads(event.get("body") or "{}").get("recipe_pk", "RECIPE#unknown")
    key = f"uploads/{int(time.time())}-{uuid.uuid4()}.jpg"
    upload = s3.generate_presigned_post(
        Bucket=os.environ["UPLOADS_BUCKET"],
        Key=key,
        ExpiresIn=300,
        Conditions=[["starts-with", "$Content-Type", "image/"]],
    )
    message = {
        "bucket": os.environ["UPLOADS_BUCKET"],
        "object_key": key,
        "recipe_pk": recipe_pk,
        "recipe_sk": "CREATED#0",
    }
    return {
        "statusCode": 200,
        "headers": {
            "content-type": "application/json",
        },
        "body": json.dumps({"upload": upload, "notification_message": message}),
    }

