# Create ECS Services with Service Discovery
# This script creates ECS services for all microservices

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "gadgetsonline-cluster"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating ECS Services" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get VPC and Subnet information
Write-Host "Getting network configuration..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text
$SUBNET_LIST = $SUBNETS -replace "\s+", ","

$ECS_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-ecs-sg" `
    --query "SecurityGroups[0].GroupId" --output text

Write-Host "VPC: $VPC_ID" -ForegroundColor Green
Write-Host "Subnets: $SUBNET_LIST" -ForegroundColor Green
Write-Host "Security Group: $ECS_SG_ID" -ForegroundColor Green
Write-Host ""

# Step 1: Create Service Discovery Namespace
Write-Host "Step 1: Creating Service Discovery namespace..." -ForegroundColor Yellow
$NAMESPACE_ID = aws servicediscovery list-namespaces `
    --filters "Name=NAME,Values=gadgetsonline.local" `
    --query "Namespaces[0].Id" --output text 2>$null

if ([string]::IsNullOrEmpty($NAMESPACE_ID) -or $NAMESPACE_ID -eq "None") {
    Write-Host "  Creating new namespace..." -ForegroundColor Cyan
    $NAMESPACE_ID = aws servicediscovery create-private-dns-namespace `
        --name gadgetsonline.local `
        --vpc $VPC_ID `
        --query "OperationId" --output text
    
    # Wait for namespace creation
    Write-Host "  Waiting for namespace creation..." -ForegroundColor Cyan
    Start-Sleep -Seconds 30
    
    $NAMESPACE_ID = aws servicediscovery list-namespaces `
        --filters "Name=NAME,Values=gadgetsonline.local" `
        --query "Namespaces[0].Id" --output text
}

Write-Host "  Namespace ID: $NAMESPACE_ID" -ForegroundColor Green
Write-Host ""

# Step 2: Create Service Discovery Services
Write-Host "Step 2: Creating Service Discovery services..." -ForegroundColor Yellow

$services = @(
    @{Name="catalog-api"; TaskDef="gadgetsonline-catalog-api"},
    @{Name="cart-api"; TaskDef="gadgetsonline-cart-api"},
    @{Name="order-api"; TaskDef="gadgetsonline-order-api"},
    @{Name="api-gateway"; TaskDef="gadgetsonline-api-gateway"},
    @{Name="web-frontend"; TaskDef="gadgetsonline-web-frontend"}
)

$serviceRegistries = @{}

foreach ($svc in $services) {
    $serviceName = $svc.Name
    
    # Check if service already exists
    $existingService = aws servicediscovery list-services `
        --filters "Name=NAMESPACE_ID,Values=$NAMESPACE_ID" `
        --query "Services[?Name=='$serviceName'].Id" --output text 2>$null
    
    if ([string]::IsNullOrEmpty($existingService) -or $existingService -eq "None") {
        Write-Host "  Creating discovery service: $serviceName..." -ForegroundColor Cyan
        
        $SERVICE_ID = aws servicediscovery create-service `
            --name $serviceName `
            --dns-config "NamespaceId=$NAMESPACE_ID,DnsRecords=[{Type=A,TTL=60}]" `
            --health-check-custom-config "FailureThreshold=1" `
            --query "Service.Id" --output text
        
        $serviceRegistries[$serviceName] = $SERVICE_ID
        Write-Host "    ✓ Created: $SERVICE_ID" -ForegroundColor Green
    } else {
        $serviceRegistries[$serviceName] = $existingService
        Write-Host "    ✓ Exists: $serviceName ($existingService)" -ForegroundColor Green
    }
}
Write-Host ""

# Step 3: Create ECS Services
Write-Host "Step 3: Creating ECS Services..." -ForegroundColor Yellow

foreach ($svc in $services) {
    $serviceName = $svc.Name
    $taskDef = $svc.TaskDef
    $registryArn = "arn:aws:servicediscovery:${Region}:$(aws sts get-caller-identity --query Account --output text):service/$($serviceRegistries[$serviceName])"
    
    Write-Host "  Creating ECS service: $serviceName..." -ForegroundColor Cyan
    
    # Check if service already exists
    $existingEcsService = aws ecs describe-services `
        --cluster $ClusterName `
        --services $serviceName `
        --query "services[?status=='ACTIVE'].serviceName" --output text 2>$null
    
    if ([string]::IsNullOrEmpty($existingEcsService)) {
        aws ecs create-service `
            --cluster $ClusterName `
            --service-name $serviceName `
            --task-definition $taskDef `
            --desired-count 1 `
            --launch-type FARGATE `
            --network-configuration "awsvpcConfiguration={subnets=[$SUBNET_LIST],securityGroups=[$ECS_SG_ID],assignPublicIp=ENABLED}" `
            --service-registries "registryArn=$registryArn" `
            --region $Region
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✓ Created: $serviceName" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed: $serviceName" -ForegroundColor Red
        }
    } else {
        Write-Host "    ✓ Already exists: $serviceName" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "ECS Services Created!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Services are starting up. This may take 2-3 minutes." -ForegroundColor Yellow
Write-Host ""
Write-Host "Check service status:" -ForegroundColor Yellow
Write-Host "  aws ecs list-services --cluster $ClusterName" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Create Application Load Balancer" -ForegroundColor White
Write-Host "2. Configure target groups" -ForegroundColor White
Write-Host "3. Test the deployment" -ForegroundColor White
Write-Host ""
Write-Host "Run the following script to create the load balancer:" -ForegroundColor Yellow
Write-Host "  .\create-load-balancer.ps1" -ForegroundColor Cyan
Write-Host ""
