import json
import os
import urllib.request

import boto3

ssm = boto3.client("ssm")


def handler(event, _context):
    parameter = ssm.get_parameter(Name=os.environ["SLACK_WEBHOOK_PARAMETER"], WithDecryption=False)
    webhook = parameter["Parameter"]["Value"]
    detail = event.get("detail", {})
    payload = {
        "text": f":seedling: Asset {detail.get('asset_id')} processed with status {detail.get('status')}",
    }
    req = urllib.request.Request(
        webhook,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req) as resp:
        resp.read()
    return {"statusCode": 200}

