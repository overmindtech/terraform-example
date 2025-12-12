#!/usr/bin/env python3
"""
Routine allowlist maintenance for the Signals demo.

Behavior (stateless):
- Never narrow or shift existing customer CIDRs.
- Broadens the first customer CIDR (in a fixed order) that can still be widened.
- If none can be broadened further, adds a new customer entry: newco_<n>.

This script edits the root main.tf in-place, updating local.api_customer_cidrs.
"""

from __future__ import annotations

import ipaddress
import re
import sys
from pathlib import Path


CUSTOMERS: list[str] = ["acme_corp", "globex", "initech", "umbrella", "cyberdyne"]
CAPS: dict[str, int] = {
    # /32: broaden to /31 then /30, then stop (still plausible)
    "acme_corp": 30,
    "initech": 30,
    # /29: broaden to /28, then stop
    "globex": 28,
    "cyberdyne": 28,
    # /24: treat as already capped
    "umbrella": 24,
}


def get_cidr(customer_key: str, s: str) -> str:
    m = re.search(
        rf'{re.escape(customer_key)}\s*=\s*\{{[^}}]*?\bcidr\s*=\s*"([^"]+)"',
        s,
        flags=re.S,
    )
    if not m:
        raise RuntimeError(f"Could not find cidr for customer '{customer_key}'")
    return m.group(1)


def set_cidr(customer_key: str, new_cidr: str, s: str) -> str:
    return re.sub(
        rf'({re.escape(customer_key)}\s*=\s*\{{[^}}]*?\bcidr\s*=\s*")([^"]+)(")',
        rf"\g<1>{new_cidr}\g<3>",
        s,
        flags=re.S,
        count=1,
    )


def broaden_one_step(cidr: str, cap_prefix: int) -> str:
    net = ipaddress.ip_network(cidr, strict=True)
    if net.prefixlen <= cap_prefix:
        return cidr
    new_prefix = max(net.prefixlen - 1, cap_prefix)
    return str(net.supernet(new_prefix=new_prefix))


def main() -> int:
    tf_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("main.tf")
    text = tf_path.read_text()
    updated = text

    for key in CUSTOMERS:
        current = get_cidr(key, updated)
        new = broaden_one_step(current, CAPS[key])
        if new != current:
            updated = set_cidr(key, new, updated)
            tf_path.write_text(updated)
            print(f"Routine change: broadened {key} ({current} -> {new}).")
            return 0

    # No customer can be broadened: add a new customer (routine onboarding).
    existing = [int(m.group(1)) for m in re.finditer(r"\bnewco_(\d+)\b", updated)]
    n = (max(existing) if existing else 0) + 1

    new_key = f"newco_{n}"
    new_name = f"NewCo {n}"
    new_cidr = f"203.0.113.{100 + n}/32"

    if "api_customer_cidrs = {" not in updated:
        raise RuntimeError("Could not find api_customer_cidrs map")

    insert = (
        "api_customer_cidrs = {\n"
        f"    {new_key} = {{\n"
        f'      cidr = "{new_cidr}"\n'
        f'      name = "{new_name}"\n'
        "    }\n"
    )
    updated = updated.replace("api_customer_cidrs = {", insert, 1)
    tf_path.write_text(updated)
    print(f"Routine change: added customer {new_key} ({new_cidr}).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


