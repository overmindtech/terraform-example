GitHub Copilot Prompt for Self-Contained Memory Optimization Demo
markdown# Create a self-contained Terraform module for memory optimization demo

## Context
I need to add a demo scenario to an existing terraform-example repository that shows how Overmind catches hidden risks. The demo must be completely self-contained and not affect any existing infrastructure. The scenario shows a Friday afternoon memory optimization to save costs that would actually cause a production outage.

## Requirements

### Module Location
Create all files in: `modules/scenarios/memory-optimization/`
This should be a completely isolated module that can be enabled/disabled without affecting anything else.

### Directory Structure
modules/scenarios/memory-optimization/
├── README.md           # Demo instructions
├── main.tf            # Module entry point with VPC logic
├── variables.tf       # All input variables
├── outputs.tf         # Module outputs
├── ecs.tf            # ECS cluster, service, task definition
├── networking.tf     # ALB, security groups, target groups
└── monitoring.tf     # CloudWatch alarms

### Core Scenario
Create infrastructure demonstrating:
1. Java application in ECS Fargate with 15 containers
2. Currently allocated 2048MB memory per container ($4000/month)
3. Java heap configured for 1536MB (-Xmx1536m)
4. CloudWatch showing "only 800MB average usage"
5. Changing to 1024MB would "save $2000/month"
6. But app needs 1536MB heap + 256MB overhead = crash

### Key Variables in variables.tf
```hcl
variable "enabled" - Toggle module on/off (default: true)
variable "name_prefix" - Unique prefix for resources (default: "memory-opt-demo")
variable "container_memory" - Memory in MB (default: 2048, will change to 1024)
variable "number_of_containers" - ECS service count (default: 15)
variable "use_default_vpc" - Use default VPC (default: true)
variable "days_until_black_friday" - Context for urgency (default: 7)
variable "days_since_last_memory_change" - Shows staleness (default: 423)
Module Requirements
main.tf

Use locals for all internal calculations
Support three VPC modes:

use_default_vpc = true (use account's default VPC)
create_standalone_vpc = true (create isolated VPC)
Use provided vpc_id and subnet_ids


Generate random suffix for resource uniqueness
Calculate cost savings: current vs proposed memory
Add common tags to all resources showing the scenario context

ecs.tf

ECS cluster with container insights enabled
Task definition with:

Fargate launch type
Public Tomcat image (tomcat:9-jre11)
JAVA_OPTS="-Xmx1536m -Xms1536m" (THE TRAP!)
memoryReservation: 800 (misleading metric)
Health check with 120s startup time for JVM
Container memory from var.container_memory


ECS service with:

desired_count = var.number_of_containers (15)
Rolling update deployment
Tags showing this will affect all containers


IAM roles for ECS execution and task

networking.tf

ALB with public access
Target group with:

deregistration_delay = 5 seconds (no rollback!)
Health check on port 8080


Security groups for ALB and ECS
Tags mentioning Black Friday capacity needs

monitoring.tf

CloudWatch alarm for memory > 80%
CloudWatch alarm for task count < expected
Tags explaining alarms will fire when OOM occurs

outputs.tf
hcloutput "alb_url" - URL to access the application
output "demo_status" - Object showing:
  - current vs required memory
  - will_it_work boolean
  - cost calculations
  - risk assessment
output "instructions" - How to break and fix the demo
Integration Points
The module should be usable in three ways:

Standalone file (create as example):

hcl# standalone-demo.tf
module "memory_optimization_demo" {
  source = "./modules/scenarios/memory-optimization"
  enabled = true
  container_memory = 2048  # Change to 1024 to break
}

Part of existing scenarios (if they have a pattern):

hclmodule "scenarios" {
  memory_optimization = {
    enabled = true
  }
}

Targeted deployment:

bashterraform apply -target='module.memory_optimization_demo'
Demo Flow in README.md
Include instructions for:

Deploy initial setup with 2048MB
Create branch and change to 1024MB
Run terraform plan (shows 2 changes)
Overmind reveals 47 resources affected
Explanation of why it breaks (JVM heap > container memory)
How to clean up

Resource Naming

All resources must use: ${var.name_prefix}-resourcetype-${random_suffix}
This ensures no conflicts with existing infrastructure
Example: "memory-opt-demo-cluster-abc123"

Cost Calculations
Include realistic cost math:

Cost per GB: $50/month
Current: 2GB × 15 containers × $50 = $4000/month
"Optimized": 1GB × 15 containers × $50 = $2000/month
Savings: $2000/month

Critical Comments
Add comments explaining:

Why 800MB average is misleading (P99 is 1.8GB during GC)
Why JVM needs 1536MB heap + 256MB metaspace + 256MB OS
Why Black Friday timing matters (10x traffic)
Why 5-second deregistration prevents rollback
Why all 15 containers restarting is risky

Make it Production-Like

Use real container images (tomcat:9-jre11)
Real AWS resources (not local testing)
Realistic configurations (proper health checks, security groups)
Actual cost calculations
Production-like tags and metadata

Safety Features

Module can be disabled with enabled=false
All resources have unique names with random suffix
No hardcoded values that could conflict
Clean destroy with terraform destroy -target

Expected Behavior
When container_memory changes from 2048 to 1024:

Terraform plan: 2 resources to change
Reality: Application crashes immediately (JVM OOM)
Overmind catches: 47 resources affected, multiple critical risks

Output Format
Generate complete, working Terraform files that:

Are production-quality with proper error handling
Include extensive comments explaining the demo
Can be deployed immediately without modifications
Won't interfere with any existing infrastructure
Tell the story of why this change seems safe but isn't


---

## How to Use This with Copilot

1. **Create the module directory**:
```bash
mkdir -p modules/scenarios/memory-optimization
cd modules/scenarios/memory-optimization

Create a context file:

bash# Save the prompt above as:
echo "# Memory Optimization Demo Module Requirements" > .copilot-context.md
# Paste the entire prompt into this file

Generate each file with Copilot:

For each file, start with a comment referencing the context:
hcl# main.tf
# Following .copilot-context.md requirements for memory optimization demo
# This creates a self-contained module showing how memory reduction breaks Java apps

# Copilot will now understand the full context and generate appropriate code

Helpful Copilot triggers:

hcl# In variables.tf:
# Create variables for memory optimization demo as specified in .copilot-context.md
# Include container_memory that will change from 2048 to 1024

# In ecs.tf:
# Create ECS resources showing Java heap trap from .copilot-context.md
# Java needs 1536MB heap but container will only have 1024MB after change

# In monitoring.tf:
# Create CloudWatch alarms that will fire when containers OOM
# Reference the memory optimization scenario from .copilot-context.md

Test the generation:

bash# After Copilot generates files, validate:
terraform init
terraform validate
terraform plan