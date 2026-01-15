# AWS Deployment Guide - GadgetsOnline Microservices

## Complete Step-by-Step Guide to Deploy on AWS

This guide will walk you through deploying your dockerized microservices to AWS using:
- **Amazon ECS (Elastic Container Service)** - For running containers
- **Amazon RDS** - For SQL Server database
- **Amazon ECR (Elastic Container Registry)** - For storing Docker images
- **Application Load Balancer** - For routing traffic
- **VPC** - For network isolation

---

## Prerequisites

### 1. AWS Account
- Create an AWS account at https://aws.amazon.com
- Have your AWS credentials ready

### 2. Install AWS CLI
**Windows (PowerShell):**
```powershell
# Download and install AWS CLI
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Verify installation:**
```powershell
aws --version
```

### 3. Configure AWS CLI
```powershell
aws configure
```

You'll be prompted for:
- **AWS Access Key ID**: (from AWS Console → IAM → Users → Security Credentials)
- **AWS Secret Access Key**: (from same location)
- **Default region**: `us-east-1` (or your preferred region)
- **Default output format**: `json`

### 4. Install Docker Desktop
- Already installed ✅ (you're running Docker)

---

## Architecture Overview

```
Internet
    ↓
Application Load Balancer (ALB)
    ↓
┌─────────────────────────────────────────────────┐
│              AWS ECS Cluster                     │
│                                                  │
│  ┌──────────────┐  ┌──────────────┐            │
│  │ Web Frontend │  │ API Gateway  │            │
│  │  (Task)      │  │   (Task)     │            │
│  └──────────────┘  └──────────────┘            │
│                           ↓                      │
│  ┌──────────────┐  ┌──────────────┐  ┌────────┐│
│  │ Catalog API  │  │  Cart API    │  │ Order  ││
│  │   (Task)     │  │   (Task)     │  │  API   ││
│  └──────────────┘  └──────────────┘  └────────┘│
└─────────────────────────────────────────────────┘
                      ↓
            Amazon RDS (SQL Server)
```

---

## Deployment Steps

## PHASE 1: Prepare AWS Infrastructure

### Step 1: Create ECR Repositories

ECR will store your Docker images.

```powershell
# Navigate to microservices folder
cd microservices

# Create repository for each service
aws ecr create-repository --repository-name gadgetsonline/catalog-api --region us-east-1
aws ecr create-repository --repository-name gadgetsonline/cart-api --region us-east-1
aws ecr create-repository --repository-name gadgetsonline/order-api --region us-east-1
aws ecr create-repository --repository-name gadgetsonline/api-gateway --region us-east-1
aws ecr create-repository --repository-name gadgetsonline/web-frontend --region us-east-1
```

**Expected Output:**
```json
{
    "repository": {
        "repositoryArn": "arn:aws:ecr:us-east-1:123456789:repository/gadgetsonline/catalog-api",
        "repositoryUri": "123456789.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline/catalog-api"
    }
}
```

**Save the `repositoryUri` values - you'll need them!**

---

### Step 2: Authenticate Docker with ECR

```powershell
# Get login password and authenticate
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com
```

Replace `YOUR_ACCOUNT_ID` with your AWS account ID (visible in the repositoryUri from Step 1).

**Expected Output:**
```
Login Succeeded
```

---

### Step 3: Tag and Push Docker Images to ECR

```powershell
# Get your AWS account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
$AWS_REGION = "us-east-1"

# Tag images
docker tag microservices-catalog-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/catalog-api:latest
docker tag microservices-cart-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/cart-api:latest
docker tag microservices-order-api:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/order-api:latest
docker tag microservices-api-gateway:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/api-gateway:latest
docker tag microservices-web-frontend:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/web-frontend:latest

# Push images to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/catalog-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/cart-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/order-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/api-gateway:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/gadgetsonline/web-frontend:latest
```

This will take several minutes. Each image is being uploaded to AWS.

---

### Step 4: Create RDS SQL Server Database

#### 4.1: Create DB Subnet Group (via AWS Console)

1. Go to **AWS Console** → **RDS** → **Subnet groups**
2. Click **Create DB subnet group**
3. Fill in:
   - **Name**: `gadgetsonline-db-subnet-group`
   - **Description**: `Subnet group for GadgetsOnline database`
   - **VPC**: Select your default VPC
   - **Availability Zones**: Select at least 2 zones
   - **Subnets**: Select subnets from different AZs
4. Click **Create**

#### 4.2: Create Security Group for RDS

```powershell
# Get your default VPC ID
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text

# Create security group for RDS
aws ec2 create-security-group `
    --group-name gadgetsonline-rds-sg `
    --description "Security group for GadgetsOnline RDS" `
    --vpc-id $VPC_ID

# Get the security group ID (save this!)
$RDS_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-rds-sg" `
    --query "SecurityGroups[0].GroupId" --output text

# Allow SQL Server port (1433) from anywhere in VPC
aws ec2 authorize-security-group-ingress `
    --group-id $RDS_SG_ID `
    --protocol tcp `
    --port 1433 `
    --cidr 10.0.0.0/16
```

#### 4.3: Create RDS SQL Server Instance

**Option A: Using AWS CLI (Recommended)**

```powershell
aws rds create-db-instance `
    --db-instance-identifier gadgetsonline-sqlserver `
    --db-instance-class db.t3.small `
    --engine sqlserver-ex `
    --master-username admin `
    --master-user-password "YourStrong@Passw0rd123" `
    --allocated-storage 20 `
    --vpc-security-group-ids $RDS_SG_ID `
    --db-subnet-group-name gadgetsonline-db-subnet-group `
    --backup-retention-period 7 `
    --no-publicly-accessible `
    --engine-version 15.00.4335.1.v1
```

