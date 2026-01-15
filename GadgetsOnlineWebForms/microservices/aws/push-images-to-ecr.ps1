# Push Docker Images to AWS ECR
# This script creates ECR repositories and pushes all Docker images

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push Docker Images to AWS ECR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
Write-Host "Step 1: Getting AWS Account ID..." -ForegroundColor Yellow
$AWS_ACCOUNT_ID = aws sts get-caller-identity --query Account --output text

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get AWS Account ID." -ForegroundColor Red
    Write-Host "Make sure AWS CLI is configured: aws configure" -ForegroundColor Yellow
    exit 1
}

Write-Host "  AWS Account ID: $AWS_ACCOUNT_ID" -ForegroundColor Green
Write-Host "  Region: $Region" -ForegroundColor Green
Write-Host ""

# Define repositories
$repositories = @(
    "gadgetsonline/catalog-api",
    "gadgetsonline/cart-api",
    "gadgetsonline/order-api",
    "gadgetsonline/api-gateway",
    "gadgetsonline/web-frontend"
)

# Step 2: Create ECR repositories
Write-Host "Step 2: Creating ECR repositories..." -ForegroundColor Yellow

foreach ($repo in $repositories) {
    Write-Host "  Creating repository: $repo..." -ForegroundColor Cyan
    
    $result = aws ecr describe-repositories --repository-names $repo --region $Region 2>$null
    
    if ($LASTEXITCODE -ne 0) {
        aws ecr create-repository --repository-name $repo --region $Region | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    ✓ Created: $repo" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Failed to create: $repo" -ForegroundColor Red
        }
    } else {
        Write-Host "    ✓ Already exists: $repo" -ForegroundColor Green
    }
}
Write-Host ""

# Step 3: Authenticate Docker with ECR
Write-Host "Step 3: Authenticating Docker with ECR..." -ForegroundColor Yellow

$loginCommand = aws ecr get-login-password --region $Region
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to get ECR login password" -ForegroundColor Red
    exit 1
}

$loginCommand | docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$Region.amazonaws.com" 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Docker authenticated with ECR" -ForegroundColor Green
} else {
    Write-Host "  ✗ Failed to authenticate Docker" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Tag and push images
Write-Host "Step 4: Tagging and pushing Docker images..." -ForegroundColor Yellow
Write-Host "  This will take 10-15 minutes..." -ForegroundColor Cyan
Write-Host ""

$images = @(
    @{Local="microservices-catalog-api"; Remote="gadgetsonline/catalog-api"},
    @{Local="microservices-cart-api"; Remote="gadgetsonline/cart-api"},
    @{Local="microservices-order-api"; Remote="gadgetsonline/order-api"},
    @{Local="microservices-api-gateway"; Remote="gadgetsonline/api-gateway"},
    @{Local="microservices-web-frontend"; Remote="gadgetsonline/web-frontend"}
)

$successCount = 0
$failCount = 0

foreach ($img in $images) {
    $localImage = "$($img.Local):latest"
    $remoteImage = "$AWS_ACCOUNT_ID.dkr.ecr.$Region.amazonaws.com/$($img.Remote):latest"
    
    Write-Host "  Processing: $($img.Local)..." -ForegroundColor Cyan
    
    # Check if local image exists
    $imageExists = docker images -q $localImage
    if ([string]::IsNullOrEmpty($imageExists)) {
        Write-Host "    ✗ Local image not found: $localImage" -ForegroundColor Red
        Write-Host "      Run 'docker-compose build' first" -ForegroundColor Yellow
        $failCount++
        continue
    }
    
    # Tag image
    Write-Host "    Tagging..." -ForegroundColor Gray
    docker tag $localImage $remoteImage
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    ✗ Failed to tag image" -ForegroundColor Red
        $failCount++
        continue
    }
    
    # Push image
    Write-Host "    Pushing to ECR..." -ForegroundColor Gray
    docker push $remoteImage 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✓ Pushed: $($img.Remote)" -ForegroundColor Green
        $successCount++
    } else {
        Write-Host "    ✗ Failed to push: $($img.Remote)" -ForegroundColor Red
        $failCount++
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Push Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Successful: $successCount" -ForegroundColor Green
Write-Host "  ✗ Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host ""

if ($successCount -eq $images.Count) {
    Write-Host "All images pushed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Run: .\deploy-to-aws.ps1" -ForegroundColor Cyan
    Write-Host "2. This will create RDS and register task definitions" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host "Some images failed to push. Please check the errors above." -ForegroundColor Red
    Write-Host ""
    Write-Host "Common issues:" -ForegroundColor Yellow
    Write-Host "  - Local images not built: Run 'docker-compose build' first" -ForegroundColor White
    Write-Host "  - AWS credentials not configured: Run 'aws configure'" -ForegroundColor White
    Write-Host "  - Network issues: Check your internet connection" -ForegroundColor White
    Write-Host ""
}
