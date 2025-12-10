# API Server Module - Platform Standardization Demo

> Learn how standardizing on a single instance family can introduce hidden risks when workload characteristics aren't considered.

## 🎬 Demo Flow

### 1. Open Compliance Dashboard
https://terraform-example-demo-app.preview.df.overmind-demo.com/

### 2. View the Auto-Created Ticket
- Dashboard shows 97.9% compliance, 1 non-compliant instance
- Click **"View Ticket"** → Opens ticket INFRA-4721
- Notice: "Standard Change - no CAB approval required"

### 3. Click "Open in Editor"
- In **Related Resources**, click **"Open in Editor"**
- Opens github.dev directly at line 389 of `main.tf`

### 4. Make the Change
Change the instance type:
```diff
- instance_type = "c5.large"
+ instance_type = "t3.large"
```

### 5. Create PR & Watch Overmind
```bash
git checkout -b align-platform-standards
git commit -am "Align API server with t3 platform standards"
git push origin align-platform-standards
```
Overmind analyzes the PR and catches the hidden risk.

## 🎯 The Scenario

| What the Engineer Sees | What Actually Happens |
|------------------------|----------------------|
| c5.large → t3.large | Compute-optimized → Burstable |
| Same specs (2 vCPU, 4GB) | Different CPU models |
| "Standard change" | Performance drops to 30% after ~1 hour |

**The trap**: Both instances look identical on paper, but t3 uses CPU credits. At 70% sustained CPU, credits exhaust and performance collapses.

## 🔥 CPU Load Simulation

The instance runs a **permanent 70% CPU load** via `stress-ng` to simulate a real CPU-intensive workload. This ensures:

- CloudWatch shows realistic CPU utilization (~70%)
- Overmind can detect the risk from actual metrics
- The demo reflects real-world conditions

The load runs as a systemd service that starts on boot and restarts automatically. No extra cost - EC2 is billed by time, not CPU usage.

## 🔍 What Overmind Catches

1. **Blast Radius** - ALB, target groups, alarms, security groups
2. **Educational Risk** - Explains CPU credit behavior
3. **Impact Analysis** - Predicts performance degradation

## 💰 Cost Management

| State | Cost |
|-------|------|
| Running | ~$79/month |
| Stopped | ~$0.60/month (EBS only) |

```bash
# Stop between demos
aws ec2 stop-instances --instance-ids $(terraform output -raw api_server_instance_id)

# Destroy when done  
terraform destroy -target=module.api_server
```

## 📖 Learn More

- [T3 CPU Credits](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/burstable-credits-baseline-concepts.html)
- [C5 vs T3 Instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/compute-optimized-instances.html)

