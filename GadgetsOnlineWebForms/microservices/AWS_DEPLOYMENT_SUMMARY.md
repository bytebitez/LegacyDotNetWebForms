# AWS Deployment - Complete Guide Summary

## 🎯 What You'll Deploy

Your GadgetsOnline microservices application will be deployed to AWS with:

- **5 Microservices** running on ECS Fargate (serverless containers)
- **SQL Server Database** on Amazon RDS (managed database)
- **Application Load Balancer** for routing traffic
- **Service Discovery** for inter-service communication
- **CloudWatch Logs** for monitoring

## 📋 Quick Start (3 Commands)

```powershell
# Navigate to aws folder
cd microservices/aws

# 1. Push images to AWS (10-15 min)
.\push-images-to-ecr.ps1

# 2. Deploy infrastructure (15-20 min)
.\deploy-to-aws.ps1

# 3. Create services and load balancer (5-10 min)
.\create-ecs-services.ps1
.\create-load-balancer.ps1
```

**Total time: ~30-45 minutes**

## 📁 Files Created

All deployment files are in the `microservices/aws/` folder:

### Scripts (PowerShell)
1. **push-images-to-ecr.ps1** - Upload Docker images to AWS
2. **deploy-to-aws.ps1** - Create infrastructure and register tasks
3. **create-ecs-services.ps1** - Deploy services with service discovery
4. **create-load-balancer.ps1** - Set up load balancer and routing

### Configuration Files (JSON)
1. **task-definition-catalog-api.json** - Catalog service config
2. **task-definition-cart-api.json** - Cart service config
3. **task-definition-order-api.json** - Order service config
4. **task-definition-api-gateway.json** - API Gateway config
5. **task-definition-web-frontend.json** - Web UI config

### Documentation
- **README.md** - Detailed deployment guide
- **AWS_DEPLOYMENT_GUIDE.md** - Step-by-step manual instructions

## 🔧 What Gets Created in AWS

### Compute (ECS)
- **ECS Cluster**: `gadgetsonline-cluster`
- **5 ECS Services**: One for each microservice
- **5 Task Definitions**: Container configurations
- **Service Discovery**: `gadgetsonline.local` namespace

### Database (RDS)
- **RDS Instance**: `gadgetsonline-sqlserver`
- **Engine**: SQL Server Express Edition
- **Size**: db.t3.small (can be adjusted)
- **Storage**: 20 GB
- **3 Databases**: CatalogDB, CartDB, OrderDB

### Networking
- **Application Load Balancer**: `gadgetsonline-alb`
- **2 Target Groups**: For web and API traffic
- **3 Security Groups**: For ALB, ECS, and RDS
- **VPC**: Uses your default VPC
- **Subnets**: Across multiple availability zones

### Container Registry (ECR)
- **5 Repositories**: One for each service image

### Monitoring (CloudWatch)
- **5 Log Groups**: One for each service
- **Metrics**: Automatic ECS and RDS metrics

## 💰 Cost Estimate

### Monthly Costs (Approximate)

**Development/Testing:**
- RDS (db.t3.small): $30-40
- ECS Fargate (5 services, 1 task each): $30-40
- Load Balancer: $20
- Data Transfer: $5-10
- **Total: ~$85-110/month**

**Production:**
- RDS (db.t3.medium): $60-80
- ECS Fargate (5 services, 2 tasks each): $60-80
- Load Balancer: $20
- Data Transfer: $20-30
- **Total: ~$160-210/month**

### Free Tier Benefits (First 12 Months)
- 750 hours of RDS db.t3.micro
- 750 hours of ECS Fargate
- 500 MB ECR storage
- 5 GB CloudWatch Logs

## 🚀 Deployment Steps Explained

### Step 1: Push Images to ECR (~10-15 min)

```powershell
.\push-images-to-ecr.ps1
```

**What happens:**
1. Creates 5 ECR repositories in AWS
2. Authenticates Docker with AWS
3. Tags your local Docker images
4. Pushes images to AWS (this takes time due to upload)

**Output:**
```
✓ Created: gadgetsonline/catalog-api
✓ Created: gadgetsonline/cart-api
✓ Created: gadgetsonline/order-api
✓ Created: gadgetsonline/api-gateway
✓ Created: gadgetsonline/web-frontend
✓ Docker authenticated with ECR
✓ Pushed: gadgetsonline/catalog-api
...
```

### Step 2: Deploy Infrastructure (~15-20 min)

```powershell
.\deploy-to-aws.ps1
```

**What happens:**
1. Gets your AWS account ID
2. Gets RDS endpoint (or creates RDS if needed)
3. Updates task definition files with your account ID and RDS endpoint
4. Registers all 5 task definitions with ECS

**Output:**
```
AWS Account ID: 123456789012
RDS Endpoint: gadgetsonline-sqlserver.xxxxx.us-east-1.rds.amazonaws.com
✓ Registered: catalog-api
✓ Registered: cart-api
...
```

**Note:** If RDS doesn't exist, you'll need to create it manually (see guide).

### Step 3: Create Services (~5-10 min)

```powershell
.\create-ecs-services.ps1
```

**What happens:**
1. Creates service discovery namespace (`gadgetsonline.local`)
2. Creates service discovery services for each microservice
3. Creates ECS services that run your containers
4. Services register themselves for inter-service communication

