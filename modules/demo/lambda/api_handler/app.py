import json
import os
import time
import uuid

import boto3

recipes_table = boto3.resource("dynamodb").Table(os.environ["RECIPES_TABLE"])


def handler(event, _context):
    method = event.get("requestContext", {}).get("http", {}).get("method", "GET")

    if method == "POST":
        body = json.loads(event.get("body") or "{}")
        recipe_id = str(uuid.uuid4())
        item = {
            "pk": f"RECIPE#{recipe_id}",
            "sk": f"CREATED#{int(time.time())}",
            "name": body.get("name", "unknown"),
            "author": body.get("author", "anonymous"),
            "created_at": int(time.time()),
            "ingredients": body.get("ingredients", []),
            "steps": body.get("steps", []),
            "status": "draft",
        }
        recipes_table.put_item(Item=item)

        return _response(201, {"id": recipe_id, "status": "stored"})

    if method == "GET":
        data = recipes_table.scan(Limit=25).get("Items", [])
        return _response(200, {"items": data})

    return _response(405, {"message": f"Unsupported method {method}."})


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "content-type": "application/json",
            "x-demo-stack": os.environ.get("PROJECT_NAME", "demo"),
        },
        "body": json.dumps(body),
    }

