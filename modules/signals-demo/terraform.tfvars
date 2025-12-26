customer_cidrs = {
  acme_corp = {
    cidr = "203.0.113.10/32"
    name = "Acme Corp"
  }
  globex = {
    cidr = "198.51.100.0/29"
    name = "Globex Industries"
  }
  initech = {
    cidr = "192.0.2.50/32"
    name = "Initech"
  }
  umbrella = {
    cidr = "198.18.100.0/24"
    name = "Umbrella Corp"
  }
  cyberdyne = {
    cidr = "100.64.0.0/29"
    name = "Cyberdyne Systems"
  }
}

# IMPORTANT: This should always be 10.0.0.0/8 in the baseline
# The "needle" scenario changes this to 10.0.0.0/16 (baseline VPC CIDR)
internal_cidr = "10.0.0.0/8"

domain      = "signals-demo-test.demo"
alert_email = "alerts@example.com"
