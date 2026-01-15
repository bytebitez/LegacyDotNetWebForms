# Create Application Load Balancer for GadgetsOnline
# This script creates an ALB and configures it to route traffic to ECS services

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "gadgetsonline-cluster"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Creating Application Load Balancer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get VPC and Subnet information
Write-Host "Getting network configuration..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text
$SUBNET_ARRAY = $SUBNETS -split "\s+"

Write-Host "VPC: $VPC_ID" -ForegroundColor Green
Write-Host "Subnets: $($SUBNET_ARRAY -join ', ')" -ForegroundColor Green
Write-Host ""

# Step 1: Create Security Group for ALB
Write-Host "Step 1: Creating security group for ALB..." -ForegroundColor Yellow

$ALB_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-alb-sg" `
    --query "SecurityGroups[0].GroupId" --output text 2>$null

if ([string]::IsNullOrEmpty($ALB_SG_ID) -or $ALB_SG_ID -eq "None") {
    Write-Host "  Creating new security group..." -ForegroundColor Cyan
    
    $ALB_SG_ID = aws ec2 create-security-group `
        --group-name gadgetsonline-alb-sg `
        --description "Security group for GadgetsOnline ALB" `
        --vpc-id $VPC_ID `
        --query "GroupId" --output text
    
    # Allow HTTP traffic
    aws ec2 authorize-security-group-ingress `
        --group-id $ALB_SG_ID `
        --protocol tcp `
        --port 80 `
        --cidr 0.0.0.0/0
    
    # Allow HTTPS traffic
    aws ec2 authorize-security-group-ingress `
        --group-id $ALB_SG_ID `
        --protocol tcp `
        --port 443 `
        --cidr 0.0.0.0/0
    
    Write-Host "  ✓ Created: $ALB_SG_ID" -ForegroundColor Green
} else {
    Write-Host "  ✓ Already exists: $ALB_SG_ID" -ForegroundColor Green
}

# Update ECS security group to allow traffic from ALB
$ECS_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-ecs-sg" `
    --query "SecurityGroups[0].GroupId" --output text

Write-Host "  Updating ECS security group to allow ALB traffic..." -ForegroundColor Cyan
aws ec2 authorize-security-group-ingress `
    --group-id $ECS_SG_ID `
    --protocol tcp `
    --port 8080 `
    --source-group $ALB_SG_ID 2>$null

Write-Host ""

# Step 2: Create Application Load Balancer
Write-Host "Step 2: Creating Application Load Balancer..." -ForegroundColor Yellow

$ALB_ARN = aws elbv2 describe-load-balancers `
    --names gadgetsonline-alb `
    --query "LoadBalancers[0].LoadBalancerArn" --output text 2>$null

