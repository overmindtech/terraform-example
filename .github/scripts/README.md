# GitHub Actions Scripts

This directory contains Python scripts used by GitHub Actions workflows to modify Terraform configuration files.

## Scripts

### `add-customers-to-main.py`

Adds new customer entries to the `signals_demo_customer_cidrs` map in `main.tf`. This script is used by the "Create Demo PR" workflow to add new customers to the API whitelist.

**Usage:**
```bash
python3 add-customers-to-main.py <main.tf path> <customers HCL>
```

**Example:**
```bash
python3 add-customers-to-main.py main.tf "$(printf '    wonka = {\n      cidr = \"203.0.113.200/32\"\n      name = \"Wonka Industries\"\n    }')"
```

**What it does:**
- Finds the `signals_demo_customer_cidrs` map in `main.tf` (in the `locals` block)
- Locates the `cyberdyne` entry (the last default customer)
- Inserts new customer entries after `cyberdyne`, before the closing brace
- Adds a comment "# New customers added by sales team" before the new entries
- Preserves proper indentation (4 spaces for customer entries)

**Input format:**
The customers HCL should be formatted with 4 spaces of indentation per line, matching the existing format:
```
    customer_key = {
      cidr = "x.x.x.x/y"
      name = "Customer Name"
    }
```

### `update-internal-cidr.py`

Updates the `signals_demo_internal_cidr` value in `main.tf`. This script is used by the "Create Demo PR" workflow for the "needle" scenario to demonstrate security hardening changes.

**Usage:**
```bash
python3 update-internal-cidr.py <main.tf path> <new_cidr> [comment]
```

**Example:**
```bash
python3 update-internal-cidr.py main.tf "10.50.0.0/16" "SECURITY HARDENING: Narrowed per audit findings"
```

**What it does:**
- Finds the `signals_demo_internal_cidr` local variable in `main.tf`
- Updates the CIDR value
- Optionally adds a comment after the value

## Testing

You can test these scripts locally:

```bash
# Make sure you're in the repository root
cd /path/to/terraform-example

# Test adding customers (with actual newlines)
python3 .github/scripts/add-customers-to-main.py main.tf "$(printf '    test = {\n      cidr = \"1.2.3.4/32\"\n      name = \"Test Customer\"\n    }')"

# Verify the change
git diff main.tf

# Test updating internal CIDR
python3 .github/scripts/update-internal-cidr.py main.tf "10.50.0.0/16" "Test comment"

# Verify the change
git diff main.tf

# Revert changes when done testing
git checkout main.tf
```

## How It Works

These scripts modify `main.tf` directly, where customer CIDRs are now hardcoded in a `locals` block instead of being read from a `terraform.tfvars` file. This approach:

- Makes changes visible in `terraform plan` immediately
- Avoids the need for external data sources or file parsing
- Ensures proper formatting that matches `terraform fmt` expectations
- Makes the changes easier to review in pull requests

The `signals_demo_customer_cidrs` is defined in a `locals` block in `main.tf` and passed directly to the `signals_demo` module, ensuring that workflow-generated PRs will trigger Terraform plan changes.

## Requirements

- Python 3.6+
- No external dependencies (uses only standard library: `re`, `sys`, `os`)

## Error Handling

Both scripts will exit with a non-zero status code and print error messages to stderr if:
- The target file cannot be found or read
- The expected patterns cannot be found in the file
- The file cannot be written

This ensures that GitHub Actions workflows will fail if the scripts encounter any issues.
