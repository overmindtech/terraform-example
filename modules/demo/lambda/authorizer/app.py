import base64
import json
import os
import time

SHARED_SECRET = os.environ.get("SHARED_SECRET", "changeme")


def handler(event, _context):
    token = event.get("headers", {}).get("authorization")
    principal_id = "anonymous"

    if token == SHARED_SECRET or _basic_auth(token):
        effect = "Allow"
    else:
        effect = "Deny"

    policy = _generate_policy(principal_id, effect, event["routeArn"])
    policy["context"] = {"authorized_at": str(int(time.time()))}
    return policy


def _basic_auth(header_value):
    if not header_value or not header_value.lower().startswith("basic "):
        return False
    encoded = header_value.split(" ", 1)[1]
    decoded = base64.b64decode(encoded).decode("utf-8")
    username, _, password = decoded.partition(":")
    return username == "demo" and password == SHARED_SECRET


def _generate_policy(principal_id, effect, resource):
    return {
        "principalId": principal_id,
        "policyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Action": "execute-api:Invoke",
                    "Effect": effect,
                    "Resource": resource,
                }
            ],
        },
    }

