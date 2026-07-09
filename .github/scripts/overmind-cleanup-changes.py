#!/usr/bin/env python3
"""
Cleanup script for stale Overmind "changes" created by repeated demo runs.

The Overmind CLI (https://github.com/overmindtech/cli) does not expose a
`delete-change` command - `overmind changes --help` only lists list-changes,
get-change, start-change, end-change, submit-plan, submit-signal,
start-analysis, and get-signals. The underlying API does support deleting a
change by UUID though (changes.ChangesService/DeleteChange), it's just never
wired up to a CLI subcommand.

This script calls that API directly using the Connect protocol's plain
HTTP+JSON transport (the same thing curl could do - see
https://connectrpc.com), so no CLI changes, Go toolchain, or extra Python
dependencies are required (stdlib only).

Usage:
    OVM_API_KEY=ovm_api_... python3 overmind-cleanup-changes.py \
        --title-pattern "narrow internal ingress" \
        --keep 0 \
        [--dry-run]

Modes:
    --keep 0   Delete every matching change. Use this right before creating a
               fresh pair of demo PRs (i.e. in the same "cleanup old branches"
               step) so that only the changes from the run you're about to
               kick off exist afterwards.
    --keep N   Delete all but the N most-recently-created matching changes.
               Use this if you want to trim history without fully wiping it.

Requires an OVM_API_KEY with the "changes:write" scope - the same scope
already used by `overmind changes start-change` / `end-change` /
`submit-plan`, so the key already configured for this repo's CI should work
as-is, assuming it has that scope. This has NOT been tested end-to-end since
no OVM_API_KEY is available in the environment this script was written in -
run with --dry-run first.
"""
import argparse
import base64
import json
import os
import re
import sys
import urllib.error
import urllib.request


def connect_post(base_url, service_method, body, token=None):
    url = f"{base_url}/{service_method}"
    headers = {
        "Content-Type": "application/json",
        "Connect-Protocol-Version": "1",
    }
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Request to {service_method} failed: {e.code} {detail}")


def base64_to_uuid(b64):
    raw = base64.b64decode(b64)
    hex_str = raw.hex()
    return f"{hex_str[0:8]}-{hex_str[8:12]}-{hex_str[12:16]}-{hex_str[16:20]}-{hex_str[20:32]}"


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        "--app",
        default="https://app.overmind.tech",
        help="Overmind frontend URL (used to discover the real API host)",
    )
    parser.add_argument(
        "--title-pattern",
        default=r"narrow internal ingress",
        help="Regex (case-insensitive) matched against each change's title",
    )
    parser.add_argument(
        "--keep",
        type=int,
        default=0,
        help="Number of most-recently-created matching changes to keep (default: 0, i.e. delete all matches)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print what would be deleted without deleting anything",
    )
    args = parser.parse_args()

    api_key = os.environ.get("OVM_API_KEY")
    if not api_key:
        raise SystemExit("OVM_API_KEY environment variable is required")

    # The frontend URL (app.overmind.tech) and the API host are different -
    # discover the real API host the same way the CLI does.
    with urllib.request.urlopen(f"{args.app}/api/public/instance-data") as resp:
        instance_data = json.loads(resp.read().decode("utf-8"))
    api_url = instance_data["api_url"]

    token_resp = connect_post(
        api_url, "apikeys.ApiKeyService/ExchangeKeyForToken", {"apiKey": api_key}
    )
    token = token_resp.get("accessToken")
    if not token:
        raise SystemExit(f"Did not receive an access token: {token_resp}")

    list_resp = connect_post(
        api_url, "changes.ChangesService/ListChanges", {}, token=token
    )
    changes = list_resp.get("changes", [])

    pattern = re.compile(args.title_pattern, re.IGNORECASE)
    matches = [
        c for c in changes if pattern.search(c.get("properties", {}).get("title", ""))
    ]
    matches.sort(key=lambda c: c.get("metadata", {}).get("createdAt", ""), reverse=True)

    print(f"Found {len(matches)} change(s) matching /{args.title_pattern}/i out of {len(changes)} total:")
    for change in matches:
        meta = change.get("metadata", {})
        props = change.get("properties", {})
        change_uuid = base64_to_uuid(meta["UUID"]) if meta.get("UUID") else "?"
        print(f"  - {change_uuid}  {meta.get('createdAt', '?')}  {props.get('title', '?')}")

    to_keep = matches[: args.keep] if args.keep > 0 else []
    to_delete = matches[args.keep :] if args.keep > 0 else matches

    if not to_delete:
        print("\nNothing to delete.")
        return

    print(f"\nKeeping {len(to_keep)}, deleting {len(to_delete)}:")
    for change in to_delete:
        meta = change["metadata"]
        change_uuid = base64_to_uuid(meta["UUID"])
        title = change.get("properties", {}).get("title", "?")
        if args.dry_run:
            print(f"  [dry-run] would delete {change_uuid}  {title}")
            continue
        connect_post(
            api_url, "changes.ChangesService/DeleteChange", {"UUID": meta["UUID"]}, token=token
        )
        print(f"  deleted {change_uuid}  {title}")


if __name__ == "__main__":
    main()
