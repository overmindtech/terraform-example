import json
import os
import time
import uuid

import boto3

dynamodb = boto3.resource("dynamodb")
assets_table = dynamodb.Table(os.environ["ASSETS_TABLE"])
recipes_table = dynamodb.Table(os.environ["RECIPES_TABLE"])
states = boto3.client("stepfunctions")


def handler(event, _context):
    records = event.get("Records", [])
    results = []

    for record in records:
        message = json.loads(record.get("Sns", {}).get("Message", "{}"))
        asset_id = message.get("object_key") or str(uuid.uuid4())
        asset_item = {
            "asset_id": asset_id,
            "bucket": message.get("bucket"),
            "status": "RECEIVED",
            "ingested_at": int(time.time()),
        }
        assets_table.put_item(Item=asset_item)
        recipe_pk = message.get("recipe_pk", "RECIPE#unknown")
        recipes_table.update_item(
            Key={"pk": recipe_pk, "sk": message.get("recipe_sk", "CREATED#0")},
            UpdateExpression="SET last_asset_id = :asset",
            ExpressionAttributeValues={":asset": asset_id},
            ReturnValues="UPDATED_NEW",
        )
        execution_input = {
            "asset_id": asset_id,
            "bucket": message.get("bucket"),
            "object_key": message.get("object_key"),
            "recipe_pk": recipe_pk,
        }
        response = states.start_execution(
            stateMachineArn=os.environ["STATE_MACHINE_ARN"],
            name=f"{asset_id}-{int(time.time())}",
            input=json.dumps(execution_input),
        )
        results.append({"asset_id": asset_id, "execution_arn": response["executionArn"]})

    return {"invocations": len(results), "executions": results}

