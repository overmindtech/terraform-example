# Shared Security Group Demo

Demonstrates Overmind's ability to discover **manual dependencies** that Terraform doesn't track.

## The Scenario

**Narrative**: Security team found the "internet-access" security group too permissive. We're restricting it to only the ports our API actually needs.

**Hidden Problem**: Other teams have manually attached this generic-named SG to their instances. Restricting egress will break their applications.

## Setup (One-Time)

### 1. Deploy Infrastructure

Merge this module to main. GitHub Actions will provision:
- Security group named `internet-access` (permissive egress)
- One t3.nano instance (Terraform-managed)

### 2. Create Manual Instance

After infrastructure is deployed, run the CLI command from the terraform output:

```bash
terraform output -module=shared_security_group manual_instance_command
```

Or manually:

```bash
aws ec2 run-instances \
  --image-id <AMI_ID> \
  --instance-type t3.nano \
  --subnet-id <SUBNET_ID> \
  --security-group-ids <SG_ID> \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=data-processor},{Key=Team,Value=data-engineering},{Key=CreatedBy,Value=console}]' \
  --region eu-west-2
```

This simulates a team member creating an instance via the console (click-ops).

## Demo Flow

### 1. Set the Scene

> "Security audit found our 'internet-access' security group is way too permissive. 
> We've reviewed the API's actual requirements and it only needs port 8080 outbound."

### 2. Make the Change

Edit `modules/shared-security-group/security-group.tf`:

```diff
  egress {
-   from_port   = 0
-   to_port     = 0
-   protocol    = "-1"
+   from_port   = 8080
+   to_port     = 8080
+   protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
-   description = "Allow all outbound traffic"
+   description = "API outbound traffic only"
  }
```

### 3. Create PR

Overmind analysis will show:

**Blast Radius**:
- ✅ `api-server` (Terraform knows about this)
- ⚠️ `data-processor` (Terraform does NOT know about this!)

**Risk**: Restricting egress will break the data-processor's database connections and external API calls.

### 4. The "How Did We Miss That?" Moment

> "Wait, there's another instance using this security group?"
> 
> *Search the codebase* - nothing found.
> 
> "It was created manually through the console. This is exactly why we need 
> real-time dependency discovery, not just Terraform state."

## Key Learning

Overmind discovers dependencies from the **actual cloud state**, not just Terraform. This catches:
- Click-ops resources
- Manually attached security groups
- Console-created instances
- Any dependency Terraform doesn't track

## Cleanup

After demo:
1. Close the PR
2. Delete the branch
3. (Optional) Terminate the manual data-processor instance

## Cost

- Terraform-managed instance: ~$4/month (t3.nano)
- Manual instance: ~$4/month (t3.nano)
- **Total**: ~$6/month

