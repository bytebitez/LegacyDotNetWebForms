# AWS Deployment - Quick Start Guide

This folder contains everything you need to deploy GadgetsOnline microservices to AWS.

## 📋 Prerequisites Checklist

Before starting, ensure you have:

- ✅ AWS Account created
- ✅ AWS CLI installed and configured (`aws configure`)
- ✅ Docker Desktop running
- ✅ Docker images built locally (from docker-compose)
- ✅ PowerShell (Windows) or Bash (Linux/Mac)

## 🚀 Quick Deployment (3 Simple Steps)

### Step 1: Push Docker Images to AWS

```powershell
# Run from the microservices/aws folder
.\push-images-to-ecr.ps1
```

**What this does:**
- Creates ECR repositories
- Authenticates Docker with AWS
- Pushes all 5 Docker images to AWS
- Takes ~10-15 minutes

### Step 2: Deploy Infrastructure and Services

```powershell
.\deploy-to-aws.ps1
```

**What this does:**
- Creates RDS SQL Server database
- Registers ECS task definitions
- Sets up networking and security groups
- Takes ~15-20 minutes (mostly waiting for RDS)

### Step 3: Create Services and Load Balancer

```powershell
.\create-ecs-services.ps1
.\create-load-balancer.ps1
```

**What this does:**
- Creates ECS services for all microservices
- Sets up service discovery
- Creates Application Load Balancer
- Configures routing rules
- Takes ~5-10 minutes

## 🎉 Access Your Application

After deployment completes, you'll get a URL like:

```
http://gadgetsonline-alb-123456789.us-east-1.elb.amazonaws.com
```

Open this in your browser to see your application running on AWS!

## 📁 Files in This Folder

### Deployment Scripts
- `push-images-to-ecr.ps1` - Push Docker images to AWS ECR
- `deploy-to-aws.ps1` - Deploy infrastructure and register tasks
- `create-ecs-services.ps1` - Create ECS services with service discovery
- `create-load-balancer.ps1` - Create and configure ALB

### Task Definitions
- `task-definition-catalog-api.json` - Catalog API configuration
- `task-definition-cart-api.json` - Cart API configuration
- `task-definition-order-api.json` - Order API configuration
- `task-definition-api-gateway.json` - API Gateway configuration
- `task-definition-web-frontend.json` - Web Frontend configuration

## 🔧 Manual Deployment (Step-by-Step)

If you prefer to understand each step, follow the detailed guide:

### Phase 1: Setup ECR and Push Images

```powershell
# 1. Create ECR repositories
aws ecr create-repository --repository-name gadgetsonline/catalog-api
aws ecr create-repository --repository-name gadgetsonline/cart-api
aws ecr create-repository --repository-name gadgetsonline/order-api
aws ecr create-repository --repository-name gadgetsonline/api-gateway
aws ecr create-repository --repository-name gadgetsonline/web-frontend

# 2. Get your AWS account ID
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

# 3. Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# 4. Tag and push images
docker tag microservices-catalog-api:latest $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline/catalog-api:latest
docker push $AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline/catalog-api:latest

# Repeat for other services...
```

### Phase 2: Create RDS Database

```powershell
# 1. Get VPC ID
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text

# 2. Create security group for RDS
aws ec2 create-security-group --group-name gadgetsonline-rds-sg --description "RDS Security Group" --vpc-id $VPC_ID

# 3. Create RDS instance
aws rds create-db-instance `
    --db-instance-identifier gadgetsonline-sqlserver `
    --db-instance-class db.t3.small `
    --engine sqlserver-ex `
    --master-username admin `
    --master-user-password "YourStrong@Passw0rd123" `
    --allocated-storage 20

# 4. Wait for RDS to be ready (10-15 minutes)
aws rds wait db-instance-available --db-instance-identifier gadgetsonline-sqlserver
```

### Phase 3: Create ECS Cluster

