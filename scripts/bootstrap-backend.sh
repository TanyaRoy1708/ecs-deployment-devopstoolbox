#!/bin/bash
set -e

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ecs-project-tfstate-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock"

echo "Bootstrapping Terraform Remote State..."

# 1. Create S3 Bucket (if it doesn't exist)
if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Creating S3 bucket: $BUCKET_NAME..."
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
    aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled
else
    echo "S3 bucket $BUCKET_NAME already exists."
fi

# 2. Create DynamoDB Table (if it doesn't exist)
if ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
    echo "Creating DynamoDB table: $TABLE_NAME..."
    aws dynamodb create-table \
        --table-name "$TABLE_NAME" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --billing-mode PAY_PER_REQUEST \
        --region "$REGION" > /dev/null
else
    echo "DynamoDB table $TABLE_NAME already exists."
fi

echo -e "\nBootstrap complete!"
echo "--------------------------------------------------------"
echo "IMPORTANT: Update your terraform/backend.tf with:"
echo "bucket = \"${BUCKET_NAME}\""
echo "--------------------------------------------------------"

