# GadgetsOnline AWS Deployment Script
# This script automates the deployment of microservices to AWS ECS

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$ClusterName = "gadgetsonline-cluster"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "GadgetsOnline AWS Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
Write-Host "Getting AWS Account ID..." -ForegroundColor Yellow
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get AWS Account ID. Make sure AWS CLI is configured." -ForegroundColor Red
    exit 1
}
Write-Host "AWS Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Green
Write-Host ""

# Get RDS Endpoint
Write-Host "Getting RDS Endpoint..." -ForegroundColor Yellow
$RDS_ENDPOINT = aws rds describe-db-instances `
    --db-instance-identifier gadgetsonline-sqlserver `
    --query "DBInstances[0].Endpoint.Address" --output text 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($RDS_ENDPOINT)) {
    Write-Host "Warning: RDS instance not found. You'll need to create it first." -ForegroundColor Yellow
    $RDS_ENDPOINT = "YOUR_RDS_ENDPOINT"
} else {
    Write-Host "RDS Endpoint: $RDS_ENDPOINT" -ForegroundColor Green
}
Write-Host ""

# Update task definition files
Write-Host "Updating task definition files..." -ForegroundColor Yellow
$taskDefinitions = @(
    "task-definition-catalog-api.json",
    "task-definition-cart-api.json",
    "task-definition-order-api.json",
    "task-definition-api-gateway.json",
    "task-definition-web-frontend.json"
)

foreach ($taskDef in $taskDefinitions) {
    $filePath = Join-Path $PSScriptRoot $taskDef
    if (Test-Path $filePath) {
        $content = Get-Content $filePath -Raw
        $content = $content -replace "YOUR_ACCOUNT_ID", $AWS_ACCOUNT_ID
        $content = $content -replace "YOUR_RDS_ENDPOINT", $RDS_ENDPOINT
        $content | Set-Content $filePath -NoNewline
        Write-Host "  Updated: $taskDef" -ForegroundColor Green
    }
}
Write-Host ""

# Register task definitions
Write-Host "Registering ECS task definitions..." -ForegroundColor Yellow
foreach ($taskDef in $taskDefinitions) {
    $filePath = Join-Path $PSScriptRoot $taskDef
    $serviceName = $taskDef -replace "task-definition-", "" -replace ".json", ""
    
    Write-Host "  Registering: $serviceName..." -ForegroundColor Cyan
    aws ecs register-task-definition --cli-input-json file://$filePath --region $Region
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ Registered: $serviceName" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Failed: $serviceName" -ForegroundColor Red
    }
}
Write-Host ""

# Get VPC and Subnet information
Write-Host "Getting VPC and Subnet information..." -ForegroundColor Yellow
$VPC_ID = aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text
$SUBNETS = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[*].SubnetId" --output text
$SUBNET_LIST = $SUBNETS -replace "\s+", ","

Write-Host "VPC ID: $VPC_ID" -ForegroundColor Green
Write-Host "Subnets: $SUBNET_LIST" -ForegroundColor Green
Write-Host ""

# Get Security Group
$ECS_SG_ID = aws ec2 describe-security-groups `
    --filters "Name=group-name,Values=gadgetsonline-ecs-sg" `
    --query "SecurityGroups[0].GroupId" --output text 2>$null

if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($ECS_SG_ID)) {
    Write-Host "Warning: Security group 'gadgetsonline-ecs-sg' not found." -ForegroundColor Yellow
    Write-Host "Please create it first using the deployment guide." -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host "Security Group: $ECS_SG_ID" -ForegroundColor Green
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Task Definitions Registered!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Create Service Discovery namespace" -ForegroundColor White
Write-Host "2. Create ECS Services" -ForegroundColor White
Write-Host "3. Create Application Load Balancer" -ForegroundColor White
Write-Host "4. Configure Load Balancer target groups" -ForegroundColor White
Write-Host ""
Write-Host "Run the following script to continue:" -ForegroundColor Yellow
Write-Host "  .\create-ecs-services.ps1" -ForegroundColor Cyan
Write-Host ""