**Output:**
```
Namespace ID: ns-xxxxx
✓ Created discovery service: catalog-api
✓ Created ECS service: catalog-api
...
```

### Step 4: Create Load Balancer (~5 min)

```powershell
.\create-load-balancer.ps1
```

**What happens:**
1. Creates security group for load balancer
2. Creates Application Load Balancer
3. Creates target groups for web and API traffic
4. Creates listener rules for routing
5. Outputs your application URL

**Output:**
```
✓ Created ALB: arn:aws:elasticloadbalancing:...
ALB DNS: gadgetsonline-alb-123456789.us-east-1.elb.amazonaws.com

Application URL:
  http://gadgetsonline-alb-123456789.us-east-1.elb.amazonaws.com
```

## 🌐 Accessing Your Application

After deployment, you'll get a URL like:

```
http://gadgetsonline-alb-123456789.us-east-1.elb.amazonaws.com
```

### Endpoints:
- **Web Application**: `http://YOUR-ALB-DNS/`
- **API Gateway**: `http://YOUR-ALB-DNS/api/products`
- **Health Check**: `http://YOUR-ALB-DNS/api/categories`

## 🔍 Monitoring Your Deployment

### Check Service Status

```powershell
# List all services
aws ecs list-services --cluster gadgetsonline-cluster

# Check specific service
aws ecs describe-services --cluster gadgetsonline-cluster --services catalog-api

# View logs
aws logs tail /ecs/gadgetsonline/catalog-api --follow
```

### Check Database

```powershell
# Get RDS status
aws rds describe-db-instances --db-instance-identifier gadgetsonline-sqlserver

# Get endpoint
aws rds describe-db-instances --db-instance-identifier gadgetsonline-sqlserver --query "DBInstances[0].Endpoint.Address"
```

### Check Load Balancer

```powershell
# Get ALB DNS
aws elbv2 describe-load-balancers --names gadgetsonline-alb --query "LoadBalancers[0].DNSName"

# Check target health
aws elbv2 describe-target-health --target-group-arn YOUR-TG-ARN
```

## 🐛 Troubleshooting

### Services Not Starting

**Check logs:**
```powershell
aws logs tail /ecs/gadgetsonline/catalog-api --follow
```

**Common issues:**
- Database connection string incorrect
- Security groups blocking traffic
- Task definition errors

### Database Connection Issues

**Verify:**
1. RDS is in "available" state
2. RDS security group allows traffic from ECS security group
3. Connection string in task definitions is correct

### Load Balancer Not Working

**Check:**
1. Target groups have healthy targets
2. Security groups allow traffic from ALB to ECS
3. Services are running and registered

## 🧹 Cleanup (Delete Everything)

To avoid ongoing charges:

```powershell
# Stop and delete services
aws ecs update-service --cluster gadgetsonline-cluster --service catalog-api --desired-count 0
aws ecs delete-service --cluster gadgetsonline-cluster --service catalog-api
# Repeat for all services

# Delete cluster
aws ecs delete-cluster --cluster gadgetsonline-cluster

# Delete RDS
aws rds delete-db-instance --db-instance-identifier gadgetsonline-sqlserver --skip-final-snapshot

# Delete load balancer
aws elbv2 delete-load-balancer --load-balancer-arn YOUR-ALB-ARN

# Delete ECR repositories
aws ecr delete-repository --repository-name gadgetsonline/catalog-api --force
# Repeat for all repositories
```

## 📚 Next Steps After Deployment

### 1. Add Custom Domain
- Register domain in Route 53
- Create SSL certificate in ACM
- Add HTTPS listener to ALB
- Update DNS records

### 2. Enable Auto-Scaling
- Configure ECS service auto-scaling
- Set up CloudWatch alarms
- Define scaling policies

### 3. Add Monitoring
- Set up CloudWatch dashboards
- Configure alarms for errors
- Enable X-Ray tracing

### 4. Implement CI/CD
- Set up GitHub Actions or AWS CodePipeline
- Automate image builds
- Automate deployments

### 5. Enhance Security
- Use AWS Secrets Manager for passwords
- Enable VPC Flow Logs
- Implement WAF rules
- Add authentication (Cognito, Auth0)

## ✅ Success Checklist

After deployment, verify:

- [ ] All 5 ECS services are running
- [ ] RDS database is available
- [ ] Load balancer is active
- [ ] Target groups show healthy targets
- [ ] Application URL loads in browser
- [ ] Products display on home page
- [ ] API endpoints respond correctly
- [ ] CloudWatch logs are being written

## 🆘 Getting Help

If you encounter issues:

1. **Check CloudWatch Logs**: Most errors appear here
2. **Verify Security Groups**: Common cause of connectivity issues
3. **Check Service Events**: ECS service events show deployment issues
4. **Review Task Definitions**: Ensure environment variables are correct

## 📞 Support Resources

- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS RDS Documentation](https://docs.aws.amazon.com/rds/)
- [AWS CLI Reference](https://docs.aws.amazon.com/cli/)
- [Troubleshooting Guide](./README.md#-common-issues)

---

**Ready to deploy? Start with the Quick Start commands above!** 🚀