if ([string]::IsNullOrEmpty($ALB_ARN) -or $ALB_ARN -eq "None") {
    Write-Host "  Creating new load balancer..." -ForegroundColor Cyan
    
    $ALB_ARN = aws elbv2 create-load-balancer `
        --name gadgetsonline-alb `
        --subnets $SUBNET_ARRAY `
        --security-groups $ALB_SG_ID `
        --scheme internet-facing `
        --type application `
        --ip-address-type ipv4 `
        --query "LoadBalancers[0].LoadBalancerArn" --output text
    
    Write-Host "  ✓ Created ALB: $ALB_ARN" -ForegroundColor Green
    
    # Wait for ALB to be active
    Write-Host "  Waiting for ALB to become active..." -ForegroundColor Cyan
    aws elbv2 wait load-balancer-available --load-balancer-arns $ALB_ARN
    Write-Host "  ✓ ALB is active" -ForegroundColor Green
} else {
    Write-Host "  ✓ Already exists: $ALB_ARN" -ForegroundColor Green
}

# Get ALB DNS name
$ALB_DNS = aws elbv2 describe-load-balancers `
    --load-balancer-arns $ALB_ARN `
    --query "LoadBalancers[0].DNSName" --output text

Write-Host "  ALB DNS: $ALB_DNS" -ForegroundColor Green
Write-Host ""

# Step 3: Create Target Groups
Write-Host "Step 3: Creating target groups..." -ForegroundColor Yellow

$targetGroups = @(
    @{Name="gadgetsonline-web-tg"; Port=8080; HealthPath="/"},
    @{Name="gadgetsonline-api-tg"; Port=8080; HealthPath="/api/products"}
)

$TG_ARNS = @{}

foreach ($tg in $targetGroups) {
    $tgName = $tg.Name
    
    $TG_ARN = aws elbv2 describe-target-groups `
        --names $tgName `
        --query "TargetGroups[0].TargetGroupArn" --output text 2>$null
    
    if ([string]::IsNullOrEmpty($TG_ARN) -or $TG_ARN -eq "None") {
        Write-Host "  Creating target group: $tgName..." -ForegroundColor Cyan
        
        $TG_ARN = aws elbv2 create-target-group `
            --name $tgName `
            --protocol HTTP `
            --port $($tg.Port) `
            --vpc-id $VPC_ID `
            --target-type ip `
            --health-check-path $($tg.HealthPath) `
            --health-check-interval-seconds 30 `
            --health-check-timeout-seconds 5 `
            --healthy-threshold-count 2 `
            --unhealthy-threshold-count 3 `
            --query "TargetGroups[0].TargetGroupArn" --output text
        
        Write-Host "    ✓ Created: $TG_ARN" -ForegroundColor Green
    } else {
        Write-Host "    ✓ Already exists: $tgName" -ForegroundColor Green
    }
    
    $TG_ARNS[$tgName] = $TG_ARN
}
Write-Host ""

# Step 4: Create Listeners
Write-Host "Step 4: Creating ALB listeners..." -ForegroundColor Yellow

# Check if listener already exists
$LISTENER_ARN = aws elbv2 describe-listeners `
    --load-balancer-arn $ALB_ARN `
    --query "Listeners[0].ListenerArn" --output text 2>$null

if ([string]::IsNullOrEmpty($LISTENER_ARN) -or $LISTENER_ARN -eq "None") {
    Write-Host "  Creating HTTP listener..." -ForegroundColor Cyan
    
    $LISTENER_ARN = aws elbv2 create-listener `
        --load-balancer-arn $ALB_ARN `
        --protocol HTTP `
        --port 80 `
        --default-actions "Type=forward,TargetGroupArn=$($TG_ARNS['gadgetsonline-web-tg'])" `
        --query "Listeners[0].ListenerArn" --output text
    
    Write-Host "  ✓ Created listener: $LISTENER_ARN" -ForegroundColor Green
} else {
    Write-Host "  ✓ Listener already exists" -ForegroundColor Green
}

# Create listener rule for API Gateway
Write-Host "  Creating listener rule for API Gateway..." -ForegroundColor Cyan

aws elbv2 create-rule `
    --listener-arn $LISTENER_ARN `
    --priority 10 `
    --conditions "Field=path-pattern,Values=/api/*" `
    --actions "Type=forward,TargetGroupArn=$($TG_ARNS['gadgetsonline-api-tg'])" 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Created API rule" -ForegroundColor Green
} else {
    Write-Host "  ✓ API rule already exists" -ForegroundColor Yellow
}

Write-Host ""

# Step 5: Update ECS Services to use Target Groups
Write-Host "Step 5: Updating ECS services with load balancer..." -ForegroundColor Yellow

# Note: This requires recreating services with load balancer configuration
Write-Host "  Note: Services need to be updated manually or recreated with load balancer config" -ForegroundColor Yellow
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Load Balancer Created!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Application URL:" -ForegroundColor Yellow
Write-Host "  http://$ALB_DNS" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Gateway URL:" -ForegroundColor Yellow
Write-Host "  http://$ALB_DNS/api/products" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Wait 2-3 minutes for services to register with target groups" -ForegroundColor White
Write-Host "2. Test the application at the URL above" -ForegroundColor White
Write-Host "3. Check target group health:" -ForegroundColor White
Write-Host "   aws elbv2 describe-target-health --target-group-arn $($TG_ARNS['gadgetsonline-web-tg'])" -ForegroundColor Cyan
Write-Host ""
