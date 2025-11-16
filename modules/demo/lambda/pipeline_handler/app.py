import json
import os
import time

import boto3

dynamodb = boto3.resource("dynamodb")
assets_table = dynamodb.Table(os.environ["ASSETS_TABLE"])
events = boto3.client("events")


def handler(event, _context):
    asset_id = (event or {}).get("asset_id", "unknown")
    status = "PROCESSED"
    assets_table.update_item(
        Key={"asset_id": asset_id},
        UpdateExpression="SET #s = :status, processed_at = :processed",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={
            ":status": status,
            ":processed": int(time.time()),
        },
    )

    detail = {
        "asset_id": asset_id,
        "bucket": event.get("bucket"),
        "object_key": event.get("object_key"),
        "status": status,
    }
    events.put_events(
        Entries=[
            {
                "EventBusName": os.environ["EVENT_BUS_NAME"],
                "Source": "demo.asset.pipeline",
                "DetailType": "AssetProcessed",
                "Detail": json.dumps(detail),
            }
        ]
    )

    return {"asset_id": asset_id, "status": status}

