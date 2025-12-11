#!/usr/bin/env python3
"""
Add new customers to the api_customer_cidrs map in main.tf.

This script inserts new customer entries after the cyberdyne entry,
before the closing brace of the customer_cidrs map.

Usage:
    python3 add-customers-to-main.py <main.tf path> <customers HCL>

Example:
    python3 add-customers-to-main.py main.tf "$CUSTOMER_HCL"
"""

import re
import sys
import os


def add_customers_to_main(main_tf_path, new_customers_hcl):
    """
    Add new customers to main.tf after the cyberdyne entry.
    
    Args:
        main_tf_path: Path to main.tf file
        new_customers_hcl: HCL-formatted string with new customer entries
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

    # Find the api_customer_cidrs block - look for cyberdyne closing brace
    pattern = r'(api_customer_cidrs = \{.*?cyberdyne = \{[^}]+\}\n)(\s+\})'
    match = re.search(pattern, content, re.DOTALL)

    if not match:
        print("Error: Could not find customer_cidrs block in main.tf", file=sys.stderr)
        print("Expected to find 'api_customer_cidrs' with 'cyberdyne' entry", file=sys.stderr)
        sys.exit(1)

    # Insert new customers after cyberdyne, before the closing brace
    # The new_customers_hcl already has proper indentation (4 spaces)
    new_customers = '    # New customers added by sales team\n' + new_customers_hcl.rstrip() + '\n'
    
    # Replace the closing brace with new customers + closing brace
    replacement = match.group(1) + new_customers + '\n' + match.group(2)
    content = content[:match.start()] + replacement + content[match.end():]
    
    # Write back
    try:
        with open(main_tf_path, 'w') as f:
            f.write(content)
        print(f"Successfully added customers to {main_tf_path}")
    except Exception as e:
        print(f"Error writing file '{main_tf_path}': {e}", file=sys.stderr)
        sys.exit(1)


def main():
    if len(sys.argv) < 3:
        print("Usage: add-customers-to-main.py <main.tf path> <customers HCL>", file=sys.stderr)
        print("\nAlternatively, set NEW_CUSTOMERS environment variable:", file=sys.stderr)
        print("  NEW_CUSTOMERS='...' python3 add-customers-to-main.py main.tf", file=sys.stderr)
        sys.exit(1)
    
    main_tf_path = sys.argv[1]
    
    # Get customers from command line arg or environment variable
    if len(sys.argv) >= 3:
        new_customers_hcl = sys.argv[2]
    else:
        new_customers_hcl = os.environ.get('NEW_CUSTOMERS', '')
    
    if not new_customers_hcl:
        print("Error: No customers provided", file=sys.stderr)
        sys.exit(1)
    
    add_customers_to_main(main_tf_path, new_customers_hcl)


if __name__ == '__main__':
    main()
