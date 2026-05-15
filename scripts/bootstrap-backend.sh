#!/bin/bash
# Exit if any command fails
set -e

REGION="us-east-1"
# Get the AWS Account ID to make the bucket name globally unique
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="ecs-project-tfstate-${ACCOUNT_ID}"
TABLE_NAME="terraform-state-lock"

echo "🚀 Bootstrapping Terraform Remote State..."

echo "1️⃣ Creating S3 bucket: ${BUCKET_NAME} in ${REGION}..."
# us-east-1 doesn't require LocationConstraint
aws s3api create-bucket \
    --bucket ${BUCKET_NAME} \
    --region ${REGION}

echo "2️⃣ Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

echo "3️⃣ Creating DynamoDB table for state locking: ${TABLE_NAME}..."
aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ${REGION} > /dev/null

echo "✅ Bootstrap complete!"
echo "--------------------------------------------------------"
echo "IMPORTANT: Update your terraform/backend.tf with:"
echo "bucket = \"${BUCKET_NAME}\""
echo "--------------------------------------------------------"
