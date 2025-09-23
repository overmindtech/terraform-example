# Memory Optimization Demo - The Friday Afternoon Trap

This Terraform module demonstrates a realistic scenario where a seemingly simple memory optimization leads to a production outage. It's designed to show how Overmind catches hidden risks that traditional infrastructure tools miss.

## 🎯 The Scenario

**The Setup**: It's Friday afternoon, 7 days before Black Friday. Your Java application is running on 15 ECS Fargate containers, each allocated 2048MB of memory. CloudWatch monitoring shows an average memory usage of only 800MB per container.

**The Temptation**: Your CFO wants cost reductions before the holiday season. You calculate that reducing memory from 2GB to 1GB per container would save **$2,000/month** ($24,000/year).

**The Trap**: The application is configured with `-Xmx1536m` (1536MB Java heap) plus 256MB overhead, requiring 1792MB total. Reducing to 1024MB will cause immediate OutOfMemoryError crashes.

**The Hidden Impact**: What appears to be a simple 2-resource change actually affects 47+ resources and risks a complete outage during peak season.

## 📊 Cost Analysis

```
Current State:
- 15 containers × 2GB × $50/GB/month = $4,000/month
- Annual cost: $48,000

"Optimized" State:
- 15 containers × 1GB × $50/GB/month = $2,000/month  
- Annual cost: $24,000
- Savings: $24,000/year (50% reduction!)
```

## 🏗️ Infrastructure Created

This module creates a complete, isolated environment:

- **ECS Cluster** with Container Insights enabled
- **ECS Service** running 15 Tomcat containers with Java heap trap
- **Application Load Balancer** with 5-second deregistration (no rollback time!)
- **CloudWatch Alarms** that will fire when containers crash
- **Security Groups** and networking for realistic production setup
- **SNS Topic** for alert notifications

## 🚀 Quick Start

### 1. Deploy the Safe Configuration

```hcl
# Create: standalone-demo.tf
module "memory_optimization_demo" {
  source = "./modules/scenarios/memory-optimization"
  
  enabled = true
  container_memory = 2048  # SAFE - meets Java requirements
  
  # Optional customizations
  name_prefix = "my-memory-demo"
  number_of_containers = 15
  use_default_vpc = true
}

output "demo_info" {
  value = module.memory_optimization_demo.demo_status
}

output "app_url" {
  value = module.memory_optimization_demo.alb_url
}
```

```bash
terraform init
terraform apply
```

### 2. Verify the Application Works

```bash
# Get the ALB URL
terraform output app_url

# Test the application (should return Tomcat default page)
curl $(terraform output -raw app_url)
```

### 3. Create the Breaking Change

```bash
# Create a feature branch
git checkout -b memory-optimization

# Edit your module call to use the "optimized" memory
# Change container_memory from 2048 to 1024
```

```hcl
module "memory_optimization_demo" {
  source = "./modules/scenarios/memory-optimization"
  
  enabled = true
  container_memory = 1024  # DANGEROUS - will cause OOM!
  
  name_prefix = "my-memory-demo"
  number_of_containers = 15
  use_default_vpc = true
}
```

### 4. See the "Simple" Change

```bash
terraform plan
```

**Terraform shows**: 2 resources to change
- `aws_ecs_task_definition.app[0]` (memory: 2048 → 1024)
- `aws_ecs_service.app[0]` (task definition ARN update)

**Reality**: 47+ resources will be affected when all containers crash!

### 5. Apply and Watch the Crash (Optional)

⚠️ **Warning**: This will actually break the application!

```bash
terraform apply
```

**What happens**:
1. All 15 containers restart with new memory limit
2. Java tries to allocate 1536MB heap in 1024MB container
3. Immediate OutOfMemoryError on startup
4. Containers crash in a loop
5. ALB health checks fail
6. CloudWatch alarms fire
7. Service becomes unavailable

### 6. Check the Damage

```bash
# View failed containers
aws ecs describe-services --cluster $(terraform output -raw cluster_name) --services $(terraform output -raw service_name)

# Check logs for OOM errors
aws logs filter-log-events --log-group-name $(terraform output -raw log_group_name) --filter-pattern "OutOfMemoryError"

# Monitor CloudWatch alarms (they should be firing)
aws cloudwatch describe-alarms --alarm-names $(terraform output -raw cluster_name)-*
```

### 7. Fix and Cleanup

```bash
# Fix: Change container_memory back to 2048 or higher
# In your module call:
container_memory = 2048

terraform apply

# Or completely clean up
terraform destroy
```

## 📋 Module Configuration

### Required Variables

```hcl
variable "enabled" {
  description = "Toggle module on/off"
  type        = bool
  default     = true
}

variable "container_memory" {
  description = "Memory in MB (2048 = safe, 1024 = breaks)"
  type        = number
  default     = 2048
}
```

### VPC Configuration Options

**Option 1: Use Default VPC (Recommended for demo)**
```hcl
use_default_vpc = true
```

