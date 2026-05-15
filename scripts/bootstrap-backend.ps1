$ErrorActionPreference = "Stop"

$REGION = "us-east-1"
$ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text).Trim()
$BUCKET_NAME = "ecs-project-tfstate-$ACCOUNT_ID"
$TABLE_NAME = "terraform-state-lock"

Write-Host "Bootstrapping Terraform Remote State..."

Write-Host "Creating S3 bucket: $BUCKET_NAME in $REGION..."
aws s3api create-bucket --bucket $BUCKET_NAME --region $REGION

Write-Host "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled

Write-Host "Creating DynamoDB table for state locking: $TABLE_NAME..."
aws dynamodb create-table `
    --table-name $TABLE_NAME `
    --attribute-definitions AttributeName=LockID,AttributeType=S `
    --key-schema AttributeName=LockID,KeyType=HASH `
    --billing-mode PAY_PER_REQUEST `
    --region $REGION | Out-Null

Write-Host "Bootstrap complete!"
Write-Host "--------------------------------------------------------"
Write-Host "IMPORTANT: Update your terraform/backend.tf with:"
Write-Host "bucket = `"$BUCKET_NAME`""
Write-Host "--------------------------------------------------------"