```powershell
# Create ECS cluster
aws ecs create-cluster --cluster-name gadgetsonline-cluster

# Create task execution role
aws iam create-role --role-name ecsTaskExecutionRole --assume-role-policy-document file://trust-policy.json
aws iam attach-role-policy --role-name ecsTaskExecutionRole --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### Phase 4: Register Task Definitions

```powershell
# Register each task definition
aws ecs register-task-definition --cli-input-json file://task-definition-catalog-api.json
aws ecs register-task-definition --cli-input-json file://task-definition-cart-api.json
aws ecs register-task-definition --cli-input-json file://task-definition-order-api.json
aws ecs register-task-definition --cli-input-json file://task-definition-api-gateway.json
aws ecs register-task-definition --cli-input-json file://task-definition-web-frontend.json
```

### Phase 5: Create Services

```powershell
# Create service discovery namespace
aws servicediscovery create-private-dns-namespace --name gadgetsonline.local --vpc $VPC_ID

# Create ECS services (see create-ecs-services.ps1 for details)
```

### Phase 6: Create Load Balancer

```powershell
# Create ALB (see create-load-balancer.ps1 for details)
```

## 🔍 Monitoring and Troubleshooting

### Check Service Status

```powershell
# List all services
aws ecs list-services --cluster gadgetsonline-cluster

# Describe a specific service
aws ecs describe-services --cluster gadgetsonline-cluster --services catalog-api

# View service logs
aws logs tail /ecs/gadgetsonline/catalog-api --follow
```

### Check RDS Status

```powershell
# Get RDS endpoint
aws rds describe-db-instances --db-instance-identifier gadgetsonline-sqlserver --query "DBInstances[0].Endpoint.Address"

# Check RDS status
aws rds describe-db-instances --db-instance-identifier gadgetsonline-sqlserver --query "DBInstances[0].DBInstanceStatus"
```

### Check Load Balancer Health

```powershell
# Get target group ARN
$TG_ARN = aws elbv2 describe-target-groups --names gadgetsonline-web-tg --query "TargetGroups[0].TargetGroupArn" --output text

# Check target health
aws elbv2 describe-target-health --target-group-arn $TG_ARN
```

## 💰 Cost Optimization

### Development/Testing
- Use `db.t3.micro` for RDS (free tier eligible)
- Set desired count to 1 for each service
- Use Fargate Spot for non-critical services
- **Estimated cost: ~$50-80/month**

### Production
- Use `db.t3.small` or larger for RDS
- Set desired count to 2+ for high availability
- Use reserved instances for cost savings
- Enable auto-scaling
- **Estimated cost: ~$150-300/month**

## 🧹 Cleanup (Delete Everything)

To avoid charges, delete all resources:

```powershell
# Delete ECS services
aws ecs update-service --cluster gadgetsonline-cluster --service catalog-api --desired-count 0
aws ecs delete-service --cluster gadgetsonline-cluster --service catalog-api
# Repeat for all services...

# Delete ECS cluster
aws ecs delete-cluster --cluster gadgetsonline-cluster

# Delete RDS instance
aws rds delete-db-instance --db-instance-identifier gadgetsonline-sqlserver --skip-final-snapshot

# Delete Load Balancer
aws elbv2 delete-load-balancer --load-balancer-arn <ALB_ARN>

# Delete Target Groups
aws elbv2 delete-target-group --target-group-arn <TG_ARN>

# Delete ECR repositories
aws ecr delete-repository --repository-name gadgetsonline/catalog-api --force
# Repeat for all repositories...
```

## 📚 Additional Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS ALB Documentation](https://docs.aws.amazon.com/elasticloadbalancing/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)

## 🆘 Common Issues

### Issue: "No default VPC found"
**Solution:** Create a VPC or specify a custom VPC ID in the scripts

### Issue: "Task failed to start"
**Solution:** Check CloudWatch logs for the specific service

### Issue: "Target health check failing"
**Solution:** Verify security groups allow traffic between ALB and ECS tasks

### Issue: "Cannot connect to RDS"
**Solution:** Ensure RDS security group allows traffic from ECS security group

## 📞 Support

For issues or questions:
1. Check CloudWatch Logs: `/ecs/gadgetsonline/*`
2. Review ECS service events
3. Verify security group rules
4. Check RDS connectivity

---

**Ready to deploy? Start with Step 1!** 🚀
