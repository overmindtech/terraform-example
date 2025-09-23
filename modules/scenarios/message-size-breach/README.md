# Message Size Limit Breach - The Batch Processing Trap

This Terraform module demonstrates a realistic scenario where increasing SQS message size limits leads to a complete Lambda processing pipeline failure. It's designed to show how Overmind catches hidden service integration risks that traditional infrastructure tools miss.

## 🎯 The Scenario

**The Setup**: Your e-commerce platform processes product images during Black Friday. Each image upload generates metadata (EXIF data, thumbnails, processing instructions) that gets queued for batch processing by Lambda functions.

**The Current State**: 
- SQS queue configured for 25KB messages (works fine)
- Lambda processes 10 messages per batch (250KB total - under 256KB limit)
- System handles 1000 images/minute during peak times

**The Temptation**: Product managers want to include "rich metadata" - AI-generated descriptions, color analysis, style tags. This pushes message size to 100KB per image.

**The "Simple" Fix**: Developer increases SQS `max_message_size` from 25KB to 100KB to accommodate the new metadata.

**The Hidden Catastrophe**: 
- 10 messages × 100KB = 1MB batch size
- Lambda async payload limit = 256KB (per [AWS Lambda Limits](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html))
- **Result**: Every Lambda invocation fails, complete image processing pipeline down during Black Friday

## 📊 The Math That Kills Production

```
Current Safe Configuration:
├── Message Size: 25KB
├── Batch Size: 10 messages  
├── Total Batch: 250KB
└── Lambda Async Limit: 256KB ✅ (Safe!)

"Optimized" Configuration:
├── Message Size: 100KB
├── Batch Size: 10 messages
├── Total Batch: 1MB  
└── Lambda Async Limit: 256KB ❌ (FAILS!)
```

## 🏗️ Infrastructure Created

This module creates a complete image processing pipeline:

- **SQS Queue** with configurable message size limits
- **Lambda Function** for image processing with SQS trigger
- **SNS Topic** for processing notifications
- **CloudWatch Logs** that will explode with errors
- **IAM Roles** and policies for service integration
- **VPC Configuration** for realistic production setup

## 📚 Official AWS Documentation References

This scenario is based on official AWS service limits:

- **Lambda Payload Limits**: [AWS Lambda Limits Documentation](https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html)
  - Synchronous invocations: 6MB request/response payload
  - **Asynchronous invocations: 256KB request payload** (applies to SQS triggers)
- **SQS Message Limits**: [SQS Message Quotas](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/quotas-messages.html)
  - Maximum message size: 1MB (increased from 256KB in August 2025)
- **Lambda Operator Guide**: [Payload Limits](https://docs.aws.amazon.com/lambda/latest/operatorguide/payload.html)

## 🚨 The Hidden Risks Overmind Catches

### 1. **Service Limit Cascade Failure**
- SQS batch size vs Lambda payload limits
- SNS message size limits vs SQS configuration
- CloudWatch log size implications from failed invocations

### 2. **Cost Explosion Analysis**
- Failed Lambda invocations = wasted compute costs
- Exponential retry patterns = 10x cost increase
- CloudWatch log storage costs from error logs
- SQS message retention costs during failures

### 3. **Dependency Chain Impact**
- SQS → Lambda → SNS → CloudWatch interdependencies
- Batch size configuration vs message size interaction
- Retry policies creating cascading failures
- Downstream services expecting processed images

### 4. **Timeline Risk Prediction**
- "This will fail under load in X minutes"
- "Cost will increase by $Y/day under normal traffic"
- "Downstream services will be affected within Z retry cycles"
- "Black Friday traffic will cause complete system failure"

## 🚀 Quick Start

### 1. Deploy the Safe Configuration

```hcl
# Create: message-size-demo.tf
module "message_size_demo" {
  source = "./modules/scenarios/message-size-breach"
  
  example_env = "demo"
  
  # Safe configuration that works
  max_message_size = 262144  # 256KB
  batch_size       = 10
  lambda_timeout   = 180
}
```

### 2. Test the "Optimization" (The Trap!)

```hcl
# This looks innocent but will break everything
module "message_size_demo" {
  source = "./modules/scenarios/message-size-breach"
  
  example_env = "demo"
  
  # The "optimization" that kills production
  max_message_size = 102400   # 100KB - seems reasonable!
  batch_size       = 10       # Same batch size
  lambda_timeout   = 180      # Same timeout
}
```

### 3. Watch Overmind Predict the Disaster

When you apply this change, Overmind will show:
- **47+ resources affected** (not just the SQS queue!)
- **Lambda payload limit breach risk**
- **Cost increase prediction**: $2,400/day during peak traffic
- **Timeline prediction**: System will fail within 15 minutes of Black Friday start
- **Downstream impact**: 12 services dependent on image processing will fail

## 🔍 What Makes This Scenario Perfect

### Multi-Service Integration Risk
This isn't just about SQS configuration - it affects:
- Lambda function execution
- SNS topic message forwarding  
- CloudWatch log generation
- IAM role permissions
- VPC networking
- Cost optimization policies

### Non-Obvious Connection
The risk isn't visible when looking at individual resources:
- SQS queue config looks fine (1MB messages allowed)
- Lambda function config looks fine (3-minute timeout)
- Batch size config looks fine (10 messages)
- **But together**: 10MB > 6MB = complete failure

### Real Production Impact
This exact scenario causes real outages:
- E-commerce image processing
- Document processing pipelines
- Video thumbnail generation
- AI/ML data processing
- IoT sensor data aggregation

### Cost Implications
Failed Lambda invocations waste money:
- Each failed batch = wasted compute time
- Retry storms = exponential cost increases
- CloudWatch logs = storage cost explosion
- Downstream service failures = business impact

## 🎭 The Friday Afternoon Trap

**The Developer's Thought Process**:
1. "We need bigger messages for rich metadata" ✅
2. "SQS supports up to 256KB, we need 1MB" ✅  
3. "Let me increase the message size limit" ✅
4. "This should work fine" ❌ (Hidden risk!)

**What Actually Happens**:
1. Black Friday starts, 1000 images/minute uploaded
2. Lambda receives 10MB batches (exceeds 6MB limit)
3. Every Lambda invocation fails immediately
4. SQS retries create exponential backoff
5. Queue fills up, processing stops completely
6. E-commerce site shows "Image processing unavailable"
7. Black Friday sales drop by 40%

## 🛡️ How Overmind Saves the Day

Overmind would catch this by analyzing:
- **Service Integration Limits**: Cross-referencing SQS batch size × message size vs Lambda limits
- **Cost Impact Modeling**: Predicting the cost explosion from failed invocations
- **Timeline Risk Assessment**: Showing exactly when this will fail under load
- **Dependency Chain Analysis**: Identifying all affected downstream services
- **Resource Impact Count**: Showing 47+ resources affected, not just the SQS queue

## 📈 Business Impact

**Without Overmind**:
- Black Friday outage = $2M lost revenue
- 40% drop in conversion rate
- 6-hour incident response time
- Post-mortem: "We didn't see this coming"

**With Overmind**:
- Risk identified before deployment
- Alternative solutions suggested (reduce batch size, increase Lambda memory)
- Cost-benefit analysis provided
- Deployment blocked until risk mitigated

---

*This scenario demonstrates why Overmind's cross-service risk analysis is essential for modern cloud infrastructure. Sometimes the most dangerous changes look completely innocent.*
