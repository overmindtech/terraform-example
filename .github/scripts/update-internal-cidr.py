#!/usr/bin/env python3
"""
Update the internal_cidr value in main.tf for the needle scenario.

This script updates the api_internal_cidr local variable.

Usage:
    python3 update-internal-cidr.py <main.tf path> <new_cidr> [comment]

Example:
    python3 update-internal-cidr.py main.tf "10.50.0.0/16" "SECURITY HARDENING: Narrowed per audit findings"
"""

import re
import sys


def update_internal_cidr(main_tf_path, new_cidr, comment=None):
    """
    Update the internal_cidr value in main.tf.
    
    Args:
        main_tf_path: Path to main.tf file
        new_cidr: New CIDR value (e.g., "10.50.0.0/16")
        comment: Optional comment to add after the value
    """
    # Read the file
    try:
        with open(main_tf_path, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: File '{main_tf_path}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error reading file '{main_tf_path}': {e}", file=sys.stderr)
        sys.exit(1)

    # Find the api_internal_cidr line
    # Pattern matches: api_internal_cidr = "10.0.0.0/8"
    pattern = r'(api_internal_cidr = )"([^"]+)"'
    match = re.search(pattern, content)

    if not match:
        print("Error: Could not find api_internal_cidr in main.tf", file=sys.stderr)
        sys.exit(1)

    # Build replacement string
    replacement = f'{match.group(1)}"{new_cidr}"'
    if comment:
        replacement += f'  # {comment}'
    
    # Replace the line
    content = content[:match.start()] + replacement + content[match.end():]
    
    # Write back
    try:
        with open(main_tf_path, 'w') as f:
            f.write(content)
        print(f"Successfully updated internal_cidr to {new_cidr} in {main_tf_path}")
    except Exception as e:
        print(f"Error writing file '{main_tf_path}': {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) < 3:
        print("Usage: update-internal-cidr.py <main.tf path> <new_cidr> [comment]", file=sys.stderr)
        sys.exit(1)
    
    main_tf_path = sys.argv[1]
    new_cidr = sys.argv[2]
    comment = sys.argv[3] if len(sys.argv) > 3 else None
    
    update_internal_cidr(main_tf_path, new_cidr, comment)


if __name__ == '__main__':
    main()
