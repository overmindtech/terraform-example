#!/bin/bash
# =============================================================================
# Cleanup Orphaned US-East-1 Resources
# These are leftovers from old Terraform state that can't be deleted normally
# =============================================================================

set -e

REGION="us-east-1"

# Orphaned resource IDs from the failed terraform apply
IGW_ID="igw-0d6fe7cea4cb373de"
VPC_ID="vpc-08a9964c7326fb265"
SUBNET_ID="subnet-04543e1efc5ded887"
SG_IDS=(
    "sg-04fcec18021624e50"  # high_fanout
    "sg-0624f2f710feb01e5"  # shared[4]
    "sg-0afd96d2607922560"  # shared[6]
    "sg-0cfd455529c333962"  # shared[8]
)

echo "=== Orphaned US-East-1 Resource Cleanup ==="
echo "Region: $REGION"
echo "VPC: $VPC_ID"
echo ""

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
    echo "Error: AWS credentials not configured"
    echo "Run: aws sso login --profile terraform-example"
    exit 1
fi

echo "AWS Account: $(aws sts get-caller-identity --query Account --output text)"
echo ""

read -p "This will delete orphaned resources. Type 'yes' to confirm: " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "=== Step 1: Find and terminate any EC2 instances using orphaned SGs ==="

for sg in "${SG_IDS[@]}"; do
    echo "Checking instances using $sg..."
    INSTANCES=$(aws ec2 describe-instances \
        --region $REGION \
        --filters "Name=instance.group-id,Values=$sg" "Name=instance-state-name,Values=running,stopped,pending" \
        --query 'Reservations[].Instances[].InstanceId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$INSTANCES" ] && [ "$INSTANCES" != "None" ]; then
        echo "  Found instances: $INSTANCES"
        echo "  Terminating..."
        aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCES 2>/dev/null || true
    else
        echo "  No instances found"
    fi
done

# Wait for instances to terminate
echo ""
echo "Waiting 30s for instances to terminate..."
sleep 30

echo ""
echo "=== Step 2: Find and delete ENIs using orphaned SGs ==="

for sg in "${SG_IDS[@]}"; do
    echo "Checking ENIs using $sg..."
    ENIS=$(aws ec2 describe-network-interfaces \
        --region $REGION \
        --filters "Name=group-id,Values=$sg" \
        --query 'NetworkInterfaces[].NetworkInterfaceId' \
        --output text 2>/dev/null || echo "")
    
    if [ -n "$ENIS" ] && [ "$ENIS" != "None" ]; then
        for eni in $ENIS; do
            echo "  Detaching and deleting ENI: $eni"
            # Get attachment ID
            ATTACH_ID=$(aws ec2 describe-network-interfaces \
                --region $REGION \
                --network-interface-ids $eni \
                --query 'NetworkInterfaces[0].Attachment.AttachmentId' \
                --output text 2>/dev/null || echo "None")
            
            if [ "$ATTACH_ID" != "None" ] && [ -n "$ATTACH_ID" ]; then
                aws ec2 detach-network-interface --region $REGION --attachment-id $ATTACH_ID --force 2>/dev/null || true
                sleep 5
            fi
            
            aws ec2 delete-network-interface --region $REGION --network-interface-id $eni 2>/dev/null || true
        done
    else
        echo "  No ENIs found"
    fi
done

echo ""
echo "=== Step 3: Release any EIPs in the VPC ==="

EIPS=$(aws ec2 describe-addresses \
    --region $REGION \
    --filters "Name=domain,Values=vpc" \
    --query "Addresses[?contains(Tags[?Key=='Name'].Value | [0] || '', 'scale') || NetworkInterfaceId != null].{AllocationId:AllocationId,AssociationId:AssociationId}" \
    --output json 2>/dev/null || echo "[]")

echo "Found EIPs: $EIPS"

# Disassociate and release EIPs associated with this VPC
# First, find EIPs that might be blocking the IGW
BLOCKING_EIPS=$(aws ec2 describe-addresses \
    --region $REGION \
    --query "Addresses[?Domain=='vpc'].AllocationId" \
    --output text 2>/dev/null || echo "")

# Try to find EIPs specifically in the orphaned VPC's subnets
echo "Checking for EIPs that might be blocking IGW detachment..."
for eip_alloc in $BLOCKING_EIPS; do
    EIP_INFO=$(aws ec2 describe-addresses \
        --region $REGION \
        --allocation-ids $eip_alloc \
        --query 'Addresses[0]' \
        --output json 2>/dev/null || echo "{}")
    
    # Check if this EIP is associated with something in our VPC
    ASSOC_ID=$(echo "$EIP_INFO" | jq -r '.AssociationId // empty')
    NETWORK_ID=$(echo "$EIP_INFO" | jq -r '.NetworkInterfaceId // empty')
    
    if [ -n "$NETWORK_ID" ]; then
        # Check if the ENI is in our orphaned VPC
        ENI_VPC=$(aws ec2 describe-network-interfaces \
            --region $REGION \
            --network-interface-ids $NETWORK_ID \
            --query 'NetworkInterfaces[0].VpcId' \
            --output text 2>/dev/null || echo "")
        
        if [ "$ENI_VPC" = "$VPC_ID" ]; then
            echo "  Found EIP $eip_alloc in orphaned VPC, releasing..."
            if [ -n "$ASSOC_ID" ]; then
                aws ec2 disassociate-address --region $REGION --association-id $ASSOC_ID 2>/dev/null || true
            fi
            aws ec2 release-address --region $REGION --allocation-id $eip_alloc 2>/dev/null || true
        fi
    fi
done

echo ""
echo "=== Step 4: Delete NAT Gateways in orphaned VPC ==="

NATS=$(aws ec2 describe-nat-gateways \
    --region $REGION \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending" \
    --query 'NatGateways[].NatGatewayId' \
    --output text 2>/dev/null || echo "")

if [ -n "$NATS" ] && [ "$NATS" != "None" ]; then
    for nat in $NATS; do
        echo "  Deleting NAT Gateway: $nat"
        aws ec2 delete-nat-gateway --region $REGION --nat-gateway-id $nat 2>/dev/null || true
    done
    echo "  Waiting 60s for NAT gateways to delete..."
    sleep 60
else
    echo "  No NAT Gateways found"
fi

echo ""
echo "=== Step 5: Detach and delete Internet Gateway ==="

echo "Detaching IGW $IGW_ID from VPC $VPC_ID..."
aws ec2 detach-internet-gateway \
    --region $REGION \
    --internet-gateway-id $IGW_ID \
    --vpc-id $VPC_ID 2>/dev/null || echo "  (detach failed or already detached)"

echo "Deleting IGW $IGW_ID..."
aws ec2 delete-internet-gateway \
    --region $REGION \
    --internet-gateway-id $IGW_ID 2>/dev/null || echo "  (delete failed)"

echo ""
echo "=== Step 6: Delete Security Groups ==="

# First, remove all rules that reference other SGs (to break circular deps)
for sg in "${SG_IDS[@]}"; do
    echo "Removing rules from $sg..."
    
    # Get and remove ingress rules
    INGRESS=$(aws ec2 describe-security-groups \
        --region $REGION \
        --group-ids $sg \
        --query 'SecurityGroups[0].IpPermissions' \
        --output json 2>/dev/null || echo "[]")
    
    if [ "$INGRESS" != "[]" ] && [ "$INGRESS" != "null" ]; then
        aws ec2 revoke-security-group-ingress \
            --region $REGION \
            --group-id $sg \
            --ip-permissions "$INGRESS" 2>/dev/null || true
    fi
    
    # Get and remove egress rules (except default all-outbound)
    EGRESS=$(aws ec2 describe-security-groups \
        --region $REGION \
        --group-ids $sg \
        --query 'SecurityGroups[0].IpPermissionsEgress' \
        --output json 2>/dev/null || echo "[]")
    
    if [ "$EGRESS" != "[]" ] && [ "$EGRESS" != "null" ]; then
        aws ec2 revoke-security-group-egress \
            --region $REGION \
            --group-id $sg \
            --ip-permissions "$EGRESS" 2>/dev/null || true
    fi
done

# Now delete the security groups
for sg in "${SG_IDS[@]}"; do
    echo "Deleting security group $sg..."
    aws ec2 delete-security-group \
        --region $REGION \
        --group-id $sg 2>/dev/null || echo "  (failed - may have remaining dependencies)"
done

echo ""
echo "=== Step 7: Delete Subnet ==="

echo "Deleting subnet $SUBNET_ID..."
aws ec2 delete-subnet \
    --region $REGION \
    --subnet-id $SUBNET_ID 2>/dev/null || echo "  (failed - may have remaining dependencies)"

echo ""
echo "=== Step 8: Attempt to delete orphaned VPC ==="

echo "Deleting VPC $VPC_ID..."
aws ec2 delete-vpc \
    --region $REGION \
    --vpc-id $VPC_ID 2>/dev/null || echo "  (failed - may have remaining dependencies)"

echo ""
echo "=== Cleanup Complete ==="
echo ""
echo "If any resources failed to delete, check for remaining dependencies:"
echo "  aws ec2 describe-network-interfaces --region $REGION --filters Name=vpc-id,Values=$VPC_ID"
echo "  aws ec2 describe-instances --region $REGION --filters Name=vpc-id,Values=$VPC_ID"
echo ""
echo "After cleanup, remove orphaned resources from Terraform state:"
echo "  terraform state rm 'module.aws_us_east_1.aws_internet_gateway.main'"
echo "  terraform state rm 'module.aws_us_east_1.aws_security_group.high_fanout'"
echo "  terraform state rm 'module.aws_us_east_1.aws_security_group.shared[4]'"
echo "  terraform state rm 'module.aws_us_east_1.aws_security_group.shared[6]'"
echo "  terraform state rm 'module.aws_us_east_1.aws_security_group.shared[8]'"
echo "  terraform state rm 'module.aws_us_east_1.aws_subnet.public[0]'"
