customer_cidrs = {
  acme_corp = { cidr = "203.0.113.10/32", name = "Acme Corp" }
  globex    = { cidr = "198.51.100.0/29", name = "Globex Industries" }
  initech   = { cidr = "192.0.2.50/32", name = "Initech" }
  umbrella  = { cidr = "198.18.100.0/24", name = "Umbrella Corp" }
  cyberdyne = { cidr = "100.64.0.0/29", name = "Cyberdyne Systems" }
  # New customers added by sales team
  wonka = { cidr = "203.0.113.200/32", name = "Wonka Industries" }
  oceanic = { cidr = "198.51.100.64/29", name = "Oceanic Airlines" }
  dharma = { cidr = "192.0.2.128/25", name = "Dharma Initiative" }
}



internal_cidr = "10.0.0.0/8"
demo_domain   = "signals-demo.overmind.tech"
alert_email   = "demo-alerts@overmind.tech"
