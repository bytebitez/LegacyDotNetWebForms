# AWS Deployment Guide for GadgetsOnline Microservices

## Prerequisites
1. AWS Account
2. AWS CLI installed and configured
3. Docker installed locally
4. ECR (Elastic Container Registry) repositories created

## Step 1: Build and Push Docker Images to AWS ECR

```bash
# Login to AWS ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com

# Build images
cd microservices
docker-compose build

# Tag and push images
docker tag gadgetsonline-catalog-api:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-catalog:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-catalog:latest

docker tag gadgetsonline-cart-api:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-cart:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-cart:latest

docker tag gadgetsonline-order-api:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-order:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-order:latest

docker tag gadgetsonline-api-gateway:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-gateway:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-gateway:latest

docker tag gadgetsonline-web:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-web:latest
docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-web:latest
```

## Step 2: Create RDS Database (SQL Server)

```bash
aws rds create-db-instance \
    --db-instance-identifier gadgetsonline-db \
    --db-instance-class db.t3.micro \
    --engine sqlserver-ex \
    --master-username admin \
    --master-user-password YourStrong@Passw0rd \
    --allocated-storage 20 \
    --vpc-security-group-ids sg-xxxxxxxx \
    --db-subnet-group-name your-subnet-group
```

## Step 3: Deploy to AWS ECS (Elastic Container Service)

### Option A: Using AWS Fargate (Serverless)

1. **Create ECS Cluster**
```bash
aws ecs create-cluster --cluster-name gadgetsonline-cluster
```

2. **Create Task Definitions** (see task-definition-*.json files)

3. **Create Services**
```bash
aws ecs create-service \
    --cluster gadgetsonline-cluster \
    --service-name catalog-service \
    --task-definition catalog-task \
    --desired-count 1 \
    --launch-type FARGATE \
    --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

### Option B: Using AWS App Runner (Simplest)

```bash
aws apprunner create-service \
    --service-name gadgetsonline-web \
    --source-configuration '{
        "ImageRepository": {
            "ImageIdentifier": "<account-id>.dkr.ecr.us-east-1.amazonaws.com/gadgetsonline-web:latest",
            "ImageRepositoryType": "ECR"
        }
    }'
```

### Option C: Using AWS Elastic Beanstalk

1. Create `Dockerrun.aws.json` file
2. Deploy using EB CLI:
```bash
eb init -p docker gadgetsonline
eb create gadgetsonline-env
```

## Step 4: Configure Load Balancer

1. **Create Application Load Balancer**
2. **Configure Target Groups** for each service
3. **Set up routing rules**:
   - `/` → Web Frontend
   - `/api/*` → API Gateway

## Step 5: Update Configuration

Update connection strings and URLs in AWS Systems Manager Parameter Store:

```bash
aws ssm put-parameter \
    --name /gadgetsonline/catalog/connectionstring \
    --value "Server=your-rds-endpoint;Database=CatalogDB;User Id=admin;Password=xxx" \
    --type SecureString

aws ssm put-parameter \
    --name /gadgetsonline/apigateway/url \
    --value "http://internal-alb.amazonaws.com" \
    --type String
```

## Architecture on AWS

```
Internet
    ↓
[Application Load Balancer]
    ↓
┌─────────────────────────────────────┐
│  ECS Cluster / Fargate              │
│  ┌──────────────────────────────┐   │
│  │  Web Frontend (Public)       │   │
│  └──────────────────────────────┘   │
│           ↓                          │
│  ┌──────────────────────────────┐   │
│  │  API Gateway (Internal)      │   │
│  └──────────────────────────────┘   │
│           ↓                          │
│  ┌────────┬────────┬────────────┐   │
│  │Catalog │  Cart  │   Order    │   │
│  │  API   │  API   │    API     │   │
│  └────────┴────────┴────────────┘   │
└─────────────────────────────────────┘
           ↓
    [RDS SQL Server]
```

## Estimated AWS Costs (Monthly)

- **ECS Fargate**: ~$30-50 (5 services)
- **RDS SQL Server Express**: ~$15-25
- **Application Load Balancer**: ~$20
- **ECR Storage**: ~$1-5
- **Data Transfer**: ~$10-20
- **Total**: ~$76-120/month

## Alternative: AWS Lightsail (Cheaper)

For smaller deployments:
- **Container Service**: $10-40/month
- **Database**: $15/month
- **Total**: ~$25-55/month

## Public URL

After deployment, your application will be accessible at:
- **Load Balancer URL**: `http://gadgetsonline-alb-123456789.us-east-1.elb.amazonaws.com`
- **Custom Domain**: `https://www.gadgetsonline.com` (after Route 53 configuration)

## Next Steps

1. Set up CI/CD with AWS CodePipeline
2. Configure CloudWatch for monitoring
3. Set up auto-scaling policies
4. Configure SSL/TLS certificates with ACM
5. Set up Route 53 for custom domain