**Option B: Using AWS Console**

1. Go to **RDS** → **Databases** → **Create database**
2. Choose:
   - **Engine**: Microsoft SQL Server
   - **Edition**: Express Edition (free tier eligible)
   - **Version**: Latest
3. **Templates**: Free tier (or Dev/Test)
4. **Settings**:
   - **DB instance identifier**: `gadgetsonline-sqlserver`
   - **Master username**: `admin`
   - **Master password**: `YourStrong@Passw0rd123`
5. **Instance configuration**: `db.t3.small`
6. **Storage**: 20 GB
7. **Connectivity**:
   - **VPC**: Default VPC
   - **Subnet group**: `gadgetsonline-db-subnet-group`
   - **Public access**: No
   - **VPC security group**: `gadgetsonline-rds-sg`
8. Click **Create database**

**Wait 10-15 minutes for RDS to be created.**

#### 4.4: Get RDS Endpoint

```powershell
# Wait for RDS to be available
aws rds wait db-instance-available --db-instance-identifier gadgetsonline-sqlserver

# Get the endpoint
$RDS_ENDPOINT = aws rds describe-db-instances `
    --db-instance-identifier gadgetsonline-sqlserver `
    --query "DBInstances[0].Endpoint.Address" --output text

Write-Host "RDS Endpoint: $RDS_ENDPOINT"
```

**Save this endpoint! You'll need it for connection strings.**

---

## PHASE 2: Deploy to ECS

### Step 5: Create ECS Cluster

```powershell
# Create ECS cluster
aws ecs create-cluster --cluster-name gadgetsonline-cluster --region us-east-1
```

---

### Step 6: Create Task Execution Role

This role allows ECS to pull images from ECR and write logs.

```powershell
# Create trust policy file
@"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
"@ | Out-File -FilePath trust-policy.json -Encoding utf8

# Create IAM role
aws iam create-role `
    --role-name ecsTaskExecutionRole `
    --assume-role-policy-document file://trust-policy.json

# Attach AWS managed policy
aws iam attach-role-policy `
    --role-name ecsTaskExecutionRole `
    --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

---

### Step 7: Create Security Group for ECS Tasks

```powershell
# Create security group for ECS tasks
aws ec2 create-security-group `
    --group-name gadgetsonline-ecs-sg `
    --description "Security group for GadgetsOnline ECS tasks" `
    --vpc-id $VPC_ID

# Get the security group ID
$ECS_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-ecs-sg" `
    --query "SecurityGroups[0].GroupId" --output text

# Allow HTTP traffic (port 80)
aws ec2 authorize-security-group-ingress `
    --group-id $ECS_SG_ID `
    --protocol tcp `
    --port 80 `
    --cidr 0.0.0.0/0

# Allow traffic on application ports
aws ec2 authorize-security-group-ingress `
    --group-id $ECS_SG_ID `
    --protocol tcp `
    --port 8080 `
    --cidr 0.0.0.0/0

# Allow all traffic within the security group (for service-to-service communication)
aws ec2 authorize-security-group-ingress `
    --group-id $ECS_SG_ID `
    --protocol -1 `
    --source-group $ECS_SG_ID

# Update RDS security group to allow traffic from ECS
aws ec2 authorize-security-group-ingress `
    --group-id $RDS_SG_ID `
    --protocol tcp `
    --port 1433 `
    --source-group $ECS_SG_ID
```

---

### Step 8: Create CloudWatch Log Groups

```powershell
aws logs create-log-group --log-group-name /ecs/gadgetsonline/catalog-api
aws logs create-log-group --log-group-name /ecs/gadgetsonline/cart-api
aws logs create-log-group --log-group-name /ecs/gadgetsonline/order-api
aws logs create-log-group --log-group-name /ecs/gadgetsonline/api-gateway
aws logs create-log-group --log-group-name /ecs/gadgetsonline/web-frontend
```

---

### Step 9: Create ECS Task Definitions

I'll create task definition files for each service. These will be created in the next step.

---

## PHASE 3: Create Configuration Files

Now I'll create the necessary configuration files for you.

---

## Summary of What We'll Deploy

1. ✅ **ECR Repositories** - Store Docker images
2. ✅ **RDS SQL Server** - Managed database
3. ✅ **ECS Cluster** - Container orchestration
4. ✅ **Security Groups** - Network security
5. ⏳ **Task Definitions** - Container configurations (next)
6. ⏳ **ECS Services** - Running containers (next)
7. ⏳ **Load Balancer** - Traffic routing (next)

---

## Cost Estimate

**Monthly costs (approximate):**
- RDS SQL Server (db.t3.small): ~$30-50/month
- ECS Fargate: ~$30-60/month (depends on usage)
- Load Balancer: ~$20/month
- Data transfer: ~$10/month
- **Total: ~$90-140/month**

**Free Tier eligible services:**
- ECR: 500 MB storage free
- CloudWatch Logs: 5 GB free
- First 12 months: Some RDS and compute hours free

---

## Next Steps

After completing the steps above, I'll create:
1. ECS Task Definition JSON files for each service
2. Scripts to create ECS services
3. Application Load Balancer configuration
4. Service discovery setup
5. Deployment automation scripts

**Are you ready to proceed? Let me know if you:**
1. Have completed Steps 1-8 above
2. Need help with any specific step
3. Want me to create the task definitions and deployment scripts now