**Option 2: Create Standalone VPC**
```hcl
use_default_vpc = false
create_standalone_vpc = true
```

**Option 3: Use Existing VPC**
```hcl
use_default_vpc = false
create_standalone_vpc = false
vpc_id = "vpc-12345"
subnet_ids = ["subnet-12345", "subnet-67890"]
```

## 🔍 Understanding the Trap

### Why Monitoring Misleads

1. **CloudWatch shows 800MB average usage** - This is the `memoryReservation` setting, not actual usage
2. **GC cycles hide peak usage** - During garbage collection, memory spikes to ~1.8GB
3. **Container Insights don't show JVM internals** - They see container limits, not heap requirements

### The Java Memory Model

```
Container Memory Limit: 1024MB (after "optimization")
├── Java Heap (-Xmx): 1536MB ❌ DOESN'T FIT!
├── Metaspace: ~100MB
├── Direct Memory: ~50MB
├── Code Cache: ~50MB
├── OS Overhead: ~100MB
└── Buffer: ~56MB
```

**Total Required**: ~1792MB
**Container Limit**: 1024MB
**Result**: OutOfMemoryError

### Why Rollback Fails

- **ALB deregistration delay**: 5 seconds (industry standard: 300s)
- **All containers restart simultaneously**: No gradual rollout
- **No circuit breaker**: Disabled to show realistic deployment
- **Black Friday timing**: Change 7 days before 10x traffic spike

## 🎯 What Overmind Would Catch

While `terraform plan` shows only 2 changing resources, Overmind would reveal:

### Direct Dependencies (47+ resources)
- ECS Task Definition changes
- ECS Service deployment
- ALB Target Group health checks
- CloudWatch Alarms triggering
- Auto Scaling Group reactions
- Service Discovery updates
- IAM role assumptions
- CloudWatch Log streams

### Hidden Impacts
- Connected microservices lose connectivity
- Database connection pools drain
- Circuit breakers in dependent services trip
- Load balancer health checks cascade
- Monitoring dashboards show degradation
- Cost allocation tags become inaccurate

### Business Risk Analysis
- **Timing Risk**: 7 days before Black Friday
- **Blast Radius**: All 15 production containers
- **Recovery Time**: Limited by 5s deregistration delay
- **Customer Impact**: Complete service unavailability
- **Financial Impact**: Lost revenue during peak season

## 🛡️ Safety Features

This demo includes several safety mechanisms:

1. **Isolated Resources**: All resources use unique names with random suffix
2. **Module Toggle**: Set `enabled = false` to disable everything
3. **No Shared Infrastructure**: Won't affect existing resources
4. **Quick Cleanup**: `terraform destroy` removes everything
5. **Cost Controls**: Small instance sizes and short retention periods

## 📚 Learning Objectives

After running this demo, you'll understand:

1. **How simple changes can have complex impacts**
2. **Why monitoring can be misleading**
3. **The importance of understanding application internals**
4. **How timing and context affect risk**
5. **Why change blast radius analysis is critical**
6. **The value of tools that reveal hidden dependencies**

## 🔧 Troubleshooting

### Common Issues

**"No default VPC found"**
```hcl
# Create a standalone VPC instead
use_default_vpc = false
create_standalone_vpc = true
```

**"Insufficient permissions"**
- Ensure your AWS credentials have ECS, ALB, and CloudWatch permissions

**"Resource already exists"**
- The random suffix should prevent conflicts
- Try changing the `name_prefix` variable

### Validation Commands

```bash
# Check if module is valid
terraform validate

# Check current resource status
terraform show

# Verify infrastructure
aws ecs list-clusters
aws elbv2 describe-load-balancers
```

## 💡 Extending the Demo

### Add More Realistic Scenarios

1. **Database connections**: Add RDS with connection limits
2. **Service mesh**: Include Istio/Envoy sidecar overhead  
3. **Logging overhead**: Add log shipping memory usage
4. **Monitoring agents**: Include DataDog/New Relic agents

### Customize for Your Environment

```hcl
module "memory_optimization_demo" {
  source = "./modules/scenarios/memory-optimization"
  
  # Scale the scenario
  number_of_containers = 50
  
  # Use your network
  use_default_vpc = false
  vpc_id = var.production_vpc_id
  subnet_ids = var.private_subnet_ids
  
  # Adjust timing
  days_until_black_friday = 3
  days_since_last_memory_change = 180
  
  # Custom naming
  name_prefix = "prod-memory-test"
}
```

## 📞 Support

This module is designed for demonstration purposes. For production use cases:

1. Always test memory changes in staging first
2. Use gradual deployment strategies  
3. Implement proper monitoring and alerting
4. Understand your application's memory requirements
5. Use tools like Overmind to analyze change impact

---

**Remember**: The best time to prevent an outage is before it happens. This demo shows why infrastructure dependency analysis is critical for production changes.